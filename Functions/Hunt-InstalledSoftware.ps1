FUNCTION Hunt-InstalledSoftware {
    <#
    .Synopsis 
        Gets the installed Software for the given computer(s).

    .Description 
        Gets the installed Software for the given computer(s).

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-InstalledSoftware 
        Hunt-InstalledSoftware SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-InstalledSoftware
        Hunt-InstalledSoftware -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-InstalledSoftware

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
        $UninstallKey="SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
                      "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"; 

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();
        $total = 0;

        class InstalledSoftware
        {
            [datetime]$datescanned
            [string]$Computer
        };

    };

    PROCESS{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
       
        $installedSoft = $null;
        
        foreach ($key in $UninstallKey){

            $installedSoft += $installedSoft = Invoke-Command -Computer $Computer -ScriptBlock {Get-ItemProperty ('HKLM:\' + "$key" + '\*') -ErrorAction SilentlyContinue}; # get current uninstallkey properties 
       
        }

        if ($installedSoft) { 
          
            foreach ($item in $installedSoft) {#loop through each record
             
                $item | Add-Member -NotePropertyName DateScanned -NotePropertyValue $(Get-Date -Format u);
                $item | Add-Member -NotePropertyName Computer -NotePropertyValue $($Computer);
                            
            };

            $installedSoft = $installedSoft | Select-Object -Property Publisher, DisplayName, DisplayVersion, InstallDate,
                InstallSource, InstallLocation, pschildname, HelpLink |
                    Sort-Object -Property Displayname;
        

        Return $installedSoft;

        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer);
            if ($Fails) {
                
                $total++;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [InstalledSoftware]::new();

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