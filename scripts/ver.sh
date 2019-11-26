#!/bin/bash
## displays and optionally changes version of product

source ./scripts/env.sh

source ./scripts/util.sh

echo
# get current version of workspace, ask to change or rebuild
webcifs_ilx_ver=$(jq -r ".version" ./workspace/extensions/webcifs/package.json 2>&1)
if [[ $? -ne 0 ]]; then exit; echo "error reading ILX irule version";fi

echo "Current version of $webcifs_workspace_name is: $webcifs_ilx_ver"

echo -n "If you want to change this version, enter it now otherwise press enter to retain: "

read newver

echo
echo "Updating version to: $newver"

if [[ ("$newver" != "") ]]; then
  export newver
  jq --arg newver "$newver" '.version = $newver' < ./workspace/extensions/webcifs/package.json > ./workspace/extensions/webcifs/package.json.new 
  if [[ $? -ne 0 ]]; then exit; echo "error changing version - ilx";fi
  mv ./workspace/extensions/webcifs/package.json.new ./workspace/extensions/webcifs/package.json
fi 
