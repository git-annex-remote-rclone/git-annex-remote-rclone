# git-annex rclone special remote

__Users are urged to upgrade to version 0.4 or higher immediately.
Some ways of using earlier versions could result in data loss. [more information here](https://github.com/DanielDent/git-annex-remote-rclone/issues/8)__


[![Tests](https://github.com/DanielDent/git-annex-remote-rclone/actions/workflows/test.yml/badge.svg)](https://github.com/DanielDent/git-annex-remote-rclone/actions/workflows/test.yml)
[![Shellcheck](https://github.com/DanielDent/git-annex-remote-rclone/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/DanielDent/git-annex-remote-rclone/actions/workflows/shellcheck.yml)

This wrapper around [rclone](http://rclone.org/) makes any destination supported by rclone usable with git-annex.

Cloud storage providers supported by rclone currently include:
   * Google Drive
   * Amazon S3
   * Openstack Swift / Rackspace cloud files / Memset Memstore
   * Dropbox
   * Google Cloud Storage
   * ~~Amazon Cloud Drive~~ ([issue #22](https://github.com/DanielDent/git-annex-remote-rclone/issues/22))
   * Microsoft One Drive
   * Hubic
   * Backblaze B2
   * Yandex Disk

## Installation

   1. [Install git-annex](https://git-annex.branchable.com/install/)
   2. [Install rclone](http://rclone.org/install/) into your $PATH, e.g. `/usr/local/bin`
   3. Copy `git-annex-remote-rclone` into your $PATH

## Requirements

The current version of git-annex-remote-rclone has been tested with rclone versions up to 1.37. Because rclone sometimes changes its output, updates to this software may be required for compatibility.

Version 1.34 of rclone includes performance improvements and for that reason is now the minimum recommended version. 

To simplify maintenance, when I make updates to git-annex-remote-rclone, I test only against the current stable
version of rclone. While I am not currently explicitly dropping support for older versions, I am also not
performing additional integration tests with older rclone versions.

A periodic continuous integration process downloads the latest stable releases
of `rclone` and `git-annex` and runs `git-annex testremote` to verify compatibility.
The build badge above is linked to this CI process.

## Usage

1. Configure rclone remote: `rclone config`. 
2. If your `rclone` configuration is password-protected then export the `RCLONE_CONFIG_PASS` environment variable in the shell where you will execute `git annex` command:
   
 ```
 export RCLONE_CONFIG_PASS=your_password_here
 ```
 
    or prefix `git annex` command with the environment variable:
 
 ```
 RCLONE_CONFIG_PASS=your_password_here git annex ...
 ```
 
   Pull requests proposing a more secure or easier to use approach to password-protected `rclone` configurations are welcome.
  
3. Create a git-annex repository ([walkthrough](https://git-annex.branchable.com/walkthrough/))
4. Choose a repository layout. If you are having difficulty choosing, the `lower` layout is recommended. Supported layouts:
    * `lower` - A two-level lower case directory hierarchy is used (using git-annex's DIRHASH-LOWER MD5-based format). This choice requires git-annex 6.20160511 or later.
    * `directory` - A two-level lower case directory hierarchy is used, along with the key name as a 3rd level nested directory. This choice requires git-annex 6.20160511 or later.
       * Some cloud providers require traversing a tree to request a file. The additional nested directory may cause a small performance loss for remote operations.
       * Known compatible remotes: [directory](http://git-annex.branchable.com/special_remotes/directory/), [rsync](http://git-annex.branchable.com/special_remotes/rsync/)
    * `nodir` - No directory hierarchy is used.
       * On systems which are designed to efficiently deal with many objects in a single "directory" or "path", this is the simplest and most efficient layout.
       * Known compatible remotes:  Thomas Jost's [Hubic](https://github.com/Schnouki/git-annex-remote-hubic) remote when a swift container other than `default` is used.
    * `mixed` - A two-level mixed case directory hierarchy is used (using git-annex's DIRHASH format).
       * This layout may cause problems when used on filesystems and cloud storage providers that are case-insensitive.
       * Known compatible remotes: Thomas Jost's [Hubic](https://github.com/Schnouki/git-annex-remote-hubic) remote when the `default` swift container is chosen.
    * `frankencase` - A two-level lower case directory hierarchy is used (using git-annex's DIRHASH format, with all characters translated to lower case)
       * This layout should not be used except if you already have a legacy remote using this layout and do not wish to migrate.
       * This was the only available layout in early versions of this remote, up to release v0.1.
5. Add a remote for the provider. This example:

   * Adds a git-annex remote called `myacdremote`
   * Stores your files in an rclone remote configured with the name `acd`
   * Uses a `lower` repository layout
   * Stores your files in a folder/prefix called `git-annex`:

```
git annex initremote myacdremote type=external externaltype=rclone target=acd prefix=git-annex chunk=50MiB encryption=shared mac=HMACSHA512 rclone_layout=lower
```

The initremote command calls out to GPG and can hang if a machine has insufficient entropy. To debug issues, use the `--debug` flag, i.e. `git-annex initremote --debug`.

## Choosing a Chunk Size

Choose your chunk size based on your needs. By using a chunk size below the maximum file size supported by
your cloud storage provider for uploads and downloads, you won't need to worry about running into issues with file size.
Smaller chunk sizes: leak less information about the size of file size of files in your repository, require less ram,
and require less data to be re-transmitted when network connectivity is interrupted. Larger chunks require less round
trips to and from your cloud provider and may be faster. Additional discussion about chunk size can be found
[here](https://git-annex.branchable.com/chunking/) and [here](https://github.com/DanielDent/git-annex-remote-rclone/issues/1)

## Upgrading From 0.1 and Earlier

git-annex-remote-rclone now requires specifying a rclone_layout= setting. Earlier versions used the `frankencase` layout,
which is no longer recommended.

A migration script is included which will convert your data from the `frankencase` layout to the `lower` layout.

Avoid using the remote during migration. The migration script is idempotent. It is safe to re-run it if migration is
interrupted or if some move operations do not complete successfully. When running the script no longer generates any
'move' commands, all objects have been migrated to the new layout.

## Implementation Note

At this time, this remote does NOT store your credentials in git-annex. Users are responsible for ensuring a
~/.rclone.conf file with valid credentials is available.

## Warning

Not all of the supported cloud storage providers have been tested. While in theory any provider that works with rclone
should also work with this remote, it's possible there are unforseen integration issues - issues which might even
result in data loss.

## Issues, Contributing

If you run into any problems, please check for issues on [GitHub](https://github.com/DanielDent/git-annex-remote-rclone/issues).
Please submit a pull request or create a new issue for problems or potential improvements.

## License

Copyright 2016-2022 [Daniel Dent](https://www.danieldent.com/), 2022 [git-annex-remote-rclone contributors](https://github.com/DanielDent/git-annex-remote-rclone/graphs/contributors). Licensed under the GPLv3.
