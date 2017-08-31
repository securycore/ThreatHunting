FUNCTION Get-AppLockerEvents {
    <#
    .Synopsis 
        Gets AppLocker Events 8002, 8003, and 8004 from a given system.

    .Description 
        Gets AppLocker Events 8002, 8003, and 8004 from a given system.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Parameter WEC
        Identify the destination host is a Windows Event Collector. This changes where to pull events from (ForwardedEvents).

    .Example 
        Get-AppLockerEvents
        Get-AppLockerEvents SomeHostName.domain.com
        Get-AppLockerEvents | Get-WinEventXMLData
        Get-Content C:\hosts.csv | Get-AppLockerEvents
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-AppLockerEvents

    .Notes
        To extract XML data, use another script like Get-WinEventXMLData
            https://github.com/TonyPhipps/CM-TH/blob/master/Get-WinEventXMLData.ps1
     
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
    #>

    PARAM(
    	    [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
            $Computer = $env:COMPUTERNAME,
            [Parameter()]
            [Switch]
            $WEC,
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
            
        if ($WEC){
            $Events = Get-WinEvent -ComputerName $Computer -FilterHashTable @{LogName="ForwardedEvents"; ID="8002","8003","8004"};
        }
        else {
            $Events = Get-WinEvent -ComputerName $Computer -FilterHashTable @{LogName="Microsoft-Windows-AppLocker/EXE and DLL"; ID="8002","8003","8004"};
        };

        if ($Events) {


            $Events |
                Foreach-Object {

                    $output = $_;
                    $output | Add-Member –MemberType NoteProperty –Name Computer -Value $Computer;
                    $output | Add-Member –MemberType NoteProperty –Name DateScanned -Value (Get-Date -Format u);

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
                $output | Add-Member –MemberType NoteProperty –Name Computer -Value $Computer;
                $output | Add-Member –MemberType NoteProperty –Name DateScanned -Value (Get-Date -Format u);

                return $output;
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


