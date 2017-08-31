Function Get-WinEventXMLData {
    <#
    .SYNOPSIS
        Get AppLocker custom event data from an event log record
    
    .DESCRIPTION
        Get custom event data from an event log record (currently only supports AppLocker)
        Takes in Event Log entries from Get-WinEvent, converts each to XML, extracts all properties and adds them to the event object.
        Notes:
            Some events store custom data in other XML nodes.
            For example, AppLocker uses Event.UserData.RuleAndFileData
            Others use Event.EventData.Data
    
    .PARAMETER Event
        One or more event.
        Accepts data from Get-WinEvent or any System.Diagnostics.Eventing.Reader.EventLogRecord object
    
    .INPUTS
        System.Diagnostics.Eventing.Reader.EventLogRecord
    
    .OUTPUTS
        System.Diagnostics.Eventing.Reader.EventLogRecord
    
    .EXAMPLE
        Get-WinEvent -FilterhashTable @{LogName="Microsoft-Windows-AppLocker/EXE and DLL"; ID="8002","8003","8004"} -MaxEvents 10 | Get-WinEventData | Select-Object *

    .NOTES
        Updated: 2017-08-31
        LEGAL: Copyright (C) 2017  Anthony Phipps
        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
    
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    .FUNCTIONALITY
        Computers
    #>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false,
                   Position=0 )]
        [System.Diagnostics.Eventing.Reader.EventLogRecord[]]
        $Event
    )

    Process
    {
        #Loop through provided events
        Foreach-Object {

            $output = $_;
                    
            $EventXML = [xml]$_.ToXml();

            # Add custom fields from XML
            
            # If event is a recognizable AppLocker event
            if ($EventXML.Event.UserData.RuleAndFileData) {
                $EventXMLFields = $EventXML.Event.UserData.RuleAndFileData | Get-Member | Where-Object {$_.Membertype -eq "Property"} |  Select-Object Name;

                $EventXMLFields | ForEach-Object {
                    $output | Add-Member –MemberType NoteProperty –Name $_.Name -Value $EventXML.Event.UserData.RuleAndFileData.($_.Name);
                };
            };

            Return $output;
        };
    };
};
