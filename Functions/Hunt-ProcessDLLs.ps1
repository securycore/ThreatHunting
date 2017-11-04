function Hunt-ProcessDLLs {
    <#
    .Synopsis 
        Gets a list of DLLs loaded by all process on a given system.

    .Description 
        Gets a list of DLLs loaded by all process on a given system.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-ProcessDLLs 
        Hunt-ProcessDLLs SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-ProcessDLLs
        Hunt-ProcessDLLs $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-ProcessDLLs

    .Notes 
        Updated: 2017-11-4

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
        [Parameter()]
        $Fails
    );

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;

        class DLLs
        {
            [String] $Computer
            [dateTime] $DateScanned

            [string] $ProcessID
            [string] $Process
            [String] $DLLName
            [String] $DLLCompany
            [String] $DLLProduct

        };
	};

    process{

        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present

        $processes = $null;
        $processes = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock { 
            
            $processes = Get-Process | Select-Object Id, ProcessName, Company, Product, Modules ;

            return $processes;
        
        };
            
        if ($processes) {
            
            $outputArray = @();

            Foreach ($process in $processes) {
                
                Foreach ($module in $process.modules){
                    
                    $output = $null;
                    $output = [DLLs]::new();
    
                    $output.Computer = $Computer;
                    $output.DateScanned = Get-Date -Format u;
    
                    $output.ProcessID = $process.id;
                    $output.Process = $process.processname;
                    $output.Company = $module.company;
                    $output.Product = $module.Product;
                    $output.DLLName = $module.modulename;
                    
                    $outputArray += $output;
                };
            };

            return $outputArray;

        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer);
            if ($Fails) {
                
                $total++;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [DLLs]::new();

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