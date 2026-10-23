# ===================================================================
#  Check MRU Certificate, MRU Logs, and MRU-to-SRS Connectivity v1.1
# ===================================================================
# Purpose   : Check MRU Certificate, MRU Logs
# and Check MRU-to-SRS Connectivity
# 
# Author    : MIYAJIMA Jun
# Team      : Customer Support
# Version   : v1.1
# Created   : 2026-07-07
# 
# Notes:
# - MRU Logs include /var/log/messages and security tunnel status
# - Output log saved to MRU_Cert_validity folder
# ===================================================================


# ===================================================================
# Change History
# ===================================================================
# v1.0  2026-07-07  Initial version
# v1.1  2026-08-15  Disables Host Key Verification
# ===================================================================

#ssh-keygen -t rsa -b 4096
# notepad $env:USERPROFILE\.ssh\id_rsa.pub

Write-Host "==================================================================="
Write-Host " Check MRU Certificate, MRU Logs, and MRU-to-SRS Connectivity v1.1 "
Write-Host "==================================================================="
[int]$trainId = Read-Host "Please enter Train ID"

if ($trainId -lt 1 -or $trainId -gt 129)
{
	echo "Invalid choice."
	Read-Host "Please enter to exit"
	exit
}

$folderpath = ".\MRU_Cert_validity"
If (-not (Test-Path -Path $folderpath)) {
New-Item -Path $folderpath -ItemType Directory | Out-NUll
}


[int]$cab =  Read-Host "Select Current Cab (1=DOWN, 2=UP)"
[int]$networkSwitch = Read-Host "Select Connected Network Switch (1=NS1, 2=NS2)"
# MRU IP 
# Write-Host "Train ID is: $trainId"
$thirdOctet=[math]::Floor((($trainId-1)*64+1)/256+128)
$fourthOctet=(($trainId-1)*64+1)%256
$upCabMRUIP ="10.13.$thirdOctet.$fourthOctet"

$thirdOctet=[math]::Floor((($trainId-1)*64+1)/256)
$fourthOctet=(($trainId-1)*64+1)%256
$downCabMRUIP ="10.13.$thirdOctet.$fourthOctet"

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = "$folderpath\Train$trainId-$timestamp.log"


if (
	($cab -eq "1" -and $networkSwitch -eq "1") -or
	($cab -eq "2" -and $networkSwitch -eq "2")
) {
	$loginhost = "$downCabMRUIP"
    $logFile = "$folderpath\Train$trainId-MRUA-$timestamp.log"
}
elseif (
	($cab -eq "1" -and $networkSwitch -eq "2") -or
	($cab -eq "2" -and $networkSwitch -eq "1")
) {
	$loginhost = "$upCabMRUIP"
    $logFile = "$folderpath\Train$trainId-MRUB-$timestamp.log"
}
else {
	echo "Invalid choice."
	Read-Host "Please enter to exit"
	exit
}

# Start-Transcript -Path $logFile -Append  | Out-Null

echo "UP CAB MRU: $upCabMRUIP"
echo "DOWN CAB MRU: $downCabMRUIP"

Write-Host

echo "loginhost: $loginhost"
$user = "root"
# $key  = "$env:USERPROFILE\.ssh\id_rsa"

# openssl x509 –in local.crt –noout –text |more
# ssh -i $key "$user@$loginhost" "cd /mnt/data/etc/certs; echo "MRU Cert Validity"; openssl x509 -in local.crt -noout -dates |more; echo; ping -c 4 10.0.96.5; echo; ping -c 4 10.4.96.5;" 2>&1 | Tee-Object -FilePath $logFile -Append
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL "$user@$loginhost" "echo "MRU Cert Validity"; openssl x509 -in /mnt/data/etc/certs/local.crt -noout -text |more; ping -c 4 10.0.96.5; ping -c 4 10.4.96.5; ping -c 4 10.80.0.63; ping -c 4 10.88.0.62" 2>&1 | Tee-Object -FilePath $logFile -Append

# Stop-Transcript | Out-Null

Read-Host "Please enter to exit"