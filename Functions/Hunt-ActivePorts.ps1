function Hunt-ActivePorts {
    <#
    .Synopsis
        Gets the active ports for the given computer(s).

    .Description
        Gets the active ports for the given computer(s) and returns a PS Object.

    .Parameter Computer
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Path
        Resolve owning PID to process path. Increases hunt time per system.       

    .Parameter Fails
        Provide a path to save failed systems to.

    .Example
        Hunt-ActivePorts 
        Hunt-ActivePorts SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-ActivePorts
        Hunt-ActivePorts -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-ActivePorts

    .Notes
        Updated: 2017-10-17

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
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,
        
        [Parameter()]
        [switch] $Path,

        [Parameter()]
        $Fails
    );

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();
        $total = 0;

        class TCPConnection
        {
            [String] $Computer
            [DateTime] $DateScanned

            [String] $LocalAddress
            [String] $LocalPort
            [String] $RemoteAddress
            [String] $RemotePort
            [String] $State
            [String] $AppliedSetting
            [String] $OwningProcessID
            [String] $OwningProcessPath
        };
	};

    process{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
        
        $TCPConnections = $null;
        $TCPConnections = Invoke-Command -ComputerName $Computer -ScriptBlock {
            $TCPConnections = Get-NetTCPConnection -State Listen, Established;
            
            if ($using:Path) {
                $TCPConnections | ForEach-Object {
                    $_ | Add-Member -MemberType NoteProperty -Name Path -Value ((Get-Process -Id $_.OwningProcess).Path);
                };
            };

            return $TCPConnections;
        };
        
        if ($TCPConnections) {

            Write-Verbose ("{0}: Parsing results." -f $Computer);
            $OutputArray = @();
          
            foreach ($TCPConnection in $TCPConnections) {

                $output = $null;
                $output = [TCPConnection]::new();

                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;
                
                $output.LocalAddress = $TCPConnection.LocalAddress;
                $output.LocalPort = $TCPConnection.LocalPort;
                $output.RemoteAddress = $TCPConnection.RemoteAddress;
                $output.RemotePort = $TCPConnection.RemotePort;
                $output.State = $TCPConnection.State;
                $output.AppliedSetting = $TCPConnection.AppliedSetting;
                $output.OwningProcessID = $TCPConnection.OwningProcess;
                $output.OwningProcessPath = $TCPConnection.Path;
                
                $OutputArray += $output;
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