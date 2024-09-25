# Patch update process for Resurgence Legacy
Any pushes to this repo will automatically update the launcher.  The launcher will read from the contents of Github Pages, and any changes to patchd2-lod will automatically trigger a Github actions workflow which rebuilds any manifest.json and index.html files required.  This build process takes a few minutes to complete.

If someone has the launcher open they can click the settings button, then click done to have it check for updates.

# Launcher patching logic overview
The launcher is targeted as a base URL: https://d2resurgence.github.io/patch-d2lod/files/

There are 1.13c files that are used to get an installation intitially patched, otherwise all resurgence specific files are in the resurgence-patches folder.

* current - All files from the current folders are synced for all users  
* hd_* - Only the contents of the selected HD version will sync
* maphack_* - Only the contents of the selected maphack version will sync

Each subfolder has a manifest.json file which contains a hash of each file to check if the client copy matches the server copy and trigger a sync if mismatched.  Ignore_crc and special file exceptions apply.

# bh.cfg and bh_settings.cfg overrides
These two files are specially designated in the launcher code to have their crcs ignored dynamically based on a "Prevent Maphack Override" toggle switch in the launcher settings.  If this is toggled on, it's similar to flagging these files with ignore_crc permanently in the builder script.  These are not set with ignore_crc right now because pushing updates to bh configs is expected in the future.

# ignore_crc functionaility
This is an option set within the manifest.json which will cause a file to be downloaded one time, but the launcher will not copy over the top.  This is used for config files that don't require any expected updates from the launcher.  This is good for things like SGD2FreeRes and D2GL settings files that a user might customize.  The list of these files are coded into the python builder script: patch-d2lod/files/builder/generate_manifest_and_html_files.py.

# General patching notes

Github will convert all files to LF line endings, so if you edit a file on windows and generate the manifest it will end up having a diffferent crc once it hits github.  Edit files in LF before pushing to github, although with the new approach using github actions to create manifests this might be a non-issue.
