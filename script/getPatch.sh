#!/bin/bash
#author: geyu

ROOT_PATH=""
DST_FOLDER="360os-patch"
SCRIPT_PATH=""
BRANCH=""

while getopts p:d:b:l: opt
do
 case $opt in
  p) ROOT_PATH=${OPTARG};;
  d) DST_FOLDER=${OPTARG};;
  b) BRANCH=${OPTARG};;
  l) LOCAL_BRANCH=${OPTARG};;
  *) usage;;
 esac
done

function check_before(){

  echo -e "\n\033[34mROOT_PATH: $ROOT_PATH \033[0m"
  echo -e "\033[34mDST_FOLDER: $DST_FOLDER \033[0m"
  echo -e "\033[34mBRANCH: $BRANCH \033[0m\n"
 
  if [ "$ROOT_PATH" = "" -o "$DST_FOLDER" = "" -o "$BRANCH" = "" -o "$LOCAL_BRANCH" = "" ]
  then
    usage
    exit 128
  fi
}

function usage(){

  echo -e "\n\033[31musage:\033[0m"
  echo -e "\033[31m`basename $0` [-pdbl]\033[0m"
  echo -e "\t\033[31m-p set the code root path\033[0m"
  echo -e "\t\033[31m-d set the release folder\033[0m"
  echo -e "\t\033[31m-b set the remote branch to generate patch\033[0m"
  echo -e "\t\033[31m-l set the local branch to compare with remote branch\033[0m"

}

function get_patch(){

 SCRIPT_PATH=`pwd`

 cd $ROOT_PATH

 echo -e "\033[32m"
 echo -e "\ngenerate patch please wait."
 repo forall -c git add --all .
 repo forall -c git reset --hard
 repo forall -c git fetch origin $LOCAL_BRANCH
 repo forall -c git checkout origin/$LOCAL_BRANCH
 #bash ${SCRIPT_PATH}/detele_files_ignore_git_repo.sh
 repo forall -c git checkout $BRANCH .

 #repo forall -c git add --all .
 repo forall -c git commit -sm "patch"
 repo forall -c "git format-patch HEAD~1"
 echo -e "\ngenerate path is finished."
 echo -e "\033[0m"
 cd -

}

function release_patch(){

 PATCH_FILE=(`find $ROOT_PATH -name 0001-patch.patch`)

 if [ $? -ne 0 ]
 then 
  echo "find $ROOT_PATH error"
 fi

 if [ ! -d $DST_FOLDER ]
 then
  mkdir -p $DST_FOLDER
  if [ $? -ne 0 ]
  then
   echo -e "\033[31mdst folder is illegal. please ensure the -d parameter you input is correct.\033[0m"
  fi
 fi
 
 for patch_file in ${PATCH_FILE[@]}
 do
  echo $patch_file
  #preffix=`echo $patch_file|awk -F/ '{print $(NF-1)}'`
  file=`echo $patch_file|awk -F/ '{print $NF}'`
  file="/"$file
  echo $file
  raw_preffix=${patch_file#$ROOT_PATH}
  raw_preffix_minus_file=${raw_preffix%$file}
  echo $raw_preffix_minus_file
  preffix=${raw_preffix_minus_file////+}
  echo $preffix

  if [ "$preffix" = "360OS" -o "$preffix" = "script" ]
  then
   continue
  fi

  cp $patch_file $DST_FOLDER/$preffix".patch"
  echo -e "\033[32mcopy $patch_file to $DST_FOLDER/"$preffix".patch\033[0m"
 done

 echo -e "\n\033[32mrelease job is finished. all success. realse folder is "$DST_FOLDER"\033[0m"
}

zip360os(){
	cd $ROOT_PATH/device/360OS/platform_app
	find . -type d | xargs rm -rf
        cd -
	cd $ROOT_PATH/device/360OS/media
	find . -type d | xargs rm -rf
        cd -
	cd $ROOT_PATH/device
	zip -r device-360OS.zip 360OS/*
	#zip -d device-360OS.zip .git
        cd -
	cp $ROOT_PATH/device/device-360OS.zip $DST_FOLDER/
	cd $ROOT_PATH/vendor
	zip -r vendor-360OS.zip 360OS/*
	#zip -d vendor-360OS.zip .git 
        cd -
	cp $ROOT_PATH/vendor/vendor-360OS.zip $DST_FOLDER/
        cd $ROOT_PATH/packages/apps/Settings/
        zip -r Setting-res.zip res/
        cd -
        cp $ROOT_PATH/packages/apps/Settings/Setting-res.zip $DST_FOLDER/
}


function main(){
 
 check_before
 get_patch
 release_patch
 zip360os

}

main
