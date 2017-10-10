FUNCTION Hunt-BitLockerDetails {
    <#
    .Synopsis 
        Gets the current BitLocker details of a given system.

    .Description 
        Gets the current BitLocker details to include recovery key of a given system.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-BitLockerDetails
        '<COMPUTERNAME>','<COMPUTERNAME>','<COMPUTERNAME>' | Hunt-BitLockerDetails 
        Hunt-BitLockerDetails SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-BitLockerDetails
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-BitLockerDetails

    .Notes 
        Updated: 2017-08-31
        LEGAL: Copyright (C) 2017  Jeremy Arnold; Anthony Phipps
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

        $Volumes = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-BitLockerVolume} -ErrorAction SilentlyContinue;
        
        $Volumes |
            ForEach-Object {
                
                $Key = Invoke-Command -ComputerName $Computer -ScriptBlock {(Get-BitLockerVolume).KeyProtector.RecoveryPassword[1]} -ErrorAction SilentlyContinue;

                $_ | Add-Member -MemberType NoteProperty -Name RecoveryPassword -Value $Key;
                $_ | Add-Member –MemberType NoteProperty –Name Computer -Value $Computer;
                $_ | Add-Member –MemberType NoteProperty –Name DateScanned -Value (Get-Date -Format u);

                Return $_ | Select-Object *;
            };
    };

    END{
        $elapsed = $stopwatch.Elapsed;

        Write-Information -MessageData "Total Systems: $total `t Total time elapsed: $elapsed" -InformationAction Continue;
	};
};
