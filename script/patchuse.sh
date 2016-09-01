#!/bin/bash 
#author: geyu

PATCH_FILE_PATCH="." 
EXTRACT=""

function help(){

  echo -e "\033[31m"
  echo -e "\n   patch progrem."
  echo  "   usage $0 [-dx]"
  echo  "   -d: set root directory."
  echo  "   -xz: extract .gz file"
  echo  "   -xj: extract .bz2 file."
  echo  " "
  echo -e "\033[0m"
  exit 2
}

function exec_patch(){

	patch_arr=(`ls $PATCH_FILE_PATCH|grep .patch`)

	for patchfile in ${patch_arr[@]}
	do
 	  RAW_PATCH_DIR=${patchfile%".patch"}
	  echo "RAW_PATCH_DIR=$RAW_PATCH_DIR"
	  PATCH_DIR=${RAW_PATCH_DIR//+//}
 	  echo "PATCH_DIR=$PATCH_DIR"

	  patch_dir_file=`echo $patchfile|awk -F+ '{print $NF}'`
 	  echo "patch_dir_file=$patch_dir_file"

	  cp $PATCH_FILE_PATCH/$patchfile $PATCH_ROOT_DIR/$PATCH_DIR/$patch_dir_file
	  cd $PATCH_ROOT_DIR/$PATCH_DIR
	  pwd
	  patch -p1 < $patch_dir_file 
	  rm $patch_dir_file
	  cd -
	done

}

function untar_file(){

	if [ -f $PATCH_FILE_PATCH/vendor-360OS* ]
	then
 	 echo -e "\033[34mvendor is exist. \033[0m"

	  if [ "$EXTRACT" == "" ] || [ "$EXTRACT" != "z" -a "$EXTRACT" != "j" ]
  	  then 
	    help
          fi

	  if [ "$EXTRACT" == "z" ]
   	  then
      	   tar -zxvf $PATCH_FILE_PATCH/vendor-360OS* -C $PATCH_ROOT_DIR/vendor/
 	  else
      	   tar -jxvf $PATCH_FILE_PATCH/vendor-360OS* -C $PATCH_ROOT_DIR/vendor/
 	  fi
	fi
	
	if [ -f $PATCH_FILE_PATCH/device-360OS* ]
	then
	 echo -e "\033[34mdevice is exsit. \033[0m"

	 if [ "$EXTRACT" == "" ] || [ "$EXTRACT" != "z" -a "$EXTRACT" != "j" ]
  	 then 
	   help
         fi

	 if [ "$EXTRACT" == "z" ]
	 then
	  tar -zxvf $PATCH_FILE_PATCH/device-360OS* -C $PATCH_ROOT_DIR/device/
 	 else 
	  tar -jxvf $PATCH_FILE_PATCH/device-360OS* -C $PATCH_ROOT_DIR/device/
	 fi
	fi
}

function main(){

  exec_patch
  untar_file

}

if [ $# -lt 2 ]
then
  help
fi

while  getopts d:h:x: opt
do
 case $opt in
 d) PATCH_ROOT_DIR=${OPTARG};;
 h) usage ;;
 x) EXTRACT=${OPTARG};;
 *) echo "option do not exist."
    help ;;
 esac
done

main


