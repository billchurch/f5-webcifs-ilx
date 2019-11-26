# Workspace build instructions
## BIG-IP Workspace Build
My current method of building the workspace for the BIG-IP involves copying ./workspace to an empty BIG-IP ILX workspace, installing modules `npm i --production`on the BIG-IP. Validating the changes with the virtual servers (APM, RADIUS Proxy, LDAP Proxy, LDAPS Proxy, and finally copying exporting the workspace back to the repo.

For this, I use a set of scripts under ./scripts.

## Overview and order of operations
The order you should do this in is:
1. Modify `env.sh` to match your environment
2. Run `push.sh` to push ./workspace to a remote BIG-IP for testing and validation
3. The new workspace on the BIG-IP should automatcially be associated to the ephemeral_aiuth plugin. Test and validate.
4. Run `pull.sh` to pull the workspace back from the BIG-IP for consistency (shouldn't really be any changes) you can also skip to step 6 as `build.sh` runs this for you
5. Run `build.sh` to package everything up and generate a sha256
 
## Script details
All scripts should be run from the root of the repo. Example:
  ```
  ./scripts/push.sh
  ```

### env.sh
Contains variables referenced by the other scripts to setup the environment. This should be modified to match your build environment, specifically the BIG-IP and workspace you wish to push/pull against. Commands are over ssh and assumes ssh-rsa key auth (otherwise you’ll be prompted constantly for your ssh password). I might move this to REST at some point, but this was easiest at the time.
Variable descriptions:
* **ilxhost** - _user@ip/hostname_ of BIG-IP to push or pull code from
* **workspace_name** – desired name of the workspace on the BIG-IP
* **package_name** – desired name of the package (workspace archive)
* **pua_location** – where to place the exported workspace binary from the BIG-IP

### push.sh
Pushes code from ./workspace to the BIG-IP, if $workspace_name does not exist, it is created. This does not associate the workspace to a plugin or a VIP.

### pull.sh
Pulls code from the BIG-IP to ./workspace, excludes ./workspace/extensions/ephemeral_auth/node_modules with the exception of ./workspace/extensions/ephemeral_auth/node_modules/f5-nodejs
 
### build.sh
This requires jq (tries to install it if you’re on a Mac), which reads JSON files. This is to extract the version of the app being packaged.
1. Pulls workspace from variables defined in ./scripts/env.sh
2. Retreives version from ./workspace/extensions/ephemeral_auth/package.json 
3. Runs a “tar czf” on the BIG-IP defied in ./scripts/env.sh of the workspace (essentially an export for the workspace) to ./Build/Release
4. Copies newly built “.tgz” to $pua_location specified in ./scripts/env.sh as $package_name-current (./bin in this submodule)
5. Creates sha256 sum and places in $pua_location
6. Cleans up any .DS_Store stuff lying around

After this point, it’s ready to be integrated into f5-pua.