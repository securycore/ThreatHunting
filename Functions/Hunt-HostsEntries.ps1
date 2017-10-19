function Hunt-HostsEntries {
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
        Hunt-ArpCache 
        Hunt-ArpCache  SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-ArpCache
        Hunt-ArpCache -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-ArpCache

    .Notes 
        Updated: 2017-10-17

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

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,
        
        [Parameter()]
        $Fails
    );

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();
        $total = 0;

        class Entry
        {
            [string] $Computer
            [Datetime] $DateScanned

            [String] $HostsIP
            [string] $HostsName
            [String] $HostsComment
        };
	};

    process{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present

        $HostsData = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock {
            $Hosts = Join-Path -Path $($env:windir) -ChildPath "system32\drivers\etc\hosts";

            [regex]$nonwhitespace = "\S";

            Get-Content $Hosts | Where-Object {
                (($nonwhitespace.Match($_)).value -ne "#") -and ($_ -notmatch "^\s+$") -and ($_.Length -gt 0); # exlcude full-line comments and blank lines
            };
        };

        if ($HostsData){

            Write-Verbose ("{0}: Parsing results." -f $Computer);
            $HostsData | ForEach-Object {

                $ip = $null;
                $hostname = $null;
                $comment = $null;

                $_ -match "(?<IP>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+(?<HOSTNAME>\S+)" | Out-Null;

                $ip = $matches.ip;
                $hostname = $matches.hostname;

                if ($_.contains("#")) {
                    
                    $comment = $_.substring($_.indexof("#")+1);
                };

                $output = $null;
                $output = [Entry]::new();
        
                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;
                
                $output.HostsIP = $ip;
                $output.HostsName = $hostname;
                $output.HostsComment = $comment;

                $total = $total+1;
                return $output;
            }
        }
        else {
            
            Write-Verbose ("{0}: System unreachable." -f $Computer);
            if ($Fails) {
                
                $total = $total+1;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [Entry]::new();

                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;
                
                $total = $total+1;
                return $output;
            };
        };
    };

    end {

        $elapsed = $stopwatch.Elapsed;

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed);
    };
};