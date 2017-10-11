FUNCTION Hunt-SCCMConsoleUsers {
<#
.Synopsis 
    Queries SCCM for a given hostname, FQDN, or IP address.

.Description 
    Queries SCCM for a given hostname, FQDN, or IP address.

.Parameter Computer  
    Computer can be a single hostname, FQDN, or IP address.

.Parameter CIM
    Use Get-CIMInstance rather than Get-WMIObject. CIM cmdlets use WSMAN (WinRM)
    to connect to remote machines, and has better standardized output (e.g. 
    datetime format). CIM cmdlets require the querying user to be a member of 
    Administrators or WinRMRemoteWMIUsers_ on the target system. Get-WMIObject 
    is the default due to lower permission requirements, but can be blocked by 
    firewalls in some environments.

.Example 
    Hunt-SCCMConsoleUsers 
    Hunt-SCCMConsoleUsers SomeHostName.domain.com
    Get-Content C:\hosts.csv | Hunt-SCCMConsoleUsers
    Hunt-SCCMConsoleUsers $env:computername
    Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-SCCMConsoleUsers

.Notes 
    Updated: 2017-10-10

    Contributing Authors:
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

    PARAM(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,
        [Parameter()]
        $SiteName="A1",
        [Parameter()]
        $SCCMServer="server.domain.com",
        [Parameter()]
        [switch]$CIM
    );

	BEGIN{
        $SCCMNameSpace="root\sms\site_$SiteName";

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Verbose "Started at $datetime"

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;
		
		class User {
            [String] $Computer
            [DateTime] $DateScanned
            
			[String] $ResourceNames
			[String] $GroupID
			[String] $LastConsoleUse
			[String] $NumberOfConsoleLogons
			[String] $SystemConsoleUser
			[String] $TotalUserConsoleMinutes
			[String] $TimeStamp
        };
	};

    PROCESS{        
                
        if ($Computer -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"){ # is this an IP address?
            
            $fqdn = [System.Net.Dns]::GetHostByAddress($Computer).Hostname;
            $ThisComputer = $fqdn.Split(".")[0];
        }
        
        else{ # Convert any FQDN into just hostname
            
            $ThisComputer = $Computer.Split(".")[0].Replace('"', '');
        };
            
        if ($CIM){
			
			$SMS_R_System = $Null;
            $SMS_R_System = Get-CIMInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceNames, ResourceID from SMS_R_System where name='$ThisComputer'";
            
			if ($SMS_R_System) {
				
				$ResourceID = $SMS_R_System.ResourceID; # Needed since -query seems to lack support for calling $SMS_R_System.ResourceID directly.
				$SMS_G_System_SYSTEM_CONSOLE_USER = Get-CIMInstance -namespace $SCCMNameSpace -computer $SCCMServer -query "select GroupID, LastConsoleUse, NumberOfConsoleLogons, SystemConsoleUser, TimeStamp, TotalUserConsoleMinutes from SMS_G_System_SYSTEM_CONSOLE_USER where ResourceID='$ResourceID'";
			};
		}
        else{
			
            $SMS_R_System = $Null;
            $SMS_R_System = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select ResourceNames, ResourceID from SMS_R_System where name='$ThisComputer'";
            
			if ($SMS_R_System) {
				$ResourceID = $SMS_R_System.ResourceID; # Needed since -query seems to lack support for calling $SMS_R_System.ResourceID directly.
				$SMS_G_System_SYSTEM_CONSOLE_USER = Get-WmiObject -namespace $SCCMNameSpace -computer $SCCMServer -query "select GroupID, LastConsoleUse, NumberOfConsoleLogons, SystemConsoleUser, TimeStamp, TotalUserConsoleMinutes from SMS_G_System_SYSTEM_CONSOLE_USER where ResourceID='$ResourceID'";
			};
		};

        if ($SMS_G_System_SYSTEM_CONSOLE_USER){
                
            $SMS_G_System_SYSTEM_CONSOLE_USER | ForEach-Object {
              
                $output = $null;
				$output = [User]::new();
				
				$output.Computer = $ThisComputer;
				$output.DateScanned = Get-Date -Format u;

                $output.ResourceNames = $SMS_R_System.ResourceNames[0];

                $output.LastConsoleUse = $_.LastConsoleUse;
                $output.NumberOfConsoleLogons = $_.NumberOfConsoleLogons;
                $output.SystemConsoleUser = $_.SystemConsoleUser;
                $output.GroupID = $_.GroupID; # does not appear to map to the GroupID in SMS_G_System_LocalGroupMembers
                $output.TotalUserConsoleMinutes = $_.TotalUserConsoleMinutes;
                $output.Timestamp = $_.Timestamp;

                return $output;
            };
        }
        else {
		
			$output = $null;
			$output = [User]::new();

			$output.Computer = $Computer;
			$output.DateScanned = Get-Date -Format u;
			
            return $output;
        };

        $elapsed = $stopwatch.Elapsed;
        $total = $total+1;
            
        Write-Verbose -Message "System $total `t $ThisComputer `t Time Elapsed: $elapsed";

    };

    END{
        $elapsed = $stopwatch.Elapsed;
        Write-Verbose "Total Systems: $total `t Total time elapsed: $elapsed";
	};
};


