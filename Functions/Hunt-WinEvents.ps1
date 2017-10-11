FUNCTION Hunt-WinEvents {
    <#
    .Synopsis 
        Gets Windows events from one or more systems.

    .Description 
        Gets Windows events from one or more systems.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-WinEvents -FilterHashTable @{LogName="Microsoft-Windows-AppLocker/EXE and DLL"; ID="8002","8003","8004"}
        Hunt-WinEvents -FilterHashTable @{LogName="Windows PowerShell"; StartTime=(Get-Date).AddDays(-8); EndTime=(Get-Date)} 
        Hunt-WinEvents SomeHostName.domain.com
        Get-Content C:\hosts.txt | Hunt-WinEvents
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-WinEvents

    .Example
        Pull AppLocker Events from a Windows Event Collector:
        Hunt-WinEvents -FilterHashTable @{LogName="ForwardedEvents"; ID="8002","8003","8004"}

    .Notes
        To extract XML data, use another script like Get-WinEventXMLData
            https://github.com/DLACERT/ThreatHunting/blob/master/Add-WinEventXMLData.ps1
     
        Updated: 2017-10-10

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2017
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
    #>

    [CmdletBinding()]
    PARAM(
    	    [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
            $Computer = $env:COMPUTERNAME,
            [Parameter()]
            [array]
            $FilterHashTable = @{LogName="Windows PowerShell"; StartTime=(Get-Date).AddDays(-8);},
            [Parameter()]
            $Fails
        );

	BEGIN{

            $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
            Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

            $stopwatch = New-Object System.Diagnostics.Stopwatch;
            $stopwatch.Start();

            $total = 0;
	    };

    PROCESS{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present

        $Events = Get-WinEvent -ComputerName $Computer -FilterHashTable $FilterHashTable;

        if ($Events) {

            $Events |
                Foreach-Object {

                    $output = $_;
                    $output | Add-Member -MemberType NoteProperty -Name Computer -Value $Computer;
                    $output | Add-Member -MemberType NoteProperty -Name DateScanned -Value (Get-Date -Format u);

                    Return $output;
                };
        }

        else { # System was not reachable

            if ($Fails) { # -Fails switch was used
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else{ # -Fails switch not used
                            
                $output = $null;
                $output = [PSCustomObject]@{};
                $output | Add-Member -MemberType NoteProperty -Name Computer -Value $Computer;
                $output | Add-Member -MemberType NoteProperty -Name DateScanned -Value (Get-Date -Format u);

                Return $output;
            };
        };
         
        $elapsed = $stopwatch.Elapsed;
        $total = $total+1;
            
        Write-Information -MessageData "System $total `t $ThisComputer `t Time Elapsed: $elapsed" -InformationAction Continue;

    };

    END{
        $elapsed = $stopwatch.Elapsed;

        Write-Information -MessageData "Total Systems: $total `t Total time elapsed: $elapsed" -InformationAction Continue;
	};
};


