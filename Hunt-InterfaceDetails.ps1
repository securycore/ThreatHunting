FUNCTION Get-InterfaceDetails {
    <#
    .Synopsis 
        Gets the interface(s) settings for the given computer(s).

    .Description 
        Gets the interface(s) settings for the given computer(s) and returns a PS Object.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Get-InterfaceDetails 
        Get-InterfaceDetails SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-InterfaceDetails
        Get-InterfaceDetails -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-InterfaceDetails

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

        $datetime = Get-Date -Format u;
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();
        $total = 0;
        
	};

    PROCESS{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
        $interfaces = Invoke-Command -ScriptBlock {Get-NetAdapter} -ErrorAction SilentlyContinue; # get network adapters 
        $output = @();
           
            foreach ($interface in $interfaces) {#loop through the interfaces and build the custom output
                
                $ipDetails = Invoke-Command -ScriptBlock {Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.interfaceIndex -eq $interface.ifIndex}} | Select-Object * -ErrorAction SilentlyContinue;
                $object = New-Object -TypeName psobject;
                
                $object | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer;
                $object | Add-Member –MemberType NoteProperty –Name DNSDomain -Value $ipDetails.DNSDomain;
                $object | Add-Member –MemberType NoteProperty –Name Name -Value $interface.name;
                $object | Add-Member –MemberType NoteProperty –Name Description -Value $interface.interfaceDescription;
                $object | Add-Member –MemberType NoteProperty –Name Status -Value $interface.status;
                $object | Add-Member –MemberType NoteProperty –Name ifIndex -Value $interface.ifIndex;
                $object | Add-Member –MemberType NoteProperty –Name LinkSpeed -Value $interface.linkspeed;
                $object | Add-Member –MemberType NoteProperty –Name MAC -Value $interface.macAddress;
                $object | Add-Member –MemberType NoteProperty –Name IP -Value $ipDetails.ipaddress;
                $object | Add-Member –MemberType NoteProperty –Name SubNet -Value $ipDetails.IPsubnet;
                $object | Add-Member –MemberType NoteProperty –Name Gateway -Value $ipDetails.DefaultIPGateway;
                $object | Add-Member –MemberType NoteProperty –Name DNS -Value $ipDetails.DNSServerSearchOrder;
                $object | Add-Member –MemberType NoteProperty –Name MTU -Value $interface.MtuSize;
 
                $output += $object;
            };

        Return $output | Select-Object *;
        
    };

    END{
        $elapsed = $stopwatch.Elapsed;

        Write-Information -MessageData "Total Systems: $total `t Total time elapsed: $elapsed" -InformationAction Continue;
	};
};
