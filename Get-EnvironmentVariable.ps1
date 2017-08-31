Function Get-EnvironmentVariable() {
    <#
    .Synopsis 
        Retreives the values of a specified environment variable from one or more systems.
    
    .Description
    	Retreives the values of a specified environment variable from one or more systems.
    
    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.
    
    .Example 
        get-content .\hosts.txt | Get-EnvironmentVariable $env:computername -Variable PATH | export-csv envVars.csv -NoTypeInformation
    
     .Notes 
        Updated: 2017-08-27
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
        $Computer,
        [Parameter()]
        $Variable        
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
        
        $Values = $null;
		$Values = (Get-CimInstance -Class Win32_Environment -ComputerName $Computer -ErrorAction Stop | Where {$_.Name -eq "$Variable"} | select -ExpandProperty VariableValue).Split(';') | Where-Object {$_ -ne ""};

		ForEach ($Value in $Values){
			$Value = $Value.Replace('"',"");

			if (-not $Value.EndsWith("\")){
				$Value = $Value + "\";
			};

			$output = $null;
            $output = New-Object PSObject;
			$output | Add-Member NoteProperty Host ($Computer);
			$output | Add-Member NoteProperty Variable ($Variable);
            $output | Add-Member NoteProperty Value ($Value);

			Write-Output $output;
			$output.PsObject.Members.Remove('*');
		};
	};

    END{
        $elapsed = $stopwatch.Elapsed;

        Write-Information -MessageData "Total Systems: $total `t Total time elapsed: $elapsed" -InformationAction Continue;
	};
};

