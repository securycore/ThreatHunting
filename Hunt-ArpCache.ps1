FUNCTION xGet-ArpCache {
    <#
    .Synopsis 
        Gets the arp cache for the given computer(s).

    .Description 
        Gets the arp cache from all connected interfaces for the given computer(s).

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        xGet-ArpCache 
        xGet-ArpCache SomeHostName.domain.com
        Get-Content C:\hosts.csv | xGet-ArpCache
        xGet-ArpCache -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | xGet-ArpCache

    .Notes 
        Updated: 2017-08-31
        LEGAL: Copyright (C) 2017  Jeremy Arnold
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
    )

	BEGIN{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();
        $total = 0;

        class ArpCache
        {
            [Datetime] $DateScanned
            [string] $Computer
            [String] $IfIndex
            [string] $InterfaceAlias
            [String] $IPAdress
            [String] $MAC
            [String] $State
            [String] $PolicyStore

        };
	};

    PROCESS{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
       
        $interfaces = $null
        $interfaces = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-NetAdapter | Where-Object {$_.MediaConnectionState -eq 'Connected'} -ErrorAction Stop}; # get connected network adapters 
        $OutputArray = @();
        
        if ($interfaces) { 
          
            foreach ($interface in $interfaces) {#loop through the connected interfaces and get the arp table
             
                $arpTable = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-NetNeighbor |
                    Where-Object {$_.ifIndex -eq $interface.ifIndex -and $_.State -ne 'Permanent'}} |
                        Where-Object {$_.state -eq 'Unreachable'} | Test-Connection -Count 1 -Quiet ; #test unreachable connections
                
                $arpTable = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-NetNeighbor |
                    Where-Object {$_.ifIndex -eq $interface.ifIndex -and $_.State -ne 'Permanent'}} |
                         Select-Object *; # grab the arp table again after unreachables have been tested
    
                    foreach ($arpRecord in $arpTable) {
                        $output = $null
                        $output = [ArpCache]::new();
                
                        $output.DateScanned = Get-Date -Format u;
                        $output.Computer = $Computer;
                        $output.IfIndex = $arpRecord.ifIndex;
                        $output.InterfaceAlias = $arpRecord.interfaceAlias;
                        $output.IPAdress = $arpRecord.ipaddress;
                        $output.MAC = $arpRecord.linklayerAddress;
                        $output.State = $arpRecord.state;
                        $output.PolicyStore = $arpRecord.store;                 

                    $OutputArray += $output
                    };
            };
            Return $OutputArray;

        }Else{# System not reachable
        
            if ($Fails) {

                # -Fails switch was used
                Add-Content -Path $Fails -Value ("$Computer");
            
            }else{ 

                # -Fails switch not used            
                $output = $null;
                $output = [ArpCache]::new();
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
