#!/bin/bash -e
#
# Builds the versioned Flame documentation.
#
# Usage:
#   ./publish.sh                      Build every version sequentially, then
#                                     assemble docs/ and push (local/full run).
#   ./publish.sh list                 Print `latest` and `targets` (a JSON array
#                                     of everything to build, in site order).
#   ./publish.sh build <ver> <latest> Build a single version into out/.
#   ./publish.sh assemble <targets>   Combine out/ (or artifacts/) into docs/
#                                     and push.
#
# The CI workflow uses `list` to fan out one `build` job per version, then a
# single `assemble` job to publish. Splitting it this way keeps one copy of the
# build logic rather than duplicating it between the script and the workflow.

tmp_flame_src='_flame'
tmp_stash='_stash'
flame_repo='https://github.com/flame-engine/flame.git'
out_dir='out'

function main {
  case "${1:-}" in
    list) cmd_list ;;
    build) cmd_build "$2" "$3" ;;
    assemble) cmd_assemble "$2" ;;
    '') cmd_all ;;
    *) echo "Unknown command: $1" >&2; exit 1 ;;
  esac
}

function section {
  echo
  echo -e "\033[1;32m#-----------------------------------------------------------\033[m"
  echo -e "\033[1;32m# $1\033[m"
  echo -e "\033[1;32m#-----------------------------------------------------------\033[m"
}

# Obtain the list of documentation versions to build. The list is created from
# git tags, skipping the versions that started with 0, and removing all the old
# versions that don't support Melos 7 and pub workspaces.
function version_list {
  git -C $tmp_flame_src for-each-ref --sort=creatordate \
    --format '%(refname:short)' 'refs/tags/v*' | sed -n '29,$p' | sort -rV
}

# Prints `latest` and `targets` as `key=value` lines, ready to be appended to
# $GITHUB_OUTPUT. `targets` is main followed by the versions in descending
# order, which is also the order they are listed in on the site.
function cmd_list {
  rm -rf $tmp_flame_src
  # Only the refs are needed here, so skip blobs and the working copy.
  git clone --filter=blob:none --no-checkout --quiet $flame_repo $tmp_flame_src
  local list latest targets
  list=$(version_list)
  latest=$(head -n 1 <<< "$list")
  targets=$(printf 'main\n%s\n' "$list" | jq -R . | jq -s -c .)
  rm -rf $tmp_flame_src
  echo "latest=$latest"
  echo "targets=$targets"
}

function cmd_build {
  prepare_flame_repo
  generate_docs_for_version "$1" "$2"
}

function cmd_all {
  local list latest targets
  prepare_flame_repo
  section "List of versions to build:"
  list=$(version_list)
  echo "$list"
  latest=$(head -n 1 <<< "$list")
  targets=$(printf 'main\n%s\n' "$list" | jq -R . | jq -s -c .)

  generate_docs_for_version main "$latest"
  while IFS= read -r line; do
    generate_docs_for_version "$line" "$latest"
  done <<< "$list"

  cmd_assemble "$targets"

  rm -rf $tmp_flame_src
  rm -rf $tmp_stash
  section "Done."
}

function prepare_flame_repo {
  section 'Downloading Flame repository'
  rm -rf $tmp_flame_src
  rm -rf $tmp_stash
  git clone $flame_repo $tmp_flame_src
  mkdir $tmp_stash
  cp -r $tmp_flame_src/doc/_sphinx $tmp_stash
  cp -r $tmp_flame_src/scripts $tmp_stash
  cp $tmp_flame_src/pubspec.yaml $tmp_stash
}

# Creates a fresh docs/ directory, and populates it with some initial files,
# copied from the template/ directory.
function prepare_docs {
  rm -rf docs
  cp -r template docs/
}

