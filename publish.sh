#!/bin/bash -e

tmp_flame_src='_flame-src'

function main {
  rm -rf docs $tmp_flame_src
  mkdir docs
  touch docs/.nojekyll
  echo 'docs.flame-engine.org' >> docs/CNAME

  git clone https://github.com/flame-engine/flame.git $tmp_flame_src

  cd $tmp_flame_src
  # This sorts the list in a semantic versioning fashion
  list=$(git tag | tr - \~ | sort -V | tr \~ - | grep '^1' | grep -v '-' | tac)
  latest_version=$(head -n 1 <<< $list)
  cd ..

  while IFS= read -r line; do
    generate $line
  done <<< "$list"
  generate main

  cp index_redirect.html docs/index.html
  cp index_redirect.html docs/404.html
  sed -i "s/FLAME_VERSION/$latest_version/g" docs/index.html
  sed -i "s/FLAME_VERSION/$latest_version/g" docs/404.html
  git_push

  rm -rf $tmp_flame_src
  echo "Successfully built the docs"
}

function generate {
  version=$1

  echo "Generating $version"
  export PUBLISH_PATH=$version

  cd $tmp_flame_src
  git checkout -f $version
  rm -rf doc/_sphinx || echo "Not removing non-existing _sphinx directory"
  cp -r ../_sphinx doc/

  sphinx_dir="doc/_sphinx"

  if [ ! -d $sphinx_dir ]; then
    echo "+ Skipping version $version as it does not support sphinx yet"
    return
  fi

  melos bootstrap || echo "Melos bootstrapping failed, trying without"
  cd $sphinx_dir
  echo "+ Generating for version $version..."
  pre_process $version
  pip install -r requirements.txt
  pip install 'jinja2>=3.1.0'
  make clean
  make html

  cd ../../..
  cp -r $tmp_flame_src/doc/_build/html docs/$version
  echo $version >> docs/versions.txt
}

function pre_process {
  cd ..
  if [ $version == 'main' ]; then
    output="\ \ \ \ git:\n      url: https://github.com/flame-engine/flame.git\n      ref: main\n      path: packages/flame"
    find . -name "*.md" -exec sed -i "/<VERSION>.*/a $output" {} \;
    find . -name "*.md" -exec sed -i "s/ <VERSION>//" {} \;
  else
    find . -name "*.md" -exec sed -i "s/<VERSION>/$version/" {} \;
  fi
  cd _sphinx
}

function git_push {
  git config user.email "contact@blue-fire.xyz"
  git config user.name "Blue Fire"
  git add docs
  git commit -m "Update & publish new doc versions"
  git push
}

main
