FUNCTION Hunt-InstalledHardware {
    <#
    .Synopsis 
        Gets a list of installed devices for the given computer(s).

    .Description 
        Gets a list of installed devices for the given computer(s).

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-InstalledHardware 
        Hunt-InstalledHardware SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-InstalledHardware
        Hunt-InstalledHardware -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-InstalledHardware

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

        class Device
        {
            [Datetime] $DateScanned
            [string] $Computer
            [String] $Class
            [string] $Caption
            [string] $Description
            [String] $DeviceID

        };

    };

    PROCESS{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
        $OutputArray = @();
        $drivers = $null;
        Write-Verbose "Getting a list of installed devices..."
        $devices = Invoke-Command -Computer $Computer -ScriptBlock {Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue};
       
        if ($devices) { 
            $deviceClassArray = $devices | Group-Object pnpclass | Select-Object Name, Count | Sort-Object name;
            foreach ($device in $devices) {
             
                $output = $null;
                $output = [Device]::new();
                
                $output.DateScanned = Get-Date -Format u;
                $output.Computer = $Computer;
                $output.Class = $device.pnpclass;
                $output.caption = $device.caption;
                $output.description = $device.description;
                $output.deviceID = $device.deviceID;

                $OutputArray += $output;
            
            };

            Return $OutputArray;
        
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer);
            if ($Fails) {
                
                $total++;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [ArpCache]::new();

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