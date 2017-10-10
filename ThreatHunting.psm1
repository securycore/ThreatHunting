# Make scripts available for use.

Get-ChildItem -Path $PSScriptRoot\Functions -Filter *.ps1 | 
ForEach-Object -Process { . $PSItem.FullName };