Get-Date

$RunDate = Get-Date -Format 'yyyy-MM-dd';
$stopwatch = New-Object System.Diagnostics.Stopwatch;
$stopwatch.Start();

Start-RSJob -Throttle 20 -InputObject (Get-Content C:\Temp\computers.csv) -Name {"$_"} -FunctionsToLoad "Hunt-Script" -ScriptBlock {Hunt-Script $_} | Select ID, Name, Command | Format-Table -Autosize;

# Job management 
While (Get-RSJob) # So long as there is a job remaining
{
    $CompletedJobs = Get-RSJob -State Completed;
    $RunningJobs = Get-RSJob -State Running;
    $NotStartedJobs = Get-RSJob -State NotStarted;
    $TimeStamp = Get-Date -Format 'yyyy/MM/dd hh:mm:ss';
    
    Write-Host -Object ("$TimeStamp - Saving $($CompletedJobs.Count) completed jobs. There are $($RunningJobs.Count)/$($NotStartedJobs.Count) jobs still running.");
    
    ForEach ($DoneJob in $CompletedJobs) 
    {

        Receive-RSJob -Id $DoneJob.ID | Export-Csv "C:\temp\Hunt-Script_$RunDate.csv" -NoTypeInformation -Append;
        Stop-RSJob -Id $DoneJob.ID;
        Remove-RSJob -Id $DoneJob.ID;
    };

    Start-Sleep -Seconds 10;
};


$elapsed = $stopwatch.Elapsed;
Write-Host $elapsed;

#	Import-Module C:\Scripts\PoshRSJob-master\PoshRSJob\PoshRSJob.psm1
