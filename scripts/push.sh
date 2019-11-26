#!/bin/bash
#
# ./scripts/push.sh
#
# bill@f5.com
#
# Pushes ./workspace to a BIG-IP ILX workspace
#
source ./scripts/env.sh
source ./scripts/util.sh

# get version of package from package.json
PACKAGE_VERSION=$(jq -r ".version" workspace/extensions/webcifs/package.json 2>&1)
# creates new workspace name with version 
webcifs_workspace_name=$webcifs_workspace_name-$PACKAGE_VERSION

echo "Push ${fgLtCya}$webcifs_workspace_name${fgLtWhi} to ${fgLtCya}$webcifs_ilxhost${fgLtWhi}"

echoNotice "Checking $webcifs_ilxhost for workspace $webcifs_workspace_name"
output=$(ssh  -o ClearAllForwardings=yes $webcifs_ilxhost tmsh list ilx workspace $webcifs_workspace_name one-line 2>&1)
result="$?" 2>&1
if [ $result -ne 0 ]; then
  echo "❌"
  echoNotice "Attempting to create workspace"
  runCommand "ssh -o ClearAllForwardings=yes $webcifs_ilxhost \"tmsh create ilx workspace $webcifs_workspace_name node-version 6.9.1\" 2>&1"
else
  echo "✅"
fi

echoNotice "Pushing ./workspace to $webcifs_workspace_name at $webcifs_ilxhost"
runCommand "rsync -e 'ssh -o ClearAllForwardings=yes -ax' -avq --delete --exclude='.DS_Store' workspace/ $webcifs_ilxhost:/var/ilx/workspaces/Common/$webcifs_workspace_name/."

echoNotice "Installing node modules at $webcifs_workspace_name on $webcifs_ilxhost"
runCommand "ssh -o ClearAllForwardings=yes $webcifs_ilxhost \"cd /var/ilx/workspaces/Common/$webcifs_workspace_name/extensions/webcifs; npm i --production\" 2>&1"

echoNotice "Setting permissions at $webcifs_workspace_name on $webcifs_ilxhost"
runCommand "ssh -o ClearAllForwardings=yes $webcifs_ilxhost \"chown -R root.sdm /var/ilx/workspaces/Common/$webcifs_workspace_name/; \
  chmod -R ug+rwX,o-w /var/ilx/workspaces/Common/$webcifs_workspace_name/; \
  chmod u+rw,go-w /var/ilx/workspaces/Common/$webcifs_workspace_name/version; \
  chmod u+rw,go-w /var/ilx/workspaces/Common/$webcifs_workspace_name/node_version\" 2>&1"

echoNotice "Deleting $webcifs_workspace_name/node_modules/.bin on $webcifs_ilxhost"
runCommand "ssh -o ClearAllForwardings=yes $webcifs_ilxhost \"cd /var/ilx/workspaces/Common/$webcifs_workspace_name/extensions/webcifs; rm -rf node_modules/.bin\" 2>&1"

# switch plugin to new workspace
echoNotice "Checking to see if plugin exists"
output=$(ssh -o ClearAllForwardings=yes $webcifs_ilxhost tmsh list ilx plugin webcifs_plugin one-line 2>&1)
result="$?" 2>&1
if [ $result -ne 0 ]; then
  echo "❌"
  echoNotice "Attempting to create plugin"
  runCommand "ssh -o ClearAllForwardings=yes $webcifs_ilxhost tmsh create ilx plugin webcifs_plugin from-workspace $webcifs_workspace_name  extensions { webcifs { concurrency-mode single ilx-logging enabled } } 2>&1"
else
  echo "✅"
  echoNotice "Switching plugin to $webcifs_workspace_name"
  runCommand "ssh -o ClearAllForwardings=yes $webcifs_ilxhost tmsh modify ilx plugin webcifs_plugin from-workspace $webcifs_workspace_name 2>&1"
fi

echo -e "\n👍 Push complete 👍\n"

exit 0
