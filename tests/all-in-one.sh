#!/bin/bash

cd "$(mktemp -d "${TMPDIR:-/tmp}/garr-XXXXXXX")"

# recipe from https://stackoverflow.com/a/4024263/1265472
# sort -V seems to work on OSX yoh has access to.
verlte() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

verlt() {
    [ "$1" = "$2" ] && return 1 || verlte $1 $2
}


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

git_annex_version=$(git annex version | awk '/git-annex version:/{print $3;}')

# Prepare rclone remote local store
mkdir rclone-local
export RCLONE_PREFIX=$PWD/rclone-local

# Prepare rclone remote local store for tree export
mkdir rclone-local-export
export RCLONE_EXPORT_PREFIX=$PWD/rclone-local-export

git-annex version
mkdir testrepo
cd testrepo
git init .
git-annex init
git-annex initremote GA-rclone-CI type=external externaltype=rclone target=local prefix=$RCLONE_PREFIX chunk=100MiB encryption=${GARR_TEST_ENCRYPTION:-shared} mac=HMACSHA512
git-annex initremote GA-rclone-export-CI type=external externaltype=rclone target=local prefix=$RCLONE_EXPORT_PREFIX encryption=none exporttree=yes

# Rudimentary test, spaces in the filename must be ok, 0 length files should be ok
if verlte "10.20220525+git73" "$git_annex_version"; then
	# Was fixed in 10.20220525-73-g13fc6a9b6
	echo "I: Fixed git-annex $git_annex_version, adding empty file"
	touch "test 0"
fi

echo 1 > "test 1"
git-annex add *
git commit -m "Initial commit"

git-annex copy * --to GA-rclone-CI
git-annex drop *
git-annex get *
git-annex drop * --from GA-rclone-CI

git status

git-annex export HEAD --to GA-rclone-export-CI
# check if the exported file layout matches workdir, exclude .git and .tmp
diff -ur -s --exclude=".*" . "$RCLONE_EXPORT_PREFIX"

if git-annex drop *; then
    echo "E: DROPPED files despite the only other copy being in an untrusted remote"
    exit 1
fi
git-annex drop --force *
git-annex get *

# Prepare for later tests
git-annex copy * --to GA-rclone-CI

# Test REMOVE with mocked git-annex
mkdir -p $RCLONE_PREFIX/abc/def
echo test > $RCLONE_PREFIX/abc/def/test
[[ -f $RCLONE_PREFIX/abc/def/test ]]
mock-git-annex <<EOF
< ^VERSION
> PREPARE
< ^GETCONFIG prefix$
> VALUE $RCLONE_PREFIX
< ^GETCONFIG target$
> VALUE local
< ^GETCONFIG rclone_layout$
> VALUE lower
< ^PREPARE-SUCCESS
> REMOVE test
< ^DIRHASH-LOWER test$
> VALUE abc/def/
< ^REMOVE-SUCCESS
> REMOVE test
< ^DIRHASH-LOWER test$
> VALUE abc/def/
< ^REMOVE-SUCCESS
> REMOVE test2
< ^DIRHASH-LOWER test2$
> VALUE doe/sno/tex/ist/
< ^REMOVE-SUCCESS
EOF
if [[ -f $RCLONE_PREFIX/abc/def/test ]]; then
	echo "E: REMOVE failed to actually remove file"
	exit 1
fi

# Test CHECKPRESENT with mocked git-annex
mkdir -p $RCLONE_PREFIX/abc/def
echo test > $RCLONE_PREFIX/abc/def/test
mock-git-annex <<EOF
< ^VERSION
> PREPARE
< ^GETCONFIG prefix$
> VALUE $RCLONE_PREFIX
< ^GETCONFIG target$
> VALUE local
< ^GETCONFIG rclone_layout$
> VALUE lower
< ^PREPARE-SUCCESS
> CHECKPRESENT test
< ^DIRHASH-LOWER test$
> VALUE abc/def/
< ^CHECKPRESENT-SUCCESS
> CHECKPRESENT test-non-existing
< ^DIRHASH-LOWER test-non-existing$
> VALUE abc/def/
< ^CHECKPRESENT-FAILURE
> CHECKPRESENT test-non-existing-dir
< ^DIRHASH-LOWER test-non-existing-dir$
> VALUE dir/doe/sno/tex/ist/
< ^CHECKPRESENT-FAILURE
EOF

