# ThreatHunting

## Installation

Before installation, unblocking the downloaded files may be required.

`Get-ChildItem *.ps* -Recurse | Unblock-File`

### Option 1: Install at the System Level
Copy the project folder to `%Windir%\System32\WindowsPowerShell\v1.0\Modules\`

### Option 2: Install at the Profile Level
Copy the project folder to `$home\Documents\WindowsPowerShell\Modules\`

### Option 3: Import Module at each Powershell Prompt
To only use the scripts during the current powershell session, use

`Import-Module .\ThreatHunting.psm1`

### Contact
CERTAnalysisMitigation@dla.mil

CERT@dla.mil

http://seclist.us/threathunting-powershell-collection-designed-to-assist-in-threat-hunting-windows-systems.html
