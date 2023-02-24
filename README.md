# snapsync

The **snapsync** system is a backup system that creates hourly snapshots (backups) of a given directory using hard links to files in snapshots created earlier to save storage. New or modified files are included in the snapshot and removed files are deleted from the snapshot.

A cleanup script is included to preserve snapshots via a retention scheme. By default this scheme keeps the following snapshots:

1. the oldest one
1. the first backup in a month
1. the first backup on every Friday [`SNAPSYNC_DOW`] of the last 52 [`SNAPSYNC_MAXWEEK`] weeks
1. Every first backup of the last 31 [`SNAPSYNC_MAXDAY`] days
1. Every backup in the last 24 [`SNAPSYNC_MAXHOUR`] hours

Using the environment variables given inside the square brackets in the rules above you can modify this scheme.

All files in the snapshots are added to a local database enabling users to find their files ([Locate](#locate))

## Usage

1. create a `snapsync` directory for all snapshots, e.g. `/snapsync`
1. create a specific directory inside `snapsync` for each snapsynced directory, e.g. `/snapsync/home`
1. add the following lines to the crontab jobs of the `root` for each directory (in this example `/home`):

   ```bash
   15 * * * * snapsync.sh /home /snapsync/home >> /snapsync/home/snapsync.log
   45 * * * * cleanup.sh /snapsync/home >> /snapsync/home/snapsync.log
   ```

For the exact usage of the script run the scripts `snapsync.sh` and `cleanup.sh` with arguments to get more information.

Runtime errors are added to `error.log` inside the snapsync directory.

A sample `logrotate` script (`logrotate_snapsync`) is included which can be saved in `/etc/logrotate.d/snapsync`.

## Locate

After each modification to the snapsync system the `locate` database (`mlocate.db` is updated. This allows users to find their files and/or directory using the following command:

```bash
locate --database=/snapsync/home/mlocate.db -b <filename>
```

## Dependencies

* standard Linux or macOS environment. This system has not been tested with Windows.
* `bash`
* `rsync`
* `updatedb` (part of `locate`)

## License and Copyright

```raw
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.
```

Please read the `LICENSE` file for more information.
