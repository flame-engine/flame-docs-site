#!/bin/bash -e

tmp_flame_src='_flame-src'

function main {
  rm -rf docs
  mkdir docs

  git clone git@github.com:flame-engine/flame.git $tmp_flame_src

  cd $tmp_flame_src
  list=`git tag | grep '^1.0.0'`
  cd ..

  while IFS= read -r line; do
    generate $line
  done <<< "$list"

  generate main

  generate_index

  rm -rf $tmp_flame_src

  git add docs
  git commit -m "Update versions"
  git push
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
    output='\n    git:\n      url: https://github.com/flame-engine/flame.git\n      ref: main'
  else
    output=$version
  fi
  find . -name "*.md" | rex -f '<VERSION>' "$output"
  cd _sphinx
}

function generate_index {
  cd docs

  list=`ls -1a | sed -e '1,2d'`

  content=''
  content+='<ul>'

  while IFS= read -r line; do
    content+="<li><a href=\"$line/index.html\">$line</a></li>"
  done <<< "$list"
  content+='</ul>'

  cp ../index_template.html index.html
  echo 'index.html' | rex -f '{content}' "$content"
}

main
