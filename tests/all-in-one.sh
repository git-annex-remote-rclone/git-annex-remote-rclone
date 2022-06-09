#!/bin/bash

cd "$(mktemp -d ${TMPDIR:-/tmp}/dl-XXXXXXX)"

set -eux

# provide versioning information to possibly ease troubleshooting
git annex version
rclone --version

export HOME=$PWD
echo -e '[local]\ntype = local\nnounc =' > ~/.rclone.conf
# to pacify git/git-annex
git config --global user.name Me
git config --global user.email me@example.com
git config --global init.defaultBranch master

# Prepare rclone remote local store
mkdir rclone-local
export RCLONE_PREFIX=$PWD/rclone-local

git-annex version
mkdir testrepo
cd testrepo
git init .
git-annex init
git-annex initremote GA-rclone-CI type=external externaltype=rclone target=local prefix=$RCLONE_PREFIX chunk=100MiB encryption=shared mac=HMACSHA512

# Rudimentary test, spaces in the filename must be ok, 0 length files should be ok

# TODO: Working with 0-sized file fails for @yarikoptic!
# doesn't work with git-annex 8.20211123-1 10.20220504-1
# kabooms with
#  (from GA-rclone-CI...)
#  git-annex: .git/annex/tmp/SHA256E-s0--e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855: rename: does not exist (No such file or directory)
#  failed
# without even talking to the rclone remote!
# touch "test 0"

echo 1 > "test 1"
git-annex add *
git-annex copy * --to GA-rclone-CI
git-annex drop *
git-annex get *

# test copy/drop/get cycle with parallel execution and good number of files and spaces in the names, and duplicated content/keys
set +x
for f in `seq 1 100`; do echo "load $f" | tee "test-$f.dat" >| "test $f.dat"; done
set -x
git annex add -J5 --quiet .
git-annex copy -J5 --quiet . --to GA-rclone-CI
git-annex drop -J5 --quiet .
git-annex get -J5 --quiet .
git-annex drop --from GA-rclone-CI -J5 --quiet .

# annex testremote --fast
git-annex testremote GA-rclone-CI --fast
