#!/bin/sh

# cert_dir=certs
# apks_dir=apks

function usage() 
{
  echo "Usage: `basename $0` -c [cert dir] -a [apk dir]" >&2
  exit 1
}

if [[ $# -lt 1 ]]
then
  usage
fi

while getopts ":a:c:" opt
do
 case $opt in
    a)
      apks_dir=$OPTARG                 
      ;;
    c)
      cert_dir=$OPTARG
      ;;
    ?)
      usage
      ;;
  esac
done

if  [ ! -d "$cert_dir" -a ! -d "$apks_dir" ]
then
  echo "Invalid certs dir: '$cert_dir' or apks dir: '$apks_dir'" >&2
  usage
fi

CER_NAMES=(
platform
shared
media
testkey
)

# qiku certs md5
CER_QIKU_MD5S=(
cc471ce767d9601effea74fd7175864e # platform
736d75d5c93e5c110148aa82f5a0c8ec # shared
f32b8f66cbf70867019511f4c959ca72 # media
ca57d0dd2393a7cccf9574854e117e9d # testkey
)

# google certs md5, only for userdebug/eng build
CER_GOOGLE_MD5S=(
8ddb342f2da5408402d7568af21e29f9 # platform
5dc8201f7db1ba4b9c8fc44146c5bcc2 # shared
1900bbfba756edd3419022576f3814ff # media
e89b158e4bcf988ebd09eb83f5378e87 # testkey
)

# for user release build
CER_TARGET_MD5S=(
"-" # 8ddb342f2da5408402d7568af21e29f9 # platform (google)
"-" # 5dc8201f7db1ba4b9c8fc44146c5bcc2 # shared
"-" # 1900bbfba756edd3419022576f3814ff # media
"-" # e89b158e4bcf988ebd09eb83f5378e87 # testkey
)

function showapk_certs() 
{
  CER_APKS=(
  framework-res.apk
  ContactsProvider.apk # CP_ContactsProvider.apk
  MediaProvider.apk
  HTMLViewer.apk
  )

  i=0
  ok=0
  for apk in ${CER_APKS[@]}
  do
    apk=$apks_dir/*$apk
    if test -f $apk
    then 
      echo "  -- $apk"
      cmd5=$(unzip -p $apk META-INF/*.RSA | openssl pkcs7 -print_certs -inform DER | openssl x509 -inform PEM -outform DER | md5sum | cut -d' ' -f1)
      echo "  $cmd5 # ${CER_NAMES[$i]}" >&2
      CER_TARGET_MD5S[$i]=$cmd5
      ok=$((ok+1))
    fi
    i=$((i+1))
  done

  echo 
  return $ok
}

function print_md5s()
{
  echo 
  echo "static final String[] $1 = {"

  i=0
  shift
  for cm in $*
  do
    echo -n "        \"$cm\""
    if [[ $i -lt 3 ]]
    then
      echo ", // ${CER_NAMES[$i]}"
    else
      echo "  // ${CER_NAMES[$i]}"
    fi
    i=$((i+1))
  done

  echo "};"
  echo
}

print_md5s qikuCertsMd5 ${CER_QIKU_MD5S[@]}

print_md5s targetCertsMd5_dbg ${CER_GOOGLE_MD5S[@]}

echo ">>> Extract certs md5 from apks ..." >&2

showapk_certs

if [[ $? -gt 0 ]]
then
  print_md5s targetCertsMd5_rel ${CER_TARGET_MD5S[@]}
else
  echo "*** Failed to extract ..." >&2
fi

echo 
echo ">>> Calculate certs md5 from x509 pems ..." >&2

i=0
for cert in ${CER_NAMES[@]}
do
  cert_path=$cert_dir/$cert.x509.pem
  if test -f $cert_path
  then 
    echo " -- $cert_path" >&2
    md5=$(openssl x509 -in $cert_path -outform DER | md5sum | cut -d' ' -f1)
    CER_TARGET_MD5S[$i]=$md5
  fi
  i=$((i+1))
done

if [[ $i -gt 0 ]]
then
  print_md5s targetCertsMd5_rel ${CER_TARGET_MD5S[@]}
else
  echo "*** Failed to calculate ..." >&2
fi
