#!/bin/bash
if [ $# -ne 3 ]
then
  echo "Please invoke this script with three arguments."
  echo "create-pipelines <jenkinsUrl> <user> <password>"
  exit -1
fi

JENKINS_URL=$1
REQUEST="https://$JENKINS_URL"
ENDING='/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)'
CRUMB=$(curl -s "$REQUEST$ENDING" -u $2:$3)
echo $CRUMB
curl -s -XPOST "https://$JENKINS_URL/createItem?name=MTS" -u  $2:$3 --data-binary @./folder.xml -H $CRUMB -H "Content-Type:text/xml"