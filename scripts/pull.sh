#!/bin/bash
#
# ./scripts/pull.sh
#
# bill@f5.com
#
# Pulls an ILX workspace from a BIG-IP and syncs to ./workspace, excludes 
# ./workspace/extensions/webcifs/node_modules.
#
source ./scripts/env.sh
source ./scripts/util.sh

# get version of package from package.json
PACKAGE_VERSION=$(jq -r ".version" workspace/extensions/webcifs/package.json 2>&1)
# creates new workspace name with version 
webcifs_workspace_name=$webcifs_workspace_name-$PACKAGE_VERSION

echo "Pull ${fgLtCya}$webcifs_workspace_name${fgLtWhi} from ${fgLtCya}$webcifs_ilxhost${fgLtWhi}"

# check to see if the workspace actually exists before attempting to copy over
echoNotice "Checking for existing workspace ${fgLtCya}$webcifs_workspace_name${fgLtWhi}"
runCommand "ssh -o ClearAllForwardings=yes $webcifs_ilxhost tmsh list ilx workspace $webcifs_workspace_name one-line 2>&1"

echoNotice "Pulling ${fgLtCya}$webcifs_workspace_name${fgLtWhi} from ${fgLtCya}$webcifs_ilxhost${fgLtWhi}"
runCommand "rsync -e 'ssh -o ClearAllForwardings=yes -ax' -avq --include=\"extensions/webcifs/node_modules/f5-*\" --exclude=\".DS_Store\" --exclude=\"extensions/webcifs/node_modules/*\" $webcifs_ilxhost:/var/ilx/workspaces/Common/$webcifs_workspace_name/. workspace/. 2>&1"

echo -e "\n👍 Pull complete 👍\n"

exit 0