# Builds one version into out/<version>. The latest version is additionally
# copied to out/latest, before the noindex marker is added, so that only the
# versioned copy is hidden from search engines.
function generate_docs_for_version {
  version=$1
  latest_version=$2
  section "Generating docs for Flame [$version]"
  export PUBLISH_PATH=$version

  cd $tmp_flame_src
  git checkout -f "$version"
  # `git checkout -f` leaves ignored files alone, so build output generated for
  # a previously built version survives into this one. That breaks the Flutter
  # apps: `.dart_tool/` holds a generated web plugin registrant, and a
  # registrant left behind by a version using rive ^0.14 imports
  # `package:rive_native`, which versions using rive ^0.13 do not depend on.
  # The app then fails to compile with "Couldn't resolve the package
  # 'rive_native'". Every version has to start from a pristine checkout.
  git clean -xfd
  cd -
  rm -rf $tmp_flame_src/doc/_sphinx
  cp -r $tmp_stash/_sphinx $tmp_flame_src/doc/
  # Since the scripts used in pubspec.yaml are the scripts from main we have to
  # replace the script directory with the newest one.
  rm -rf $tmp_flame_src/scripts
  cp -r $tmp_stash/scripts $tmp_flame_src

  # Remove dartdoc dependency from all pubspec.yaml files, as it can cause
  # analyzer version conflicts with newer Flutter SDKs. Docs are built with
  # Sphinx, so dartdoc is not needed.
  find $tmp_flame_src -name "pubspec.yaml" -exec sed -i '/^\s*dartdoc: \^/d' {} +

  cd $tmp_flame_src

  melos bootstrap || echo "Melos bootstrapping failed, trying without"
  melos run doc-setup
  cd -

  cd $tmp_flame_src/doc/_sphinx
  echo "+ Generating for version $version..."
  pre_process "$version"
  make clean
  make html
  cd -

  mkdir -p $out_dir
  if [[ "$version" == "$latest_version" ]]; then
    rm -rf "$out_dir/latest"
    cp -r $tmp_flame_src/doc/_build/html "$out_dir/latest"
  fi

  rm -rf "${out_dir:?}/$version"
  cp -r $tmp_flame_src/doc/_build/html "$out_dir/$version"
  no_index_string="<meta name=\"robots\" content=\"noindex\">"
  find "$out_dir/$version" -type f -name "*.html" \
    -exec sed -i "/<head>/a  $no_index_string" {} +
}

function pre_process {
  if [ "$version" == 'main' ]; then
    output="\ \ \ \ git:\n      url: https://github.com/flame-engine/flame.git\n      ref: main\n      path: packages/flame"
    find .. -name "resources.md" -exec sed -i "s/--VERSION--/latest/" {} \;
    find .. -name "*.md" -exec sed -i "/--VERSION--.*/a $output" {} \;
    find .. -name "*.md" -exec sed -i "s/ --VERSION--//" {} \;
    find .. -name "*.md" -exec sed -i "/<VERSION>.*/a $output" {} \;
    find .. -name "*.md" -exec sed -i "s/ <VERSION>//" {} \;
  else
    find .. -name "*.md" -exec sed -i "s/--VERSION--/${version#v}/" {} \;
    find .. -name "*.md" -exec sed -i "s/<VERSION>/$version/" {} \;
  fi
}

# Combines the per-version builds into docs/ and publishes them. Version
# directories are read from artifacts/*/ (one directory per CI artifact) when
# present, and from out/ otherwise.
function cmd_assemble {
  local targets="$1"
  section "Assembling docs"
  prepare_docs
  sed -i "s/FLAME_VERSION/latest/g" docs/index.html
  sed -i "s/FLAME_VERSION/latest/g" docs/404.html

  if compgen -G 'artifacts/*/' > /dev/null; then
    cp -r artifacts/*/. docs/
  else
    cp -r $out_dir/. docs/
  fi

  # versions.txt drives the version picker, so the order has to be stable:
  # main first, then newest to oldest.
  jq -r '.[]' <<< "$targets" > docs/versions.txt
  echo "Published versions:"
  cat docs/versions.txt

  git_push
}

function git_push {
  section "Publishing to Git"
  git config user.email "contact@blue-fire.xyz"
  git config user.name "Blue Fire"
  git add docs
  if git commit -m "Update & publish new doc versions"; then
    git push &&
    echo "Successfully pushed changes."
  else
    echo "Nothing to commit."
  fi
}

main "$@"
