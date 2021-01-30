#!/bin/bash
if [ $# -ne 4 ]
then
  echo "Please invoke this script with four arguments."
  echo "create-pipelines <sonarUrlName> <gitOnlinePathRepositoryProject> <user> <password>"
  exit -1
fi
PROJECTREPOSITORYPATH=$2
SONAR_DOMAIN=$1


RESULT = $(curl --include --request GET --header "Content-Type: application/x-www-form-urlencoded" -u  $3:$4 "http://$SONAR_DOMAIN/api/authentication")

echo $RESULT

curl --include \
     --request POST \
     --header "Content-Type: application/x-www-form-urlencoded" \
     -u  $3:$4 \
     -d "project=$PROJECTREPOSITORYPATH&organization=devossteam&name=myproject" \
"http://$SONAR_DOMAIN/api/projects/create"
