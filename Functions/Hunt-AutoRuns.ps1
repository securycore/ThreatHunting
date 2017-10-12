FUNCTION Hunt-AutoRuns {
    <#
    .Synopsis 
        Gets a list of programs that auto start for the given computer(s).

    .Description 
        Gets a list of programs that auto start for the given computer(s).

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-AutoRuns 
        Hunt-AutoRuns SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-AutoRuns
        Hunt-AutoRuns -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-AutoRuns

    .Notes
        Updated: 2017-10-12

        Contributing Authors:
            Jeremy Arnold
            
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

        class AutoRuns
        {
            [Datetime] $DateScanned
            [string] $Computer
            [String] $User
            [string] $Caption
            [string] $Command
            [String] $RegistryLocation
                        
        };

    };

    PROCESS{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
        $OutputArray = @();
        $autoRun = $null;
        Write-Verbose "Getting a list of AutoRuns..."
        $autoRun = Invoke-Command -Computer $Computer -ScriptBlock {Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue};
       
        if ($autoRun) { 
            foreach ($entry in $autoRun) {
             
                $output = $null;
                $output = [AutoRuns]::new();
                
                $output.DateScanned = Get-Date -Format u;
                $output.Computer = $Computer;
                $output.User = $entry.user;
                $output.caption = $entry.caption;
                $output.command = $entry.command;
                $output.RegistryLocation = $entry.location;

                $OutputArray += $output;
            
            };

            Return $OutputArray;
        
        }
        else {
            
            Write-Verbose "System unreachable.";
            if ($Fails) {
                
                Write-Verbose "-Fails switch activated. Saving system to $Fails.";
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                Write-Verbose "Writing failed Computer and DateScanned.";        
                $output = $null;
                $output = [AutoRuns]::new();

                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;

                return $output;
            };
        };
        
        $elapsed = $stopwatch.Elapsed;
        $total = $total + 1;
        
        Write-Verbose "System $total `t $ThisComputer `t Total Time Elapsed: $elapsed";

    };

    END {

        $elapsed = $stopwatch.Elapsed;

        Write-Verbose "Total Systems: $total `t Total time elapsed: $elapsed";
    };
};