#!/bin/bash -e

tmp_flame_src='_flame'
tmp_stash='_stash'

function main {
  prepare_flame_repo
  prepare_docs

  # Obtain the list of documentation versions to build. The list is
  # created from git tags, skipping the versions that started with 0.
  section "List of versions to build:"
  cd $tmp_flame_src
  list=$(git tag | grep '^[1-9][^-]*$' | sort -rV)
  cd -
  echo "$list"
  latest_version=$(head -n 1 <<< "$list")
  sed -i '' "s/FLAME_VERSION/$latest_version/g" docs/index.html
  sed -i '' "s/FLAME_VERSION/$latest_version/g" docs/404.html

  generate_docs_for_version main
  while IFS= read -r line; do
    generate_docs_for_version "$line"
  done <<< "$list"

  git_push

  rm -rf $tmp_flame_src
  rm -rf $tmp_stash
  section "Done."
}

function section {
  echo
  echo -e "\033[1;32m#-----------------------------------------------------------\033[m"
  echo -e "\033[1;32m# $1\033[m"
  echo -e "\033[1;32m#-----------------------------------------------------------\033[m"
}

function prepare_flame_repo {
  section 'Downloading Flame repository'
  rm -rf $tmp_flame_src
  rm -rf $tmp_stash
  git clone https://github.com/flame-engine/flame.git $tmp_flame_src
  mkdir $tmp_stash
  cp -r $tmp_flame_src/doc/_sphinx $tmp_stash
  cp $tmp_flame_src/melos.yaml $tmp_stash
}

# Creates a fresh docs/ directory, and populates it with some initial files,
# copied from the template/ directory.
function prepare_docs {
  rm -rf docs
  cp -r template docs/
}

function generate_docs_for_version {
  version=$1
  section "Generating docs for Flame [$version]"
  export PUBLISH_PATH=$version

  cd $tmp_flame_src
  git checkout -f "$version"
  cd -
  rm -rf $tmp_flame_src/doc/_sphinx
  cp -r $tmp_stash/_sphinx $tmp_flame_src/doc/
  cp -r $tmp_stash/melos.yaml $tmp_flame_src/

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

  cp -r $tmp_flame_src/doc/_build/html "docs/$version"
  echo "$version" >> docs/versions.txt
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
    find .. -name "*.md" -exec sed -i "s/--VERSION--/$version/" {} \;
    find .. -name "*.md" -exec sed -i "s/<VERSION>/$version/" {} \;
  fi
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

main
