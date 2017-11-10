function Hunt-ProcessHandles {
    <#
    .Synopsis 
        Gets a list of Handles loaded by all process on a given system.

    .Description 
        Gets a list of Handles loaded by all process on a given system.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter ToolLocation
        The location of Sysinternals Handle.exe/Handle64.exe. This parameter is manadatory
        and is how the function gets the list of handles.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-ProcessHandles -Toollocation c:\tools\sysinternals
        Hunt-ProcessHandles SomeHostName.domain.com -Toollocation c:\tools\sysinternals
        Get-Content C:\hosts.csv | Hunt-ProcessHandles -Toollocation c:\tools\sysinternals
        Hunt-ProcessHandles $env:computername -Toollocation c:\tools\sysinternals
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-ProcessHandles -Toollocation c:\tools\sysinternals

    .Notes 
        Updated: 2017-11-10

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
        
    .LINK
        https://github.com/DLACERT/ThreatHunting
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,
        [Parameter(mandatory=$true)]
        $ToolLocation,
        [Parameter()]
        $Fails
    );

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;

        class Handles
        {
            [String] $Computer
            [dateTime] $DateScanned

            [string] $ProcessID
            [string] $Process
            [string] $Owner
            [string] $Location
            [string] $HandleType
            [string] $Attributes
            [string] $String
        };
	};

    process{

        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
        $remoteOS64 = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock {

            $remoteOS64 = [environment]::Is64BitOperatingSystem;
        
            return $remoteOS64;
        };
      
        if ($remoteOS64){$tool = 'handle64.exe'} else {$tool = 'handle.exe'};
        
        Write-Verbose ("{0}: Copying {1} to {0}." -f $Computer, $tool);
        
        try{Copy-Item -Path $($ToolLocation+'\'+$tool) -Destination $('\\'+$Computer+'\c$\temp\'+$tool); 
        }catch{$Error[0]};

        $handles = $null;
        $handles = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock { 
            
            $handles = Invoke-Expression "C:\temp\$tool -a -nobanner -accepteula";

            return $handles;
        
        };
            
        if ($handles) {
            [regex]$regexProcess = '(?<process>\S+)\spid:\s(?<pid>\d+)\s(?<string>.*)'
            [regex]$regexHandle = '(?<location>[A-F0-9]+):\s(?<type>\w+)\s{2}(?<attributes>\(.*\))?\s+(?<string>.*)'
            [regex]$nullHandle = '([A-F0-9]+):\s(\w+)\s+$'
            $outputArray = @();
            $handles = $handles | Where-Object {($_.length -gt 0) -and ($_ -notmatch $nullHandle)}
            Foreach ($handle in $handles) {
                if ($handle -match $regexProcess){
                    $process = $Matches.process;
                    $processPID = $Matches.pid;
                    $owner = $Matches.string;
                }
                if ($handle -match $regexHandle){
                    $output = $null;
                    $output = [Handles]::new();
    
                    $output.Computer = $Computer;
                    $output.DateScanned = Get-Date -Format u;
    
                    $output.ProcessID = $processPID;
                    $output.Process = $process;
                    $output.Owner =$owner;
                    $output.Location = $Matches.location;
                    $output.HandleType = $Matches.type;
                    $output.Attributes = $Matches.attributes;
                    $output.String = $Matches.string;
                                        
                    $outputArray += $output;
                }

            };
            Remove-Item -Path $('\\'+$Computer+'\c$\temp\'+$tool);
            return $outputArray[0..12000];#select first 12000

        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer);
            if ($Fails) {
                
                $total++;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [Handles]::new();

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