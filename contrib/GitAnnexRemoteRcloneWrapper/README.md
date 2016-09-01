#git-annex-remote-rclone wrapper

This project provides a Windows executable, `git-annex-remote-rclone.exe`, which allows `git-annex-remote-rclone` to be loaded by `git annex` on Windows. It accomplishes this by simply executing Git Bash's `bash`, which it assumes is available as `C:\Program Files (x86)\Git\bin\bash.exe`, to run the `git-annex-remote-rclone` shell script.

##Compiling

Open the .sln file with SharpDevelop and hit Build -> Build Solution. The executable will end up in `contrib\GitAnnexRemoteRcloneWrapper\GitAnnexRemoteRcloneWrapper\bin\Debug\git-annex-remote-rclone.exe`.

##Installation

Place the executable on your Windows PATH, and **place `git-annex-remote-rclone` itself in the same directory**.

##Usage

You should be able to type `git-annex-remote-rclone` into a `cmd.exe` prompt and get the interactive `VERSION 1` message from the Bash script.

After that, just use `git annex` with the rclone remote, as normal.
