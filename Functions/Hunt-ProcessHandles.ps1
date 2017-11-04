function Hunt-ProcessHandles {
    <#
    .Synopsis 
        Gets a list of Handles loaded by all process on a given system.

    .Description 
        Gets a list of Handles loaded by all process on a given system.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-ProcessHandles 
        Hunt-ProcessHandles SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-ProcessHandles
        Hunt-ProcessHandles $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-ProcessHandles

    .Notes 
        Updated: 2017-11-4

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
        
    .LINK
        https://github.com/DLACERT/ThreatHunting
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,
        [Parameter()]
        $Fails
    );

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;

        class Handles
        {
            [String] $Computer
            [dateTime] $DateScanned

            [string] $ProcessID
            [string] $Process

        };
	};

    process{

        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present

        $handles = $null;
        $handles = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock { 
            
            $handles = 'Looking to use Sysinternals handles.exe / handles64.exe for this task' ;

            return $handles;
        
        };
            
        if ($handles) {
            
            $outputArray = @();

            Foreach ($handle in $handles) {
                
                    
                    $output = $null;
                    $output = [Handles]::new();
    
                    $output.Computer = $Computer;
                    $output.DateScanned = Get-Date -Format u;
    
                    $output.ProcessID = '';
                    $output.Process = '';
                                        
                    $outputArray += $output;

            };

            return $outputArray;

        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer);
            if ($Fails) {
                
                $total++;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [Handles]::new();

                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;
                
                $total++;
                return $output;
            };
        };
    };

    end {

        $elapsed = $stopwatch.Elapsed;

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed);
    };
};