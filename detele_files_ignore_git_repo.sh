#for file in `find . | grep -v "/.git/"`
#do
#base_name=`basename $file`
#echo "base_name: $base_name"
#if [ $file != "." ] && [ $base_name != ".gitignore" ]
#then
#echo "rm $file"
#rm -rf $file
#fi
#done > ../delete_file.log


temp_dir=~/temp/


if [ ! -d $temp_dir ]
then
echo "mkdir $temp_dir"
mkdir $temp_dir
fi

date=`date +%Y%m%d%H%M%S`
temp_dir=$temp_dir$date"/"

echo "mkdir $temp_dir"
mkdir $temp_dir

echo "===========begin copy .git dir to $temp_dir=================="
for copy_file_path in `find . -name ".git" -type d`
do
dis_path=`echo "$copy_file_path" | sed s/.git$//g`
#dis_path=`echo "$copy_file_path"`
dis_path=$temp_dir$dis_path
echo "dis_path: $dis_path"
echo "copy_file_path: $copy_file_path"

if [ ! -d $dis_path ]
then
mkdir -p $dis_path
fi

cp -a $copy_file_path $dis_path 
done

echo "===========end copy .git dir to $temp_dir=================="


echo "===========begin copy .gitignore files to $temp_dir=================="
for ignore_file_path in `find . -name ".gitignore" -type f`
do
dis_path=`echo "$ignore_file_path" | sed s/.gitignore$//g`
dis_path=$temp_dir$dis_path
echo "dis_path: $dis_path"
echo "ignore_file_path: $ignore_file_path"

if [ ! -d $dis_path ]
then
mkdir -p $dis_path
fi

cp -a $ignore_file_path $dis_path 
done
echo "===========end copy .gitignore files to $temp_dir=================="
current_dir=`pwd`
echo "===========begin delete $current_dir and cp $temp_dir to $current_dir=================="
rm -rf ./*
cp -a $temp_dir* .
rm -rf $temp_dir
echo "===========end delete $current_dir and cp $temp_dir to $current_dir=================="
