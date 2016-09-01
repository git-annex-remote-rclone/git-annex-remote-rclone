/*
 * A wrapper EXE for git-annex-remote-rclone that runs a Bash script under Bash.
 * 
 * Rename to "git-annex-remote-rclone.exe" and place on your PATH, next to git-annex-remote-rclone itself.
 * 
 * Be sure you have 32-bit Git Bash installed (which the Git Annex Windows installer provides).
 */
using System;
using System.Diagnostics;

namespace GitAnnexRemoteRcloneWrapper
{
	class Program
	{
		public static int Main(string[] args)
		{
			// Instead of screwing about with escaping, we'll just patch up Environment.CommandLine
			// and run that. Windows internally doesn't separate command-line arguments out.
			string fixed_args = Environment.CommandLine.Replace(System.AppDomain.CurrentDomain.FriendlyName, "git-annex-remote-rclone");
			
			var psi = new ProcessStartInfo
	        {
				// TODO: what if git-bash isn't on C?
	            FileName = @"C:\Program Files (x86)\Git\bin\bash.exe",
	            Arguments = fixed_args,
	            // Keep it in our console/using our STDIN/STDOUT
	            UseShellExecute = false
	        };
			
			// Start the child, passing it the script and the args for the script.
			Process proc = Process.Start(psi);
			
			// Wait for it to stop and return its return code
			proc.WaitForExit();
			return proc.ExitCode;
		}
	}
}