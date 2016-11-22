REPO=/home/bin/repo
SCRIPT_DIR=$(pwd)

while  getopts b:n:d:m:g:t:c: opt
do
   case $opt in
   n) NEW_BRANCH="${OPTARG}";;
   b) BRANCH="${OPTARG}";;
   d) BASE_BRANCH="${OPTARG}";;
   m) QO3="${OPTARG}";;
   g) isGerrit="${OPTARG}";;
   t) Tag="${OPTARG}";;
   c) copy2="${OPTARG}";;
   *) echo "option do not exist."
      exit 1 ;;
   esac
done

if [ $NEW_BRANCH ] && [ $BRANCH ] && [ $BASE_BRANCH ]
then
    echo =========================================
    echo "**check product branch changeset**"
    echo BRANCH : $BRANCH
    echo NEW_BRANCH : $NEW_BRANCH
    echo BASE_BRANCH : $BASE_BRANCH
    echo Tag : $Tag
    echo =========================================
else
    echo vavaribles are empty...
    exit 1   
fi

if [ -f "isbuilding.txt" ]
then
echo please wait...project is building...
exit 1
else 
touch isbuilding.txt
fi

sync_code() {
echo rm -rf android
rm -rf android
echo "--------$REPO init -u ssh://minheng@10.100.13.26:29418/android/qiku/manifests -b $BASE_BRANCH"
$REPO init -u ssh://minheng@10.100.13.26:29418/android/qiku/manifests -b $BASE_BRANCH
if [ $? != '0' ] ;then
    echo "============Product branch init Failed! ============"
    rm -rf $SCRIPT_DIR/isbuilding.txt
    exit 1
fi

$REPO sync -j32
if [ $? != '0' ] ;then
    echo "============Product branch sync Failed! ============"
    rm -rf $SCRIPT_DIR/isbuilding.txt
    exit 1
fi
#echo --------$REPO forall -c git checkout origin/$BASE_BRANCH
#$REPO forall -c git reset --hard origin/$BASE_BRANCH
#$REPO forall -c git checkout origin/$BASE_BRANCH
cd android/qiku
echo --------bash $SCRIPT_DIR/detele_files_ignore_git_repo.sh
bash $SCRIPT_DIR/detele_files_ignore_git_repo.sh
cd $SCRIPT_DIR/android/qiku
if [ a"$Tag" != a"default" ]
then
echo --------$REPO forall -c git checkout $Tag .
$REPO forall -c git checkout $Tag .
echo --------$REPO forall -c git diff $Tag
$REPO forall -c git diff $Tag
else
echo --------$REPO forall -c git checkout origin/$BRANCH .
$REPO forall -c git checkout origin/$BRANCH .
echo --------$REPO forall -c git diff origin/$BRANCH
$REPO forall -c git diff origin/$BRANCH
fi
echo --------rm -rf $SCRIPT_DIR/android/qiku/script/*
rm -rf $SCRIPT_DIR/android/qiku/script/* $SCRIPT_DIR/android/qiku/copy_lib.sh
}

change_vendor() {
cd $SCRIPT_DIR
if [ ! -f copy_libs.zip ];then echo "please upload binary files!..." && rm -rf $SCRIPT_DIR/isbuilding.txt && exit 1;fi
unzip copy_libs.zip
rm -rf copy_libs.zip
echo --------begin to replace vendor source codes to jar
dire=$1
if [ -f libqkparam64.a ]
then
if [ ! -f libqkparam.a ];then echo error!!!libqkparam.a 32 not exists!! && rm -rf $SCRIPT_DIR/isbuilding.txt && exit 1;fi
echo rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkparam/*
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkparam/*
mv -v libqkparam.a libqkparam64.a android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkparam/
tee android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkparam/Android.mk <<MYCONTEXT
LOCAL_PATH:= \$(call my-dir)

include \$(CLEAR_VARS)

LOCAL_C_INCLUDES += \\
        vendor/$dire/opensource/frameworks/native/cmds/libqkparam/include

LOCAL_MULTILIB := both
LOCAL_SRC_FILES_64 := libqkparam64.a
LOCAL_SRC_FILES_32 := libqkparam.a

LOCAL_MODULE := libqkparam

LOCAL_MODULE_SUFFIX := .a

LOCAL_MODULE_TAGS := optional

LOCAL_MODULE_CLASS := STATIC_LIBRARIES

include \$(BUILD_PREBUILT)
MYCONTEXT
else
if [ -f libqkparam.a ]
then
echo rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkparam/*
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkparam/*
mv -v libqkparam.a android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkparam/
tee android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkparam/Android.mk <<MYCONTEXT
LOCAL_PATH:= \$(call my-dir)

include \$(CLEAR_VARS)

LOCAL_C_INCLUDES += \\
        vendor/$dire/opensource/frameworks/native/cmds/libqkparam/include

LOCAL_SRC_FILES := \\
    libqkparam.a

LOCAL_MODULE := libqkparam

LOCAL_MODULE_SUFFIX := .a

LOCAL_MODULE_TAGS := optional

LOCAL_MODULE_CLASS := STATIC_LIBRARIES

include \$(BUILD_PREBUILT)
MYCONTEXT
else
rm -rf $SCRIPT_DIR/isbuilding.txt
echo libqkparam.a do not exists!!!! && exit 1
fi
fi

if [ -f libdata_monitor64.a ]
then
if [ ! -f libdata_monitor.a ];then echo error!!!libdata_monitor.a 32 not exists!! && rm -rf $SCRIPT_DIR/isbuilding.txt && exit 1;fi
echo rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/dataflow_monitor/*
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/dataflow_monitor/*
mv -v libdata_monitor.a libdata_monitor64.a android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/dataflow_monitor/
tee android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/dataflow_monitor/Android.mk <<MYCONTEXT
LOCAL_PATH:= \$(call my-dir)
include \$(CLEAR_VARS)

LOCAL_C_INCLUDES := bionic/libc
LOCAL_SRC_FILES_32 := libdata_monitor.a
LOCAL_SRC_FILES_64 := libdata_monitor64.a
LOCAL_MULTILIB := both
LOCAL_MODULE := libdata_monitor
LOCAL_MODULE_SUFFIX := .a
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := STATIC_LIBRARIES
LOCAL_ADDITIONAL_DEPENDENCIES := \$(libc_common_additional_dependencies)
LOCAL_CXX_STL := none
LOCAL_SYSTEM_SHARED_LIBRARIES :=
LOCAL_ADDRESS_SANITIZER := false
LOCAL_NATIVE_COVERAGE := \$(bionic_coverage)

include \$(BUILD_PREBUILT)
MYCONTEXT
else
if [ -f libdata_monitor.a ]
then
echo rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/dataflow_monitor/*
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/dataflow_monitor/*
mv -v libdata_monitor.a android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/dataflow_monitor/
tee android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/dataflow_monitor/Android.mk <<MYCONTEXT
LOCAL_PATH:= \$(call my-dir)
include \$(CLEAR_VARS)

LOCAL_C_INCLUDES := bionic/libc
LOCAL_SRC_FILES := \\
    libdata_monitor.a
LOCAL_MODULE := libdata_monitor
LOCAL_MODULE_SUFFIX := .a
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := STATIC_LIBRARIES
LOCAL_ADDITIONAL_DEPENDENCIES := \$(libc_common_additional_dependencies)
LOCAL_CXX_STL := none
LOCAL_SYSTEM_SHARED_LIBRARIES :=
LOCAL_ADDRESS_SANITIZER := false
LOCAL_NATIVE_COVERAGE := \$(bionic_coverage)

include \$(BUILD_PREBUILT)
MYCONTEXT
else
rm -rf $SCRIPT_DIR/isbuilding.txt
echo libdata_monitor.a do not exists!!!! && exit 1
fi
fi

if [ -f libqkinstalld64.a ]
then
if [ ! -f libqkinstalld.a ];then echo error!!!libqkinstalld.a 32 not exists!! && rm -rf $SCRIPT_DIR/isbuilding.txt && exit 1;fi
echo rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkinstalld/*.mk *.cpp
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkinstalld/*.mk
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkinstalld/*.cpp
mv -v libqkinstalld.a libqkinstalld64.a android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkinstalld/
tee android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkinstalld/Android.mk <<MYCONTEXT
LOCAL_PATH:= \$(call my-dir)

include \$(CLEAR_VARS)

LOCAL_EXPORT_C_INCLUDE_DIRS := \\
        \$(LOCAL_PATH)

LOCAL_SRC_FILES_64 := libqkinstalld64.a
LOCAL_SRC_FILES_32 := libqkinstalld.a
LOCAL_MULTILIB := both

LOCAL_MODULE := libqkinstalld

LOCAL_MODULE_SUFFIX := .a

LOCAL_MODULE_TAGS := optional

LOCAL_MODULE_CLASS := STATIC_LIBRARIES

include \$(BUILD_PREBUILT)
MYCONTEXT
else
if [ -f libqkinstalld.a ]
then
echo rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkinstalld/*.mk *.cpp
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkinstalld/*.mk
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkinstalld/*.cpp
mv -v libqkinstalld.a android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkinstalld/
tee android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libqkinstalld/Android.mk <<MYCONTEXT
LOCAL_PATH:= \$(call my-dir)

include \$(CLEAR_VARS)

LOCAL_EXPORT_C_INCLUDE_DIRS := \\
        \$(LOCAL_PATH)

LOCAL_SRC_FILES := \\
    libqkinstalld.a

LOCAL_MODULE := libqkinstalld

LOCAL_MODULE_SUFFIX := .a

LOCAL_MODULE_TAGS := optional

LOCAL_MODULE_CLASS := STATIC_LIBRARIES

include \$(BUILD_PREBUILT)
MYCONTEXT
else
rm -rf $SCRIPT_DIR/isbuilding.txt
echo libqkinstalld.a do not exists!!!! && exit 1
fi
fi

if [ -f libqksafetyspace64.so ];then
if [ ! -f libqksafetyspace.so ];then echo error!!!libqksafetyspace.so 32 not exists!! && rm -rf $SCRIPT_DIR/isbuilding.txt && exit 1;fi
echo rm -rf android/qiku/vendor/$dire/proprietary/frameworks/base/core/jni/libqksafetyspace/*.mk *.cpp
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/base/core/jni/libqksafetyspace/*.mk
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/base/core/jni/libqksafetyspace/*.cpp
mv -v libqksafetyspace.so libqksafetyspace64.so android/qiku/vendor/$dire/proprietary/frameworks/base/core/jni/libqksafetyspace/
tee android/qiku/vendor/$dire/proprietary/frameworks/base/core/jni/libqksafetyspace/Android.mk <<MYCONTEXT
LOCAL_PATH:= \$(call my-dir)
include \$(CLEAR_VARS)
LOCAL_MODULE := libqksafetyspace
LOCAL_SRC_FILES_64 := libqksafetyspace64.so
LOCAL_SRC_FILES_32 := libqksafetyspace.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_TAGS := optional
LOCAL_EXPORT_C_INCLUDE_DIRS := \\
        \$(LOCAL_PATH)
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_PATH_64 := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)
LOCAL_MODULE_PATH_32 := \$(2ND_TARGET_OUT_VENDOR_SHARED_LIBRARIES)
LOCAL_MULTILIB := both
include \$(BUILD_PREBUILT)
MYCONTEXT
else
if [ -f libqksafetyspace.so ]
then
echo rm -rf android/qiku/vendor/$dire/proprietary/frameworks/base/core/jni/libqksafetyspace/*.mk *.cpp
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/base/core/jni/libqksafetyspace/*.mk
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/base/core/jni/libqksafetyspace/*.cpp
mv -v libqksafetyspace.so android/qiku/vendor/$dire/proprietary/frameworks/base/core/jni/libqksafetyspace/
tee android/qiku/vendor/$dire/proprietary/frameworks/base/core/jni/libqksafetyspace/Android.mk <<MYCONTEXT
LOCAL_PATH:= \$(call my-dir)

include \$(CLEAR_VARS)

LOCAL_SRC_FILES := \\
    libqksafetyspace.so

LOCAL_MODULE := libqksafetyspace

LOCAL_EXPORT_C_INCLUDE_DIRS := \\
        \$(LOCAL_PATH)

LOCAL_MODULE_SUFFIX := .so

LOCAL_MODULE_TAGS := optional

LOCAL_MODULE_CLASS := SHARED_LIBRARIES

LOCAL_MODULE_PATH := \$(TARGET_OUT_SHARED_LIBRARIES)

include \$(BUILD_PREBUILT)
MYCONTEXT
else 
rm -rf $SCRIPT_DIR/isbuilding.txt
echo libqksafetyspace.so do not exists!!!! && exit 1
fi
fi

if [ -f libaps_jni64.so ];then
if [ ! -f libaps_jni.so ];then echo error!!!libaps_jni.so 32 not exists!! && rm -rf $SCRIPT_DIR/isbuilding.txt && exit 1;fi
echo rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libaps_jni/*
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libaps_jni/*
mv -v libaps_jni.so libaps_jni64.so android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libaps_jni/
tee android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libaps_jni/Android.mk <<MYCONTEXT
LOCAL_PATH:= \$(call my-dir)
include \$(CLEAR_VARS)
LOCAL_MODULE := libaps_jni
LOCAL_SRC_FILES_64 := libaps_jni64.so
LOCAL_SRC_FILES_32 := libaps_jni.so
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_PATH_64 := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)
LOCAL_MODULE_PATH_32 := \$(2ND_TARGET_OUT_VENDOR_SHARED_LIBRARIES)
LOCAL_MULTILIB := both
include \$(BUILD_PREBUILT)
MYCONTEXT
else
if [ -f libaps_jni.so ]
then
echo rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libaps_jni/*
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libaps_jni/*
mv -v libaps_jni.so android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libaps_jni/
tee android/qiku/vendor/$dire/proprietary/frameworks/native/cmds/libaps_jni/Android.mk <<MYCONTEXT
LOCAL_PATH:= \$(call my-dir)

include \$(CLEAR_VARS)

LOCAL_SRC_FILES := \\
    libaps_jni.so

LOCAL_MODULE := libaps_jni

LOCAL_MODULE_SUFFIX := .so

LOCAL_MODULE_TAGS := optional

LOCAL_MODULE_CLASS := SHARED_LIBRARIES

LOCAL_MODULE_PATH := \$(TARGET_OUT_SHARED_LIBRARIES)

include \$(BUILD_PREBUILT)
MYCONTEXT
else 
rm -rf $SCRIPT_DIR/isbuilding.txt
echo libaps_jni.so do not exists!!!! && exit 1
fi
fi

if [ -f qiku-services.jar ]
then
echo rm -rf android/qiku/vendor/$dire/proprietary/frameworks/base/services/core/*
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/base/services/core/*
mv -v qiku-services.jar android/qiku/vendor/$dire/proprietary/frameworks/base/services/core/
tee android/qiku/vendor/$dire/proprietary/frameworks/base/services/core/Android.mk <<MYCONTEXT
LOCAL_PATH:= \$(call my-dir)

include \$(CLEAR_VARS)

LOCAL_SRC_FILES := \\
    qiku-services.jar

LOCAL_MODULE := qiku-services

LOCAL_MODULE_SUFFIX := .jar

LOCAL_MODULE_TAGS := optional

LOCAL_MODULE_CLASS := JAVA_LIBRARIES

include \$(BUILD_PREBUILT)
MYCONTEXT
else
rm -rf $SCRIPT_DIR/isbuilding.txt
echo qiku-services.jar do not exists!!!! && exit 1
fi

if [ -f qiku-framework.jar ]
then
echo rm -rf android/qiku/vendor/$dire/proprietary/frameworks/base/core/ except jni
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/base/core/java android/qiku/vendor/$dire/proprietary/frameworks/base/telephony
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/base/core/*.mk android/qiku/vendor/$dire/proprietary/frameworks/base/core/*.flags
mv -v qiku-framework.jar android/qiku/vendor/$dire/proprietary/frameworks/base/core/
tee android/qiku/vendor/$dire/proprietary/frameworks/base/core/Android.mk <<MYCONTEXT
LOCAL_PATH:= \$(call my-dir)

include \$(CLEAR_VARS)

LOCAL_SRC_FILES := \\
    qiku-framework.jar

LOCAL_MODULE := qiku-framework

LOCAL_MODULE_SUFFIX := .jar

LOCAL_MODULE_TAGS := optional

LOCAL_MODULE_CLASS := JAVA_LIBRARIES

include \$(BUILD_PREBUILT)

include \$(call all-makefiles-under,\$(LOCAL_PATH)) 
MYCONTEXT
else
rm -rf $SCRIPT_DIR/isbuilding.txt
echo qiku-framework.jar do not exists!!!! && exit 1
fi
echo --------replace vendor end
}

push() {
cd $SCRIPT_DIR
echo --------begin to push $NEW_BRANCH
echo $REPO forall -c git add -A
$REPO forall -c git add -A
echo $REPO forall -c git commit -sm "patch for $NEW_BRANCH"
date=`date +%y%m%d`
$REPO forall -c git commit -sm "patch for $NEW_BRANCH $date"
echo $REPO forall -c git checkout -b $NEW_BRANCH
$REPO forall -c git branch -D $NEW_BRANCH
$REPO forall -c git branch $NEW_BRANCH
echo --------pushToGerrit : $isGerrit---------
if [ a"$isGerrit" = a"no" ]
then
echo $REPO forall -c git push origin $NEW_BRANCH:$NEW_BRANCH
$REPO forall -c git push --no-thin origin $NEW_BRANCH:$NEW_BRANCH
else
echo $REPO forall -c git push origin $NEW_BRANCH:refs/for/$NEW_BRANCH
$REPO forall -c git push --no-thin origin $NEW_BRANCH:refs/for/$NEW_BRANCH
fi
echo --------push patch end
}

remove_feature() {
cd ${SCRIPT_DIR}/android/qiku/frameworks
echo --------begin to del feature in frameworks
git add -A
git commit -sm OS_patch
git format-patch HEAD^
python ${SCRIPT_DIR}/patch_processor.py 0001-OS_patch* ${SCRIPT_DIR}/android/qiku/device/${QO3}/QikuFeature/product_features > log
git reset --hard HEAD^
git apply 0001-OS*.new
rm -rvf 0001-OS* log
echo --------del feature end
}

copy_package2() {
mkdir -p ${SCRIPT_DIR}/script
cd ${SCRIPT_DIR}/script
echo --------begin to copy packages to platform_app
git fetch
git add -A
git reset --hard origin/$BRANCH
pn=`ls -l | grep ^d | awk '{print $NF}' | egrep -v "OTA|ota|sign|local|tools|cpb|for_wtwd"`
if [ "`echo $pn | wc -w`" != "1" ]
then
echo "error: project_name error!! -> $pn"
rm -rf $SCRIPT_DIR/isbuilding.txt
exit 1
fi
SO_BIT=$(grep '^SO_BIT' ${pn}/PRO_Parameters.txt | awk -F :=  '{print $2}' | tr -d " "| tr -d "\r")
echo SO_BIT : $SO_BIT
export SO_BIT BUILD_ENV=${SCRIPT_DIR}
rm -rf ${SCRIPT_DIR}/share_win/*
bash coollife_package.sh ${SCRIPT_DIR}/android/qiku/device/$1/platform_app ${SCRIPT_DIR}/share_win $pn ${SCRIPT_DIR}/android/qiku
cd ${SCRIPT_DIR}/android/qiku/device/$1/platform_app
rm -rf classes.jar obfuscated.jar original.jar *.txt *.xls code_check symbol
echo --------copy package end
}

copy_package() {
echo --------begin to copy packages to platform_app
cd ${SCRIPT_DIR}/android/qiku/device/$1
find . -name "copy*.sh" | while read line
do
dir=${line%/*}
cd $dir
pwd
bash copy*.sh
rm -rf platform_app/symbol
cd ${SCRIPT_DIR}/android/qiku/device/$1
done
echo --------copy package end
}

sync_code
change_vendor ${QO3}
remove_feature
if [ a"${copy2}" = a"script" ];then
copy_package2 ${QO3}
else
copy_package ${QO3}
fi
push
rm -rf $SCRIPT_DIR/isbuilding.txt
echo --------good job!!
