# XML-Renamer
The XML-Renamer scans XML-Files for specific tags and returns a file name concatenated from those tags which is then used to rename the file. Purpose of this tool is to rename files from one naming convention to another one. The tool is written in AWK and a short shell script and can be configured using a config file.

# Installation
1. Create a working directory, it should contain two subfolders ("input" and "output")
1. Copy the files "rename.sh" and "rename_xml.awk" to the working directory

# How to use
Manual mode:
1. Put the XML file(s) you would like to rename into subfolder "input"
1. Run "rename.sh" from the shell to rename one or more files in "input"
1. Collect the results from subfolder "output"
  - If the filename starts with "ERROR_" then something went wrong
1. Subfolder "input" will be empty afterwards because rename.sh uses Unix "mv" command

Integrate with schedulers:
In case you want to work on files automatically or by a schedule, you can either:
- Invoke the script "rename.sh" in a scheduler (see system.d example below)
  - Ensure to put the files into the "input" folder
  - Kick off "rename.sh" from a scheduler (like good old cron daemon) or event-driven system
  - Evaluate the Shell Script Return Code
  - All log entries go to the configured log file
- Call the AWK-Script "rename_xml" from an application
  - Depending on the tool you can start the AWK script from a shell or by other means
  - Evaluate the AWK Script Return Code (0 for OK and 1 for Failures)
  - In case of errors evaluate the returned file name for the root cause
  
# Error codes:
- File name returned from rename_xml.awk starts with "ERROR_"
- Then the reason for the error is given:
  - NO_<Fieldname> messages indicate the XML file did not have the required tags
  - NO_SEPARATOR messages indicate that the number of separators in the input file was wrong
  - Example: ERROR_NO_CREATE_DATE
  
# Example: integration with System.d
Let's say we have a user "renamer" with the usual home directory. Every now and then (we don't know when exactly) the user stores a file in his home directory under "/home/renamer/input". 
1. 
1. 
