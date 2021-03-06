#!/bin/bash
if [ $# -ne 3 ]
then
  echo "Please invoke this script with three arguments."
  echo "create-pipelines <jenkinsUrl> <user> <password>"
  exit -1
fi

JENKINS_URL=$1
REQUEST="http://$JENKINS_URL"
ENDING='/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,%22:%22,//crumb)'
COOKIEJAR="$(mktemp)"
CRUMB=$(curl -u "$2:$3" --cookie-jar "$COOKIEJAR" "http://$JENKINS_URL$ENDING")
curl -XPOST "http://$JENKINS_URL/createItem?name=TheBackProject" -u  $2:$3 --data-binary @config_resources/multipipeline_back.xml -v --cookie "$COOKIEJAR" -H $CRUMB -H "Content-Type:text/xml"
curl -XPOST "http://$JENKINS_URL/createItem?name=TheFrontProject" -u  $2:$3 --data-binary @config_resources/multipipeline_front.xml -v --cookie "$COOKIEJAR" -H $CRUMB -H "Content-Type:text/xml"
