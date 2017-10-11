FUNCTION Hunt-ScheduledTasks {
    <#
    .Synopsis 
        Gets the scheduled tasks on a given system.

    .Description 
        Gets the scheduled tasks on a given system.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-ScheduledTasks 
        Hunt-ScheduledTasks SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-ScheduledTasks
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-ScheduledTasks

    .Notes 
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
        $Fails

    );

	BEGIN{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;

	}

    PROCESS{

        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present

        $Tasks = $null;
                        
		$Tasks = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-ScheduledTask | Select-Object *} -ErrorAction SilentlyContinue;
            
        if ($Tasks) {

            $Tasks |
                ForEach-Object {
                    
                    $_ | Add-Member -MemberType NoteProperty -Name Computer -Value $Computer;
                    $_ | Add-Member -MemberType NoteProperty -Name DateScanned -Value (Get-Date -Format u);

                    $_ | Add-Member -MemberType NoteProperty -Name ActionsId -Value ($_.Actions.Id -join "; ");
                    $_ | Add-Member -MemberType NoteProperty -Name ActionsArguments -Value ($_.Actions.Arguments -join "; ");
                    $_ | Add-Member -MemberType NoteProperty -Name ActionsExecute -Value ($_.Actions.Execute -join "; ");
                    $_ | Add-Member -MemberType NoteProperty -Name ActionsWorkingDirectory -Value ($_.Actions.WorkingDirectory -join "; ");

                    $_ | Add-Member -MemberType NoteProperty -Name TriggersEnabled -Value ($_.Triggers.Enabled -join "; ");
                    $_ | Add-Member -MemberType NoteProperty -Name TriggersEndBoundary -Value ($_.Triggers.EndBoundary -join "; ");
                    $_ | Add-Member -MemberType NoteProperty -Name TriggersExecutionTimeLimit -Value ($_.Triggers.ExecutionTimeLimit -join "; ");
                    $_ | Add-Member -MemberType NoteProperty -Name TriggersRepetition -Value ($_.Triggers.Repetition -join "; ");
                    $_ | Add-Member -MemberType NoteProperty -Name TriggersStartBoundary -Value ($_.Triggers.StartBoundary -join "; ");
                    $_ | Add-Member -MemberType NoteProperty -Name TriggersDelay -Value ($_.Triggers.Delay -join "; ");
                    $_ | Add-Member -MemberType NoteProperty -Name TriggersPSComputerName -Value ($_.Triggers.PSComputerName -join "; ");

                    return $_;
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
