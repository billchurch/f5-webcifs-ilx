#!/bin/bash
## Syncs from BIG-IP and builds a release based on version in extensions/webcifs/package.json
#
source ./scripts/env.sh
source ./scripts/util.sh

./scripts/pull.sh
if [ $? -ne 0 ]; then
  # failure
  tput bel;tput bel;tput bel;tput bel
  echo -e "\n${fgLtRed}Pull command failed. Giving up.${fgLtWhi}\n"
  echo ${output}
  exit 255
fi

# get version of package from package.json
PACKAGE_VERSION=$(jq -r ".version" workspace/extensions/webcifs/package.json 2>&1)
# creates new workspace name with version 
webcifs_workspace_name=$webcifs_workspace_name-$PACKAGE_VERSION

echoNotice "Creating workspace package" 
runCommand "ssh -o ClearAllForwardings=yes $webcifs_ilxhost /bin/tar --exclude='./extensions/webcifs/config.json' -czf - -C /var/ilx/workspaces/Common/$webcifs_workspace_name . > Build/Release/BIG-IP-ILX-webcifs-v$PACKAGE_VERSION.tgz"

echoNotice "Creating SHA256 hash" 
runCommand "shasum -a 256 Build/Release/BIG-IP-ILX-webcifs-v$PACKAGE_VERSION.tgz > Build/Release/BIG-IP-ILX-webcifs-v$PACKAGE_VERSION.tgz.sha256"

echoNotice "Copying to current"
runCommand "cp Build/Release/BIG-IP-ILX-webcifs-v$PACKAGE_VERSION.tgz $webcifs_pua_location/$webcifs_package_name-current.tgz && \
            cp Build/Release/BIG-IP-ILX-webcifs-v$PACKAGE_VERSION.tgz.sha256 $webcifs_pua_location/$webcifs_package_name-current.tgz.sha256"

echoNotice "Deleting any '.DS_Store' files"
runCommand "find . -name '.DS_Store' -type f -delete"

echo -e "\nWorkspace packages located at:\n"
echo "  Build/Release/BIG-IP-ILX-webcifs-v$PACKAGE_VERSION.tgz"
echo "  Build/Release/BIG-IP-ILX-webcifs-v$PACKAGE_VERSION.tgz.sha256"
echo "  $webcifs_pua_location/$webcifs_package_name-current.tgz"
echo "  $webcifs_pua_location/$webcifs_package_name-current.tgz.sha256"

echo -e "\n👍 Build Complete 👍\n"

exit 0
