# ===================================================================
#  VOBC Syslog Extraction Tool v1.0
# ===================================================================
# Purpose   : Obtain syslog via Putty, PSFTP.exe
# 
# Author    : MIYAJIMA Jun
# Team      : Customer Support
# Version   : v1.0
# Created   : 2026-11-18
# 
# Notes:
# - SysLogs include /var/volatile and /scratchpad files
# - Output log saved to Syslogs folder
# ===================================================================


# ===================================================================
# Change History
# ===================================================================
# v1.0  2026-11-18  Initial version
# ===================================================================

Write-Host "==================================================================="
Write-Host " VOBC Syslog Extraction Tool v1.0 SFTP"
Write-Host "==================================================================="
Write-Host

# Prompt user for information
[int]$TrainID = Read-Host "Please enter Train ID (1-129)"

if ($TrainID -lt 1 -or $TrainID -gt 129)
{
	echo "Invalid choice."
	Read-Host "Please enter to exit"
	exit
}

[int]$Cab = Read-Host "Select Current Cab (1=DOWN, 2=UP)"
[int]$Switch = Read-Host "Select Connected Network Switch (1=NS1, 2=NS2)"

$thirdOctet=[math]::Floor((($TrainID-1)*128+2)/256)
$fourthOctet=(($TrainID-1)*128+2)%256
$VOBC1R1IP ="10.14.$thirdOctet.$fourthOctet"

$thirdOctet=[math]::Floor((($TrainID-1)*128+2)/256+128)
$fourthOctet=(($TrainID-1)*128+2)%256
$VOBC1R2IP ="10.14.$thirdOctet.$fourthOctet"

$thirdOctet=[math]::Floor((($TrainID-1)*128+2)/256)
$fourthOctet=(($TrainID-1)*128+2+64)%256
$VOBC2R1IP ="10.14.$thirdOctet.$fourthOctet"

$thirdOctet=[math]::Floor((($TrainID-1)*128+2)/256+128)
$fourthOctet=(($TrainID-1)*128+2+64)%256
$VOBC2R2IP ="10.14.$thirdOctet.$fourthOctet"

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

$LocalPath1 = ".\Train$TrainID\$TimeStamp\VOBC1R1\"
$LocalPath2 = ".\Train$TrainID\$TimeStamp\VOBC2R2\"
$LocalPath3 = ".\Train$TrainID\$TimeStamp\VOBC1R2\"
$LocalPath4 = ".\Train$TrainID\$TimeStamp\VOBC2R1\"


$loginhost1 = ""
$loginhost2 = ""
$logFilePath1 = ""
$logFilePath2 = ""

if (
	($Cab -eq "1" -and $Switch -eq "1") -or
	($Cab -eq "2" -and $Switch -eq "2")
) {
    # Create folder if not exists
    New-Item -ItemType Directory -Force -Path $LocalPath1 | Out-Null
    New-Item -ItemType Directory -Force -Path $LocalPath2 | Out-Null
	$loginhost1 = "$VOBC1R1IP"
    $loginhost2 = "$VOBC2R2IP"
    $logFilePath1 = "$LocalPath1"
    $logFilePath2 = "$LocalPath2"
}
elseif (
	($Cab -eq "1" -and $Switch -eq "2") -or
	($Cab -eq "2" -and $Switch -eq "1")
) {
    # Create folder if not exists
    New-Item -ItemType Directory -Force -Path $LocalPath3 | Out-Null
    New-Item -ItemType Directory -Force -Path $LocalPath4 | Out-Null
	$loginhost1 = "$VOBC1R2IP"
    $loginhost2 = "$VOBC2R1IP"
    $logFilePath1 = "$LocalPath3"
    $logFilePath2 = "$LocalPath4"
}
else {
	echo "Invalid choice."
	Read-Host "Please enter to exit"
	exit
}

$CollectScript = Join-Path $PSScriptRoot "\modules\CollectLogs.ps1" 

$job1 = Start-Job -ArgumentList $CollectScript, $loginhost1, $logFilePath1  -ScriptBlock {
    param(
        $CollectScript,
        $loginhost1,
        $logFilePath1
    )
    & "$CollectScript" -HostName "$loginhost1" -LocalPath "$logFilePath1"
}

$job2 = Start-Job -ArgumentList $CollectScript, $loginhost2, $logFilePath2 -ScriptBlock {
    param(
        $CollectScript,
        $loginhost2,
        $logFilePath2
    )
    & "$CollectScript" -HostName "$loginhost2" -LocalPath "$logFilePath2"
}

Wait-Job $job1,$job2

Receive-Job $job1
Receive-Job $job2

# Check exit code for success/failure
if ($LASTEXITCODE -eq 0) {
    Write-Host "Download successful"
} else {
    Write-Host "Download failed. Exit code: $LASTEXITCODE"
}

# Clean up
# Remove-Item $tempFile -Force
Remove-Job $job1
Remove-Job $job2
pause