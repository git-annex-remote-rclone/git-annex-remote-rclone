# git-annex rclone special remote

This wrapper around [rclone](http://rclone.org/) makes any destination supported by rclone usable with git-annex.

Cloud storage providers supported by rclone currently include:
   * Google Drive
   * Amazon S3
   * Openstack Swift / Rackspace cloud files / Memset Memstore
   * Dropbox
   * Google Cloud Storage
   * Amazon Cloud Drive
   * Microsoft One Drive
   * Hubic
   * Backblaze B2
   * Yandex Disk

## Installation

   1. [Install git-annex](https://git-annex.branchable.com/install/)
   2. [Install rclone](http://rclone.org/install/) into your $PATH, e.g. `/usr/local/bin`
   3. Copy `git-annex-remote-rclone` into your $PATH

## Usage

   1. Configure an rclone remote: `rclone config`
   2. Create a git-annex repository ([walkthrough](https://git-annex.branchable.com/walkthrough/))
   3. Add a remote for the provider. This example:
      * Adds a git-annex remote called `myacdremote`
      * Stores your files in an rclone remote configured with the name `acd`
      * Stores your files in a folder/prefix called `git-annex`:

    git annex initremote myacdremote type=external externaltype=rclone target=acd prefix=git-annex chunk=1GiB encryption=shared mac=HMACSHA512

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

Copyright 2016 [Daniel Dent](https://www.danieldent.com/). Licensed under the GPLv3.
