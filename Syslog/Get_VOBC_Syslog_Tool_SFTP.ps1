# Path to PuTTY's PSFTP.exe
$psftpPath = "C:\Program Files\PuTTY\psftp.exe"

# Connection details
$host       = "example.com"          # SFTP server hostname or IP
$username   = "myuser"               # SFTP username
$password   = "mypassword"           # WARNING: plain text password is insecure
$remoteDir  = "/remote/path"         # Remote directory
$remoteFile = "file.txt"             # Remote file name
$localDir   = "C:\local"             # Local directory to save file

# Create a temporary batch file with SFTP commands
$sftpCommands = @"
cd $remoteDir
get $remoteFile $localDir\$remoteFile
bye
"@

$tempFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $tempFile -Value $sftpCommands -Encoding ASCII

# Run PSFTP with password authentication
& $psftpPath "$username@$host" -pw $password -batch -b $tempFile

# Check exit code for success/failure
if ($LASTEXITCODE -eq 0) {
    Write-Host "Download successful: $localDir\$remoteFile"
} else {
    Write-Host "Download failed. Exit code: $LASTEXITCODE"
}

# Clean up
Remove-Item $tempFile -Force