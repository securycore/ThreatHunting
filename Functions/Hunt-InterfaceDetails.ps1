FUNCTION Hunt-InterfaceDetails {
    <#
    .Synopsis 
        Gets the Interface(s) settings for the given computer(s).

    .Description 
        Gets the Interface(s) settings for the given computer(s) and returns a PS Object.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-InterfaceDetails 
        Hunt-InterfaceDetails SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-InterfaceDetails
        Hunt-InterfaceDetails -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-InterfaceDetails

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

        $datetime = Get-Date -Format u;
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();
        $total = 0;

        class Adapter
        {
            [String] $Computer
            [DateTime] $DateScanned
            [String] $FQDN
            [String] $Description
            [String] $NetConnectionID
            [String] $NetEnabled
            [String] $InterfaceIndex
            [String] $Speed
            [String] $MACAddress
            [String] $IPAddress
            [String] $Subnet
            [String] $Gateway
            [String] $DNS
            [String] $MTU
        };
        
	};

    PROCESS{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
        $Adapters = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-CimInstance Win32_NetworkAdapter | Select-Object * -ErrorAction SilentlyContinue}; #get a list of network adapters
        
        if ($Adapters) {

            $AdapterConfigs = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-CimInstance Win32_NetworkAdapterConfiguration | Select-Object * -ErrorAction SilentlyContinue};  #get the configuration for the current adapter
            $OutputArray = $null;
            $OutputArray = @();

            foreach ($Adapter in $Adapters) {#loop through the Interfaces and build the outputArray
                
                if ($Adapter.NetEnabled) {

                    $AdapterConfig = $AdapterConfigs | Where {$_.InterfaceIndex -eq $Adapter.InterfaceIndex};
                    $output = $null;
			        $output = [Adapter]::new();
   
                    $output.Computer = $Computer;
                    $output.DateScanned = Get-Date -Format u;
                    $output.FQDN = $Adapter.SystemName;
                    $output.Description = $Adapter.Description;
                    $output.NetConnectionID = $Adapter.NetConnectionID;
                    $output.NetEnabled = $Adapter.NetEnabled;
                    $output.InterfaceIndex = $Adapter.InterfaceIndex;
                    $output.Speed = $Adapter.Speed;
                    $output.MACAddress = $Adapter.MACAddress;
                    $output.IPAddress = $AdapterConfig.ipaddress[0];
                    $output.Subnet = $AdapterConfig.IPsubnet[0];
                    $output.Gateway = $AdapterConfig.DefaultIPGateway;
                    $output.DNS = $AdapterConfig.DNSServerSearchOrder;
                    $output.MTU = $AdapterConfig.MTU;
 
                    $OutputArray += $output;

                };

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
                $output = [Adapter]::new();

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