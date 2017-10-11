FUNCTION Hunt-HotFixes2 {
    <#
    .Synopsis 
        Gets the installed Hotfixes for the given computer(s).

    .Description 
        Gets the installed Hotfixes for the given computer(s).

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-HotFixes 
        Hunt-HotFixes SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-HotFixes
        Hunt-HotFixes -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-HotFixes

    .Notes 
        Updated: 2017-10-10

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

        class Hotfix
        {

            [datetime]$datescanned
            [string]$Computer
        
        };

    };

    PROCESS{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
        $Hotfixes = $null;
        $Hotfixes = Invoke-Command -Computer $Computer -ScriptBlock {Get-HotFix -ErrorAction SilentlyContinue}; # get current installed hotfixes 
      

        if ($Hotfixes) { 
          
            foreach ($hotfix in $Hotfixes) {#loop through each hotfix
             
                $hotfix | Add-Member -NotePropertyName DateScanned -NotePropertyValue $(Get-Date -Format u);
                $hotfix | Add-Member -NotePropertyName Computer -NotePropertyValue $($Computer);
            
            };

            $Hotfixes = $Hotfixes | select DateScanned, Computer, Description, HotfixID, InstalledBy, InstalledOn;
        
        Return $Hotfixes;

        }Else{# System not reachable
        
            if ($Fails) {

                # -Fails switch was used
                Add-Content -Path $Fails -Value ("$Computer");
            
            }else{ 

                # -Fails switch not used            
                $output = $null;
                $output = [Hotfix]::new();
                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;

            return $output;

            };

        };

    };

    END{
        $elapsed = $stopwatch.Elapsed;
        $total = $total+1;

        Write-Information -MessageData "Total Systems: $total `t Total time elapsed: $elapsed" -InformationAction Continue;

	};

};
