# ===================================================================
#  VOBC Syslog Extraction Tool v1.0
# ===================================================================
# Purpose   : Obtain syslog via Putty, PSCP.exe
# 
# Author    : MIYAJIMA Jun
# Team      : Customer Support
# Version   : v1.0
# Created   : 2026-07-22
# 
# Notes:
# - SysLogs include /var/volatile and /scratchpad files
# - Output log saved to Syslogs folder
# ===================================================================


# ===================================================================
# Change History
# ===================================================================
# v1.0  2026-07-22  Initial version
# ===================================================================

Write-Host "==================================================================="
Write-Host " VOBC Syslog Extraction Tool v1.0"
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

$folderpath = ".\Syslogs"
If (-not (Test-Path -Path $folderpath)) {
New-Item -Path $folderpath -ItemType Directory | Out-NUll
}

$trainLogFolderPath = "$folderpath\Train$TrainID"
If (-not (Test-Path -Path $trainLogFolderPath)) {
New-Item -Path $trainLogFolderPath -ItemType Directory | Out-NUll
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFilePath = "$trainLogFolderPath\Train$TrainID-$timestamp"
$secondlogFilePath = "$trainLogFolderPath\Train$TrainID-$timestamp"

if (
	($Cab -eq "1" -and $Switch -eq "1") -or
	($Cab -eq "2" -and $Switch -eq "2")
) {
	$loginhost = "$VOBC1R1IP"
    $secondloginhost = "$VOBC2R2IP"
    $logFilePath = "$trainLogFolderPath\VOBC1R1-$timestamp"
    $secondlogFilePath = "$trainLogFolderPath\VOBC2R2-$timestamp"
}
elseif (
	($Cab -eq "1" -and $Switch -eq "2") -or
	($Cab -eq "2" -and $Switch -eq "1")
) {
	$loginhost = "$VOBC1R2IP"
    $secondloginhost = "$VOBC2R1IP"
    $logFilePath = "$trainLogFolderPath\VOBC1R2-$timestamp"
    $secondlogFilePath = "$trainLogFolderPath\VOBC2R1-$timestamp"
}
else {
	echo "Invalid choice."
	Read-Host "Please enter to exit"
	exit
}

If (-not (Test-Path -Path $logFilePath)) {
New-Item -Path $logFilePath -ItemType Directory | Out-NUll
}
If (-not (Test-Path -Path $secondlogFilePath)) {
New-Item -Path $secondlogFilePath -ItemType Directory | Out-NUll
}


$username = "root"
$pscp = "C:\FLMD Toolbox\putty\pscp.exe"

try {
    Write-Host "Downloading logs from $loginhost ..." -ForegroundColor Green

    & $pscp -pw root -P 22 -r "${username}@${loginhost}:/var/volatile" $logFilePath

    if ($LASTEXITCODE -ne 0) {
        throw "PSCP command failed with exit code $LASTEXITCODE"
    }
    Start-Sleep 3
    Write-Host "Done. Logs saved to $logFilePath" -ForegroundColor Green

# ------------------------------------------------------------------------------------

    Write-Host "Downloading logs from $secondloginhost ..." -ForegroundColor Green

    & $pscp -pw root -P 22 -r "${username}@${secondloginhost}:/var/volatile" $secondlogFilePath

    if ($LASTEXITCODE -ne 0) {
        throw "PSCP command failed with exit code $LASTEXITCODE"
    }
    Start-Sleep 3
    Write-Host "Done. Logs saved to $secondlogFilePath" -ForegroundColor Green

# ------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------
    Write-Host "Downloading logs from $loginhost ..." -ForegroundColor Green

    & $pscp -pw root -P 22 -r "${username}@${loginhost}:/scratchpad" $logFilePath

    if ($LASTEXITCODE -ne 0) {
        throw "PSCP command failed with exit code $LASTEXITCODE"
    }
    Start-Sleep 3
    Write-Host "Done. Logs saved to $logFilePath" -ForegroundColor Green

# ------------------------------------------------------------------------------------

    Write-Host "Downloading logs from $secondloginhost ..." -ForegroundColor Green

    & $pscp -pw root -P 22 -r "${username}@${secondloginhost}:/scratchpad" "$secondlogFilePath"

    if ($LASTEXITCODE -ne 0) {
        throw "PSCP command failed with exit code $LASTEXITCODE"
    }
    Start-Sleep 3
    Write-Host "Done. Logs saved to $secondlogFilePath" -ForegroundColor Green
}
catch {
    Write-Error $_
    # Delete empty folders
    if ((Get-ChildItem -Path $logFilePath -Force | Measure-Object).Count -eq 0) {
        Remove-Item -Path $logFilePath -Force
    }

    if ((Get-ChildItem -Path $secondlogFilePath -Force | Measure-Object).Count -eq 0) {
        Remove-Item -Path $secondlogFilePath -Force
    }
    Pause
    exit 1
}

#Get-ChildItem -Path $trainLogFolderPath -Directory -Recurse |
#Sort-Object FullName -Descending |
#ForEach-Object {
#    if ((Get-ChildItem -Path $_.FullName -Force | Measure-Object).Count -eq 0) {
#        Remove-Item -Path $_.FullName -Force
#    }
#}