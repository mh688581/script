#!/bin/bash
# publish OS version to 19
# author : minheng , 20170119
while  getopts d:s:t:u: opt
do
   case $opt in
   d) dest_path="${OPTARG}";;
   s) src_path="${OPTARG}";;
   t) tag="${OPTARG}";;
   u) BUILD_USER="${OPTARG}";;
   *) echo "option do not exist."
   esac
done

if [ -e isbuilding.txt ];then
echo "patch tag is building,wait...."
exit 1
fi

touch isbuilding.txt
local_dest_path='/mnt/hgfs/360OS_Plt_Release_Version/'$dest_path
local_src_path=$(echo $src_path | sed 's!\\!\/!g' | sed 's!'\/\/10.100.11.207\/OSProject_Test_Verion'!'\/mnt\/hgfs\/OSProject_Test_Verion207'!g')
echo "local_dest_path:$local_dest_path"
echo "local_src_path:$local_src_path"

mkdir -p $tag/Tag_info
mkdir -p $tag/App_info
mkdir -p $tag/Release_Note

cp 操作说明.txt $tag

# check if first publish version or not
FIRST=0
if [ a"`ls $local_dest_path | wc -l`" = a"0" ];then
FIRST=1
fi

create_tag_info() {
echo "$tag" > $tag/Tag_info/${tag}.txt
baseline=`cat $local_src_path/Configurations/Baseline_*.txt`
cp -v $local_src_path/Configurations/Baseline_* $tag/Tag_info/Baseline_${baseline}.txt
cp -v $local_src_path/Configurations/*.xml $tag/Tag_info/
}

create_release_info() {
echo "软件版本：$tag " > release_info.txt
echo "目标路径："'\\10.100.11.19\360OS_Plt_Release_Version\'"$dest_path"'\'"$tag" >> release_info.txt
echo "源路径：$src_path " >> release_info.txt
echo "发布者：$BUILD_USER " >> release_info.txt

mv -v release_info.txt $tag/Release_Note
cp -v $local_src_path/Configurations/CR_List_diff.txt $tag/Release_Note
mv -v *.xls* $tag/Release_Note/平台项目统一基线测试报告.xls
mv -v *.rar  $tag/Release_Note/平台项目统一基线测试报告.rar
}

sync_appinfo() {
INFO=$local_src_path/Configurations/app_info/app_info.txt
LAST_VERSION=`ls -t $local_dest_path | head -n1`
if [ a"$FIRST" = a"1" ]
then
python app_info.py -n $INFO -f
else
python app_info.py -n $INFO -o $local_dest_path/$LAST_VERSION/App_info/app_info.txt
fi
mv -v ApkChangedInfo $tag/App_info
cp -v $INFO $tag/App_info
}

create_patch(){
if [ a"$FIRST" = a"0" ];then
  LAST_VERSION=`ls -t $local_dest_path | head -n1`
  branch=$(grep default $tag/Tag_info/*.xml | awk -F'revision="' '{print $2}' | awk -F'"' '{print $1}')
  #echo "LAST_VERSION:$LAST_VERSION"
  #echo "branch:$branch"
  bash getPatch.sh -p ~/publishOSVersion/android/qiku -b $branch -m $LAST_VERSION -h $tag
  zip -r patch.zip 360os-patch
  mv patch.zip $tag/Release_Note
  if [ "$?" = "0" ];then
     rm -rf 360os-patch
  fi
fi
}

create_tag_info
sync_appinfo
create_release_info
create_patch
cp -rf $tag $local_dest_path/
if [ "$?" = "0" ];then
rm -rf $tag
fi
rm isbuilding.txt