# Test REMOVEEXPORT with mocked git-annex
mkdir -p $RCLONE_EXPORT_PREFIX/abc/def
echo test > $RCLONE_EXPORT_PREFIX/abc/def/test
[[ -f $RCLONE_EXPORT_PREFIX/abc/def/test ]]
mock-git-annex <<EOF
< ^VERSION
> PREPARE
< ^GETCONFIG prefix$
> VALUE $RCLONE_EXPORT_PREFIX
< ^GETCONFIG target$
> VALUE local
< ^GETCONFIG rclone_layout$
> VALUE lower
< ^PREPARE-SUCCESS
> EXPORT abc/def/test
> REMOVEEXPORT test1234
< ^REMOVE-SUCCESS
> EXPORT abc/def/test
> REMOVEEXPORT test1234
< ^REMOVE-SUCCESS
> EXPORT doe/sno/tex/ist/test2
> REMOVEEXPORT test2345
< ^REMOVE-SUCCESS
EOF
if [[ -f $RCLONE_EXPORT_PREFIX/abc/def/test ]]; then
	echo "E: REMOVEEXPORT failed to actually remove file"
	exit 1
fi

# Test CHECKPRESENTEXPORT with mocked git-annex
mkdir -p $RCLONE_EXPORT_PREFIX/abc/def
echo test > $RCLONE_EXPORT_PREFIX/abc/def/test
mock-git-annex <<EOF
< ^VERSION
> PREPARE
< ^GETCONFIG prefix$
> VALUE $RCLONE_EXPORT_PREFIX
< ^GETCONFIG target$
> VALUE local
< ^GETCONFIG rclone_layout$
> VALUE lower
< ^PREPARE-SUCCESS
> EXPORT abc/def/test
> CHECKPRESENTEXPORT test1234
< ^CHECKPRESENT-SUCCESS
> EXPORT abc/def/test-non-existing
> CHECKPRESENTEXPORT test-non-existing2345
< ^CHECKPRESENT-FAILURE
> EXPORT doe/sno/tex/ist/test-non-existing-dir
> CHECKPRESENTEXPORT test-non-existing-dir3456
< ^CHECKPRESENT-FAILURE
EOF

rm -r $RCLONE_EXPORT_PREFIX/abc

# Do a cycle with --debug to ensure that we are passing desired DEBUG output
git-annex --debug drop test\ 1 2>&1 | grep -q 'rclone.*exited with rc='
git-annex --debug get test\ 1 2>/dev/null
git-annex --debug drop test\ 1 --from GA-rclone-CI 2>&1 | grep -q 'grep.*exited with rc='

# test copy/drop/get cycle with parallel execution and good number of files and spaces in the names, and duplicated content/keys
set +x
for f in `seq 1 20`; do echo "load $f" | tee "test-$f.dat" >| "test $f.dat"; done
set -x
git annex add -J5 --quiet .
git commit -m "add files"

git-annex copy -J5 --quiet . --to GA-rclone-CI
git-annex drop -J5 --quiet .
git-annex get -J5 --quiet .
git-annex drop --from GA-rclone-CI -J5 --quiet .

git-annex export -J5 --quiet HEAD --to GA-rclone-export-CI
# check if the exported file layout matches workdir, exclude .git and .tmp
diff -ur -s --exclude=".*" . "$RCLONE_EXPORT_PREFIX"
git-annex drop -J5 --quiet --force .
git-annex get -J5 --quiet .

# annex testremote --fast
git-annex testremote GA-rclone-CI --fast
