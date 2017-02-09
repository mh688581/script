#!/bin/bash
# patch tag v1.0
# author : minheng 20170106
REPO=/home/bin/repo
CODE_TAG=$1
BRANCH=$2
TAG_NAME=$3

if [ -e isbuilding.txt ];then
echo "publish is building,wait...."
exit 1
fi

touch isbuilding.txt
#echo rm -rf android
#rm -rf android
echo $REPO init -u ssh://minheng@10.100.13.26:29418/android/qiku/manifests -b ${BRANCH}
$REPO init -u ssh://minheng@10.100.13.26:29418/android/qiku/manifests -b ${BRANCH}
echo $REPO sync -c -j32
$REPO sync -c -j32

echo $REPO init -u ssh://minheng@10.100.13.26:29418/android/qiku/manifests -b refs/tags/$CODE_TAG -m ${BRANCH}_tag.xml
$REPO init -u ssh://minheng@10.100.13.26:29418/android/qiku/manifests -b refs/tags/$CODE_TAG -m ${BRANCH}_tag.xml
echo $REPO sync -c -j32
$REPO sync -c -j32
echo $REPO forall -c git tag $TAG_NAME
$REPO forall -c git tag $TAG_NAME
echo $REPO forall -c git push -f origin $TAG_NAME
$REPO forall -c git push -f origin $TAG_NAME
rm isbuilding.txt
