FUNCTION xGet-ActivePorts {
    <#
    .Synopsis 
        Gets the active ports for the given computer(s).

    .Description 
        Gets the active ports for the given computer(s) and returns a PS Object.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-ActivePorts 
        Hunt-ActivePorts SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-ActivePorts
        Hunt-ActivePorts -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-ActivePorts

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

        class ActivePorts
        {
            [Datetime] $DateScanned
            [String] $Computer
            [String] $LocalAddress
            [String] $LocalPort
            [String] $RemoteDNS
            [String] $RemoteAddress
            [String] $RemotePort
            [String] $State
            [String] $AppliedSetting
            [String] $OwningProcessID
            [String] $ProcessName
            [String] $ProcessPath
            [datetime] $ProcessStartTime

        };
	};

    PROCESS{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
       
        $activePorts = $null
        $activePorts = Invoke-Command -ScriptBlock {Get-NetTCPConnection | Where-Object {($_.state -eq 'listen') -or ($_.state -eq 'Established')}} -ErrorAction Stop; # get network adapters 
        $OutputArray = @();
        
        if ($activePorts) { 
          
            foreach ($port in $activePorts) {#loop through the ports and build the custom output
                $output = $null
                $output = [ActivePorts]::new();

                $process = Invoke-Command -ScriptBlock {Get-Process | Where-Object {$_.id -eq $port.owningProcess}} | Select-Object * -ErrorAction Stop;
                
                try
                {                    
                    $remoteDNS = Invoke-Command -ScriptBlock {Resolve-DnsName $port.remoteaddress -ErrorAction Stop}
                
                }catch [System.Exception]{

                    $output.RemoteDNS = $error[0].Exception.Message -split ': ' | Select-Object -Skip 1
                                                                        
                }               

                $output.DateScanned = Get-Date -Format u;
                $output.Computer = $Computer;
                $output.LocalAddress = $port.localAddress;
                $output.LocalPort = $port.localPort;
                $output.RemoteAddress = $port.remoteAddress;
                $output.RemotePort = $port.remoteport;
                $output.State = $port.state;
                $output.AppliedSetting = $port.AppliedSetting;
                $output.OwningProcessID = $port.owningProcess;
                $output.ProcessName = $process.Name;
                $output.ProcessPath = $process.Path;
                $output.ProcessStartTime = $process.startTime
                If (!$Output.RemoteDNS) {$output.RemoteDNS = $remoteDNS[0].namehost};

                $OutputArray += $output
            };

            Return $OutputArray;

        }Else{# System not reachable
        
            if ($Fails) {

                # -Fails switch was used
                Add-Content -Path $Fails -Value ("$Computer") 
            
            }else{ 

                # -Fails switch not used            
                $output = $null;
                $output = [Activeports]::new();
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