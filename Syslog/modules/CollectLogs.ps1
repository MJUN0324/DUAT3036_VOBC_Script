param(
    [string]$HostName,
    [string]$LocalPath
)

Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

# Session settings
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Sftp
    HostName = "$HostName"
    UserName = "root"
    Password = "root"
    GiveUpSecurityAndAcceptAnySshHostKey = $true
}

$RemoteFolders = @(
    "/var/volatile/*",
    "/var/scratchpad/*",
    "/var/diag/cs*/diag/config"
)

$session = New-Object WinSCP.Session

try {
    $session.Open($sessionOptions)

    # Download all files
    foreach ($Folder in $RemoteFolders)
    {
        $session.GetFiles($Folder, "$LocalPath\").Check()
    }

    Write-Host "Download completed."
    Write-Host "Files stored at $LocalPath"
}
finally{
    $session.Dispose()
}