# UnattendedUPG

To "compile" - run the Build.bat after cloning the repo. This will first take the smtp details from the SMTP.ini file and insert them into the RB_Upgrade.bat for the email alerts. It will then compile all the needed scripts into a single SetSchedUpgrade.exe

Usage - add the RemoteUpgrade file you are using for the upgrade to the Software folder. Place any class or sql files in the Custom folder for them to be run after the upgrade, driver files in the Drivers folder, and anything you want in the Squirrel\Program folder can go in the Program folder.

Copy the Software folder and SetSchedUpgrade.exe to the target machine, run SetSchedUpgrade.exe, and follow the prompts to schedule the upgrade for a specific date/time. The upgrade will run at the scheduled time then reboot the PC automatically once complete. 

NOTE: the upgrade runs under the SYSTEM user, so everything happens in the background and cannot be viewed. To get around this, the script logs all of its output to a RB_Upgrade.log which can be viewed if the upgrade gets stuck somewhere. It also creates a symlink to the Squirrel Setup log as SquirrelSetup.log.
