# Slashdiablo patcher

## Updating the patch files

Change the files you need to for the new patch.

### Regenerating the manifest file

Making the patch downloadable requires the manifest to be updated. It will
update the patch for the changes files.

| Argument | Example                                           | Description                                             |
| -------- | ------------------------------------------------- | ------------------------------------------------------- |
| `-dir`   | `-dir /path/to/slashdiablo-patches/maphack_1.9.9` | Directory to generate the manifest for.                 |
| -ic      | `-ic file.cfg,another.txt`                        | Files that should have the flag ignore_crc set to true. |
| `-d`     | `-d dep_fix.bat`                                  | Files that should be flagged as deprecated.             |

#### Simple example.

```bash
$ ./bin/darwin -dir /path/to/slashdiablo-patches/maphack
```

#### Ignoring CRC and deprecating files.

```bash
$ ./bin/darwin -dir /path/to/slashdiablo-patches/maphack_1.9.9 -ic BH_settings.cfg -d BH_settings.cfg
```
