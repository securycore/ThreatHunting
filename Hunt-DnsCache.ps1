FUNCTION Hunt-DNSCache {
    <#
    .Synopsis 
        Gets the DNS cache for the given computer(s).

    .Description 
        Gets the DNS cache from all connected interfaces for the given computer(s).

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-DNSCache 
        Hunt-DNSCache SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-DNSCache
        Hunt-DNSCache -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-DNSCache

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

        class DNSCache
        {
            [Datetime] $DateScanned
            [string] $Computer
            [string] $Status
            [String] $DataLength
            [String] $RecordResponse
            [String] $TTL
            [String] $RecordType            
            [String] $Record
            [string] $Entry
            [string] $RecordName

        };
	};

    PROCESS{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
       
        $dnsCache = $null
        $dnsCache = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-DnsClientCache -ErrorAction Stop}; # get dns cache 
        $OutputArray = @();
        
        if ($dnsCache) { 
          
            foreach ($dnsRecord in $dnsCache) {#loop through each DNS record
             
                $output = $null
                $output = [DNSCache]::new();
                
                $output.DateScanned = Get-Date -Format u;
                $output.Computer = $Computer;
                $output.Status = $dnsRecord.status;# need to fix conversion from text to digit
                $output.DataLength = $dnsRecord.dataLength;
                $output.RecordResponse = $dnsRecord.section;
                $output.TTL = $dnsRecord.TimeToLive;
                $output.RecordType = $dnsRecord.RecordType;
                $output.Record = $dnsCache.data;
                $output.Entry = $dnsRecord.entry;
                $output.RecordName = $dnsRecord.RecordName;                 

                $OutputArray += $output
            
            };
            Return $OutputArray;

        }Else{# System not reachable
        
            if ($Fails) {

                # -Fails switch was used
                Add-Content -Path $Fails -Value ("$Computer");
            
            }else{ 

                # -Fails switch not used            
                $output = $null;
                $output = [DNSCache]::new();
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
