# Resurgence patching

Github will convert all files to LF line endings, so if you edit a file on windows and generate the manifest it will end up having a diffferent crc once it hits github.  Edit files in LF before generating manifests.
