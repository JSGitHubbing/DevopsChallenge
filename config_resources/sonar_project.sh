#!/bin/bash
if [ $# -ne 5 ]
then
  echo "Please invoke this script with three arguments."
  echo "create-pipelines <sonarUrl> <key> <name> <user> <password>"
  exit -1
fi

function jsonval {
    temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop`
    echo ${temp##*|}
}
curl -u $4:$5 -X POST 'http://'$1'/api/projects/create?key='$2'&name='$3
json=`curl -u admin:admin -X POST 'http://'$1'/api/user_tokens/generate?name='$3'Token'`
echo $json
prop='token'
myToken=`jsonval`
echo 'Generated token: '$myToken