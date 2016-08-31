REPO=/home/bin/repo
SCRIPT_DIR=$(pwd)

while  getopts b:n:d:m: opt
do
   case $opt in
   n) NEW_BRANCH="${OPTARG}";;
   b) BRANCH="${OPTARG}";;
   d) BASE_BRANCH="${OPTARG}";;
   m) QO3="${OPTARG}";;
   *) echo "option do not exist."
      exit 1 ;;
   esac
done

sync_code() {
echo rm -rf android
rm -rf android
echo "--------$REPO init -u ssh://minheng@10.100.13.26:29418/android/qiku/manifests -b $BRANCH"
$REPO init -u ssh://minheng@10.100.13.26:29418/android/qiku/manifests -b $BRANCH

$REPO sync -j32
echo --------$REPO forall -c git checkout origin/$BASE_BRANCH
$REPO forall -c git checkout origin/$BASE_BRANCH
cd android/qiku
echo --------bash $SCRIPT_DIR/detele_files_ignore_git_repo.sh
bash $SCRIPT_DIR/detele_files_ignore_git_repo.sh
cd $SCRIPT_DIR/android/qiku
echo --------$REPO forall -c git checkout origin/$BRANCH .
$REPO forall -c git checkout origin/$BRANCH .
echo --------$REPO forall -c git diff origin/$BRANCH
$REPO forall -c git diff origin/$BRANCH
cd $SCRIPT_DIR
}

change_vendor() {
echo --------begin to replace vendor source codes to jar
cd $SCRIPT_DIR
dire=$1
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
fi

if [ -f libaps_jni64.so ];then
if [ ! -f libaps_jni.so ];then echo error!!!libaps_jni.so 32 not exists!! && exit 1;fi
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
echo qiku-services.jar do not exists!!!! && exit 1
fi

if [ -f qiku-framework.jar ]
then
echo rm -rf android/qiku/vendor/$dire/proprietary/frameworks/base/core/*
rm -rf android/qiku/vendor/$dire/proprietary/frameworks/base/core/* android/qiku/vendor/$dire/proprietary/frameworks/base/telephony
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
MYCONTEXT
else
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
echo $REPO forall -c git push origin $NEW_BRANCH:$NEW_BRANCH
$REPO forall -c git push --no-thin origin $NEW_BRANCH:$NEW_BRANCH
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
git am 0001-OS*.new
rm -rvf 0001-OS* log
echo --------del feature end
}

copy_package() {
cd ${SCRIPT_DIR}/script
echo --------begin to copy packages to platform_app
git fetch
git add -A
git reset --hard origin/$BRANCH
pn=`ls -l | grep ^d | awk '{print $NF}' | egrep -v "OTA|ota|sign|local|tools|cpb"`
if [ "`echo $pn | wc -w`" != "1" ]
then
echo "error: project_name error!! -> $pn"
exit 1
fi
SO_BIT=$(grep '^SO_BIT' ${pn}/PRO_Parameters.txt | awk -F :=  '{print $2}' | tr -d " "| tr -d "\r")
echo SO_BIT : $SO_BIT
export SO_BIT BUILD_ENV=${SCRIPT_DIR}
bash coollife_package.sh ${SCRIPT_DIR}/android/qiku/device/$1/platform_app ${SCRIPT_DIR}/share_win $pn ${SCRIPT_DIR}/android/qiku
cd ${SCRIPT_DIR}/android/qiku/device/$1/platform_app
rm -vf classes.jar obfuscated.jar original.jar
echo --------copy package end
}

sync_code
change_vendor ${QO3}
remove_feature
copy_package ${QO3}
push
echo --------good job!!
