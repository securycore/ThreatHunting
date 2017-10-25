function Hunt-Autoruns {
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
        Hunt-Autoruns 
        Hunt-Autoruns SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-Autoruns
        Hunt-Autoruns -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-Autoruns

    .Notes
        Updated: 2017-10-24

        Contributing Authors:
            Jeremy Arnold
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

        class Autorun
        {
            [Datetime] $DateScanned
            [string] $Computer
            [String] $User
            [string] $Caption
            [string] $Command
            [String] $Location
                        
        };

    };

    process{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
        
        Write-Verbose ("{0}: Querying remote system" -f $Computer); 
        $autoruns = $null;
        $autoruns = Invoke-Command -Computer $Computer -ErrorAction SilentlyContinue -ScriptBlock {
            Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue;
        };
       
        if ($autoruns) { 
            
            $outputArray = @();

            foreach ($autorun in $autoruns) {
             
                $output = $null;
                $output = [Autorun]::new();
                
                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;
                
                $output.User = $autorun.User;
                $output.Caption = $autorun.Caption;
                $output.Command = $autorun.Command;
                $output.Location = $autorun.Location;

                $outputArray += $output;
            
            };

            $total++;
            return $OutputArray;
        
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer);
            if ($Fails) {
                
                $total++;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [Autorun]::new();

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