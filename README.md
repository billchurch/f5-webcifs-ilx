# ILXWebCifs
##iRuleLX Webified CIFS Project

F5 BIG-IP iRulesLX (Unsupported) Project for Webified CIFS Shares.

Interface:
![alt tag](http://i.imgur.com/M447vvdl.png)

Directory Browsing:
![alt tag](http://i.imgur.com/isXT1Ckl.png)

Logging:
![alt tag](http://i.imgur.com/u3QnVO6l.png)

Currently supports SMB2:ReadDir, SMB2:ReadFile, SMB2:WriteFile

Modified SMB2 Library to allow additional file attriute return for SMB2::READDIR

-EndofFile: File Size on Disk (UInt64 to Hex, to Binary, to Bytes.)

-CreationDate: File Creation Date (UInt64 to Int32, to Hex, to Binary, to Java GMT.)

-QueryStrings & Form Fields can be passed for connection settings.

##TODO:
-NFS Support?

-MkDir, 

-Rename, 

-additional error handling, 

-add more intelligence to QueryString and Form Field settings,

-Addition Error handling for multi level paths. (currently supports 1 path deep and back to top options.)
