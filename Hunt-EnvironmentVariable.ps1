Function Hunt-EnvironmentVariable() {
    <#
    .Synopsis 
        Retreives the values of a specified environment variable from one or more systems.
    
    .Description
    	Retreives the values of a specified environment variable from one or more systems.
    
    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.
    
    .Example 
        get-content .\hosts.txt | Hunt-EnvironmentVariable $env:computername | export-csv envVars.csv -NoTypeInformation
    
     .Notes 
        Updated: 2017-09-14
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

	[cmdletbinding()]

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

        class EnvVariable {
            [String] $Computer
            [DateTime] $DateScanned
            
            [String] $Name         
            [String] $UserName
            [String] $VariableValue
        };
	};


	PROCESS{
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
        
        $AllVariables = $null;
        $AllVariables = Get-CimInstance -Class Win32_Environment -ComputerName $Computer -ErrorAction SilentlyContinue;
        
        if ($AllVariables) {

            $OutputArray = $null;
            $OutputArray = @();

            ForEach ($Variable in $AllVariables) {
                $VariableValues = $Variable.VariableValue.Split(";") | Where-Object {$_ -ne ""}
            
                Foreach ($VariableValue in $VariableValues) {
                    $VariableValueSplit = $Variable;
                    $VariableValueSplit.VariableValue = $VariableValue;
                
                    $output = $null;
                    $output = [EnvVariable]::new();
   
                    $output.Computer = $Computer;
                    $output.DateScanned = Get-Date -Format u;

                    $output.Name = $VariableValueSplit.Name;
                    $output.UserName = $VariableValueSplit.UserName;
                    $output.VariableValue = $VariableValueSplit.VariableValue;

                    $elapsed = $stopwatch.Elapsed;
                    $total = $total+1;               

                    $OutputArray += $output;

                };
	        };

            $elapsed = $stopwatch.Elapsed;
            $total = $total+1;

            return $OutputArray;
        }

        else { # System was not reachable

            if ($Fails) { # -Fails switch was used
                Add-Content -Path $Fails -Value ("$Computer");
            }

            else{ # -Fails switch not used
                            
                $output = $null;
                $output = [EnvVariable]::new();
                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;

                $total = $total+1;
                return $output;
            };
        };
	};

    END{
        $elapsed = $stopwatch.Elapsed;

        Write-Information -MessageData "Total Systems: $total `t Total time elapsed: $elapsed" -InformationAction Continue;
    };
};

