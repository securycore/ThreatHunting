FUNCTION Invoke-PortScan {
    <#
    .Synopsis 
        Utilizes Test-NetConnection to perform rudimentary port scanning.

    .Description 
        Utilizes Test-NetConnection to perform rudimentary port scanning. 
        Note that this is much slower due than things like nmap due to lack 
        of multithreading. However tools like PoshRSJob will certainly 
        speed things up.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Invoke-PortScan SomeHostName.domain.com
        Get-Content C:\hosts.txt | Invoke-PortScan
        Get-ADComputer -filter * | Select -ExpandProperty Name | Invoke-PortScan

    .Notes
        Updated: 2017-09-22
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

    [CmdletBinding()]
    PARAM(
    	    [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
            $Computer = $env:COMPUTERNAME,
            [Parameter()]
            [array]
            $Ports = (80, 443, 593, 135, 139, 445, 3389, 5988, 5989),
            [Parameter()]
            $Fails
        );

	BEGIN{

            $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
            Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

            $stopwatch = New-Object System.Diagnostics.Stopwatch;
            $stopwatch.Start();
	    };

    PROCESS{

        class Port {
            [String] $Computer
            [DateTime] $DateScanned

            [String] $RemoteAddress
            [String] $RemotePort
            [String] $TCPTestSucceeded
        };

        $OutputArray = $null;
        $OutputArray = @();

        Foreach ($Port in $Ports) {

            $Scan = Test-NetConnection -ComputerName $Computer -Port $Port | Select-Object ComputerName, RemoteAddress, RemotePort, TCPTestSucceeded;

            $output = $null;
            $output = [Port]::new();

            $output.Computer = $Computer;
            $output.DateScanned = Get-Date -Format u;

            $output.ComputerName = $Scan.ComputerName;
            $output.RemoteAddress = $Scan.RemoteAddress;
            $output.RemotePort = $Scan.RemotePort;
            $output.TcpTestSucceeded = $Scan.TcpTestSucceeded;
            
            $OutputArray += $output;
        };

        Return $OutputArray;
    };
};