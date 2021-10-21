#!/bin/bash -e

tmp_flame_src='_flame-src'

function main {
  rm -rf docs
  mkdir docs
  touch docs/.nojekyll
  echo 'docs.flame-engine.org' >> docs/CNAME

  git clone https://github.com/flame-engine/flame.git $tmp_flame_src

  cd $tmp_flame_src
  list=`git tag | grep '^1.0.0'`
  cd ..

  while IFS= read -r line; do
    generate $line
  done <<< "$list"
  generate main

  cd docs
  ln -s main/index.html index.html
  cd ..
  git_push

  rm -rf $tmp_flame_src
}

function generate {
  version=$1

  cd $tmp_flame_src
  git checkout $version
  cd ..

  sphinx_dir="$tmp_flame_src/doc/_sphinx"

  if [ ! -d $sphinx_dir ]; then
    echo "+ Skipping version $version as it does not support sphinx yet"
    return
  fi

  cd $sphinx_dir
  echo "+ Generating for version $version..."
  pre_process $version
  pip install -r requirements.txt
  make html

  cd ../../..
  cp -r $tmp_flame_src/doc/_build/html docs/$version
}

function pre_process {
  cd ..
  if [ $version == 'main' ]; then
    output='    git:\n      url: https://github.com/flame-engine/flame.git\n      ref: main'
    find . -name "*.md" -exec sed -i "/<VERSION>.*/a $output/" {} \;
    find . -name "*.md" -exec sed -i "s/ <VERSION>//" {} \;
  else
    find . -name "*.md" -exec sed -i "s/<VERSION>/$version/" {} \;
  fi
  cd _sphinx
}

function generate_index {
  cd docs

  list=`ls -1a | sed -e '1,2d'`

  content=''

  while IFS= read -r line; do
    if [ $line != ".nojekyll" ] && [ $line != "CNAME" ] && [ $line != "index.html" ]; then
     content+="$line"
    fi
  done <<< "$list"

  echo $content > versions.txt
  cd ..
}

function git_push {
  git add docs
  git commit -m "Update & publish new doc versions"
  git push
}

main
