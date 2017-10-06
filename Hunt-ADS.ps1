function Hunt-ADS {
    <#
    .SYNOPSIS 
        Gets the processes applied to a given system.

    .DESCRIPTION 
        Gets the processes applied to a given system, including usernames.

    .PARAMETER Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .PARAMETER Services  
        Includes Services associated with each Process ID. Slows processing per system by a small amount while service are pulled.

    .PARAMETER DLLs  
        Includes DLLs associated with each Process ID. Note that DLLs cannot be pulled on remote systems due to lack of support in Get-Process.

    .PARAMETER Fails  
        Provide a path to save failed systems to.

    .EXAMPLE 
        Hunt-ADS 
        Hunt-ADS SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-ADS
        Hunt-ADS $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-ADS

    .NOTES 
        Updated: 2017-10-06
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
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        $Computer = $env:COMPUTERNAME,

        [Parameter()]
        $Path = "C:\temp",

        [Parameter()]
        $Fails
    );

    begin {

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Verbose "Started at $datetime";

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;

        class ADS {
            [String] $Computer
            [DateTime] $DateScanned

            [String] $FileName
            [String] $StreamName
            [String] $StreamLength
            [String] $StreamContent
            [DateTime] $CreationTimeUtc
            [DateTime] $LastAccessTimeUtc
            [DateTime] $LastWriteTimeUtc

        };
    };

    process {

        $Computer = $Computer.Replace('"', '');

        $Streams = $null;
        
        Write-Verbose "Attempting Get-ChildItem";

        $OldErrorActionPreference = $ErrorActionPreference;
        $ErrorActionPreference = "SilentlyContinue";

        $Streams = Invoke-Command -ArgumentList $Path -ComputerName $Computer -ScriptBlock {
            $Path = $args[0];

            $Streams = Get-ChildItem -Path $Path -Recurse -Force -Attributes !Directory -PipelineVariable FullName | 
            Get-Item -Stream * |
            Where-Object {($_.Stream -notlike "*DATA") -AND ($_.Stream -ne "Zone.Identifier")};

            ForEach ($Stream in $Streams) {
                $File = Get-Item $Stream.FileName;
                $StreamContent = Get-Content -Path $Stream.FileName -Stream $Stream.Stream;

                $Stream | Add-Member -MemberType NoteProperty -Name CreationTimeUtc -Value $File.CreationTimeUtc;
                $Stream | Add-Member -MemberType NoteProperty -Name LastAccessTimeUtc -Value $File.LastAccessTimeUtc;
                $Stream | Add-Member -MemberType NoteProperty -Name LastWriteTimeUtc -Value $File.LastWriteTimeUtc;
                $Stream | Add-Member -MemberType NoteProperty -Name StreamContent -Value $StreamContent;
            };

            Return $Streams;
        };

        $ErrorActionPreference = $OldErrorActionPreference;
        
        if ($Streams) {
            Write-Verbose "Streams exists";


            $OutputArray = $null;
            $OutputArray = @();

            ForEach ($Stream in $Streams) {

                $output = $null;
                $output = [ADS]::new();

                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;

                $output.FileName = $Stream.FileName;
                $output.StreamName = $Stream.Stream;
                $output.StreamLength = $Stream.Length;
                $output.StreamContent = $Stream.StreamContent;
                $output.CreationTimeUtc = $Stream.CreationTimeUtc;
                $output.LastAccessTimeUtc = $Stream.LastAccessTimeUtc;
                $output.LastWriteTimeUtc = $Stream.LastWriteTimeUtc;
                
                $total = $total + 1;

                $OutputArray += $output;
            };

            return $OutputArray;
        }
        else {
            
            Write-Verbose "System unreachable.";
            if ($Fails) {
                
                Write-Verbose "-Fails switch activated. Saving system to -Fails filepath.";
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                Write-Verbose "Writing failed Computer and DateScanned.";        
                $output = $null;
                $output = [ADS]::new();

                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;

                $total = $total + 1;

                return $output;
            };
        };
        
        $elapsed = $stopwatch.Elapsed;
        $total = $total + 1;
        
        Write-Verbose "System $total `t $ThisComputer `t Total Time Elapsed: $elapsed";

    };

    end {

        $elapsed = $stopwatch.Elapsed;

        Write-Verbose "Total Systems: $total `t Total time elapsed: $elapsed";
    };
};




