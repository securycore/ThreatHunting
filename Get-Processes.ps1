FUNCTION Get-Processes {
    <#
    .Synopsis 
        Gets the processes applied to a given system.

    .Description 
        Gets the processes applied to a given system, including usernames.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Services  
        Includes Services associated with each Process ID. Slows processing per system by a small amount while service are pulled.

    .Parameter DLLs  
        Includes DLLs associated with each Process ID. Note that DLLs cannot be pulled on remote systems due to lack of support in Get-Process.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Get-Processes 
        Get-Processes SomeHostName.domain.com
        Get-Content C:\hosts.csv | Get-Processes
        Get-Processes $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Get-Processes

    .Notes 
        Updated: 2017-09-05
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

        PARAM(
    	    [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
            $Computer = $env:COMPUTERNAME,
            [Parameter()]
            [switch]$Services,
            [Parameter()]
            [switch]$DLLs,
            [Parameter()]
            $Fails

        );

	    BEGIN{

            $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
            Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

            $stopwatch = New-Object System.Diagnostics.Stopwatch;
            $stopwatch.Start();

            $total = 0;

            class Process
            {
                [String] $Computer
                [String] $Mode
                [String] $BasePriority
                [String] $CPU
                [String] $CommandLine
                [String] $Company
                [String] $Description
                [String] $EnableRaisingEvents
                [String] $FileVersion
                [String] $Handle
                [Int32] $HandleCount
                [Int32] $Id
                [String] $MainModule
                [String] $MainWindowHandle
                [String] $MainWindowTitle
                [Int32] $ModuleCount
                [Datetime] $DateScanned
                [String] $DisplayName
                [String] $Path
                [String] $PriorityBoostEnabled
                [String] $PriorityClass
                [String] $PrivilegedProcessorTime
                [String] $ProcessName
                [String] $ProcessorAffinity
                [String] $Product
                [String] $ProductVersion
                [String] $Responding
                [Int32] $SessionId
                [String] $StartTime
                [Int32] $Threads
                [String] $TotalProcessorTime
                [String] $UserName
                [String] $Services
                [String] $DLLs
            }
	    }

        PROCESS{

            $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present

            $Processes = $null;
            $Mode = $null;
            
             #Try with -IncludeUserName, then fallback to older version, then fallback to not using Invoke-Command
            
			$Processes = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-Process -IncludeUserName} -ErrorAction SilentlyContinue;
            
            If ($Processes -eq $null){
            
                $Processes = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-Process} -ErrorAction SilentlyContinue;
				
				If ($Processes -eq $null){

					$Processes = Get-Process -ComputerName $Computer -ErrorAction SilentlyContinue;
					$Mode = "3";
				}
				else{
					$Mode = "2";
				};
            }
			else{
				$Mode = "1";
			};

            
            
        
            if ($Processes){ # The system was reachable, and Get-Process worked
        
                if ($Services){ # The -services switch was selected, so pull service info
                    $CIM_Services = $null;
                    $CIM_Services = Get-CIMinstance -class Win32_Service -Filter "Caption LIKE '%'" -ComputerName $Computer -ErrorAction SilentlyContinue;
                    # Odd filter explanation: http://itknowledgeexchange.techtarget.com/powershell/cim-session-oddity/
                };
            
                $CIM_Processes = $null;
                $CIM_Processes = Get-CIMinstance -class Win32_Process -Filter "Caption LIKE '%'" -ComputerName $Computer -ErrorAction SilentlyContinue;

                $Processes | ForEach-Object { # Work on each process provided in $Processes array

                    $ProcessID = $null;
                    $ProcessID = $_.Id;

                
                    if ($Services -AND $CIM_Services){ # The -services switch was selected, so pull service info on this process
                    
                        $ThisServices = $null;
                        $ThisServices = $CIM_Services | Where-Object ProcessID -eq $ProcessID;
                    };
                
                    if ($CIM_Processes){ # If CIM process collection worked, pull commandline and owner information

                        $CommandLine = $null;
                        $CommandLine = $CIM_Processes | Where-Object ProcessID -eq $ProcessID | Select-Object -ExpandProperty CommandLine;

                        if ($_.UserName -eq $null){
                            $ProcessOwner = $null;
                            $ProcessOwner = $CIM_Processes | Where-Object ProcessID -eq $ProcessID | Invoke-CimMethod -MethodName GetOwner -ErrorAction SilentlyContinue | Select-Object Domain, User;
                        };
                    };

                    $output = $null;
                    $output = [Process]::new();

                        $output.Computer = $Computer;
						$output.Mode = $Mode;
                        $output.BasePriority = $_.BasePriority;
                        $output.CPU = $_.CPU;
                        $output.CommandLine = $CommandLine;
                        $output.Company = $_.Company;
                        $output.Description = $_.Description;
                        $output.EnableRaisingEvents = $_.EnableRaisingEvents;
                        $output.FileVersion = $_.FileVersion;
                        $output.Handle = $_.Handle;
                        $output.HandleCount = $_.HandleCount;
                        $output.Id = $_.Id;
                        $output.MainModule = $_.MainModule;
                        $output.MainModule = $output.MainModule.Replace('System.Diagnostics.ProcessModule (', '').Replace(')', '');
                        $output.MainWindowHandle = $_.MainWindowHandle;
                        $output.MainWindowTitle = $_.MainWindowTitle;
                        $output.ModuleCount = @($_.Modules).Count;
                        $output.DisplayName = $_.Name;
                        $output.Path = $_.Path;
                        $output.PriorityBoostEnabled = $_.PriorityBoostEnabled;
                        $output.PriorityClass = $_.PriorityClass;
                        $output.PrivilegedProcessorTime = $_.PrivilegedProcessorTime;
                        $output.ProcessName = $_.ProcessName;
                        $output.ProcessorAffinity = $_.ProcessorAffinity;
                        $output.Product = $_.Product;
                        $output.ProductVersion = $_.ProductVersion;
                        $output.Responding = $_.Responding;
                        $output.DateScanned = Get-Date -Format u;
                        $output.SessionId = $_.SessionId;
                        $output.StartTime = $_.StartTime;
                        $output.Threads = @($_.Threads).Count;
                        $output.TotalProcessorTime = $_.TotalProcessorTime;
                        $output.UserName = if ($_.UserName) {$_.UserName} elseif ($ProcessOwner.User) {$ProcessOwner.Domain+"\"+$ProcessOwner.User;};
                        $output.Services = if ($ThisServices) {$ThisServices.PathName -Join "; ";};
                        $output.DLLs = if ($DLLs -AND $_.Modules) {$_.Modules -join "; ";};
                        $output.DLLs = $output.DLLs.Replace('System.Diagnostics.ProcessModule (', '').Replace(')', '')
						
						<#
                        UserName = if ($ProcessOwner.User) {$ProcessOwner.Domain+"\"+$ProcessOwner.User;};
                        MachineName = $_.MachineName;
                        NonpagedSystemMemorySize = $_.NonpagedSystemMemorySize;
                        NonpagedSystemMemorySize64 = $_.NonpagedSystemMemorySize64;
                        MaxWorkingSet = $_.MaxWorkingSet;
                        MinWorkingSet = $_.MinWorkingSet;
                        PagedMemorySize = $_.PagedMemorySize;
                        PagedMemorySize64 = $_.PagedMemorySize64;
                        PeakPagedMemorySize = $_.PeakPagedMemorySize;
                        PeakPagedMemorySize64 = $_.PeakPagedMemorySize64;
                        PeakVirtualMemorySize = $_.PeakVirtualMemorySize;
                        PeakVirtualMemorySize64 = $_.PeakVirtualMemorySize64;
                        PeakWorkingSet = $_.PeakWorkingSet;
                        PeakWorkingSet64 = $_.PeakWorkingSet64;
                        PrivateMemorySize = $_.PrivateMemorySize;
                        PrivateMemorySize64 = $_.PrivateMemorySize64;
                        UserProcessorTime = $_.UserProcessorTime;
                        VirtualMemorySize = $_.VirtualMemorySize;
                        VirtualMemorySize64 = $_.VirtualMemorySize64;
                        WorkingSet = $_.WorkingSet;
                        WorkingSet64 = $_.WorkingSet64;
                        #>
                
                    return $output; 
                };#end of each object processed for this system
        
            }
            else { # System was not reachable

                if ($Fails) { # -Fails switch was used
                    Add-Content -Path $Fails -Value ("$Computer");
                }
                else{ # -Fails switch not used
                            
                    $output = $null;
                        $output = [Process]::new();
                        $output.Computer = $Computer;
					    $output.DateScanned = Get-Date -Format u;

                    return $output;
                };
            };
         
            $elapsed = $stopwatch.Elapsed;
            $total = $total+1;
            
            Write-Information -MessageData "System $total `t $ThisComputer `t Time Elapsed: $elapsed" -InformationAction Continue;

        };

        END{
            $elapsed = $stopwatch.Elapsed;

            Write-Information -MessageData "Total Systems: $total `t Total time elapsed: $elapsed" -InformationAction Continue;
	    };
    };




