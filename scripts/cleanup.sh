#!/usr/bin/env bash

function is_git_root {
  if [[ ! -d .git ]]; then
    return 1
  fi
  git remote -v | grep -q -P 'https://github.com/.*?sv-cases\.git'
}

while [[ "${PWD}" != '/' ]]; do
  if is_git_root; then
    break
  fi
  cd ..
done
if [[ "${PWD}" == '/' ]]; then
  echo "not a Git repo"
  exit 2
fi

find -type d \( -name 'work' -or -name 'obj_dir' -or -name 'build' \) -exec rm -rf {} \;
