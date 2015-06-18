#!/bin/bash
# TESS3 directory on my linux computer
cd /home/cayek/Projects/TESS3
ROUGE="\\033[1;31m"
dir_TESS3=`pwd`

function test {
    eval "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo -e "$ROUGE" "error with $1" >&2
	exit 1
    fi
    return $status
}


###############################
# push all changes to develop #
###############################
git checkout develop
# check if there are not commited file
status=`git status 2>&1 | tee`
dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`

if [ "${dirty}" == "0" ] || [ "${newfile}" == "0" ] || [ "${renamed}" == "0" ] || [ "${deleted}" == "0" ]; then
echo -e "$ROUGE" "commit in develop branch before release"
exit 1
fi

#git push
git push

#################
# try to deploy #
#################

cd ~/Téléchargements/

rm -rf TESS3_testdeploy
git clone ssh://cayek@patator.imag.fr/home/cayek/noBackup/TESS3.git TESS3_testdeploy
cd TESS3_testdeploy/
git checkout develop

mkdir build
cd build
test "cmake -DCMAKE_BUILD_TYPE=release ../ &> /dev/null"
test "make TESS3 &> /dev/null"
cd ../
test "./setupRsrc.sh &> /dev/null"

#############
# run tests #
#############

test "Rscript test/scriptR/Rtest.R  &> /dev/null"

cd ~/Téléchargements/
rm -rf TESS3_testdeploy

#################
# if ok release #
#################
cd "$dir_TESS3"

git checkout master
git merge develop

# start release #

# compile documentation
# cd doc/src/
# test "latex note.tex &> /dev/null"
# test "bibtex note &> /dev/null"
# test "latex note.tex &> /dev/null"
# test "latex note.tex &> /dev/null"
# test "dvipdf note.dvi &> /dev/null"
# rm -f ../documentation.pdf
# cp -f note.pdf ../documentation.pdf 
# git add ../documentation.pdf
# cd "$dir_TESS3"

# remove file which are not suppose to be in the release version
cat releaseRemove | xargs git rm --cached 

DATE=`date +%Y-%m-%d`
git commit -m "Release date: $DATE"

#push on github
ssh cayek@patator.imag.fr <<EOF
cd noBackup/TESS3.git
git push 
logout
EOF
git checkout develop