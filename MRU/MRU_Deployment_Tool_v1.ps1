# ===================================================================
#  MRU Deployment Tool v1.0
# ===================================================================
# Purpose   : Deploy MRU OS, Data and Project
# 
# Author    : MIYAJIMA Jun
# Team      : Customer Support
# Version   : v1.0
# Created   : 2026-10-18
# 
# Notes:
# ===================================================================


# ===================================================================
# Change History
# ===================================================================
# v1.0  2026-10-18  Initial version
# ===================================================================

Write-Host "==================================================================="
Write-Host " MRU Deployment Tool v1.0"
Write-Host "==================================================================="
$usingMRUTool = $true
while($usingMRUTool)
{
Write-Host
Write-Host "[1] Extract certificate from old MRU"
Write-Host "[2] Configure new MRU"
Write-Host
[int]$toolOption = Read-Host "Enter your option (1,2)"

switch($toolOption) 
{
    #---------------------------------Extract MRU Cert---------------------------------
    {$_ -eq 1}
    {
        $folderpath = ".\Config_MRU"
        If (-not (Test-Path -Path $folderpath)) {
        New-Item -Path $folderpath -ItemType Directory | Out-NUll
        }

        $LogFile = ".\Config_MRU\SerialLog.log"
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"



        Write-Host

        $port = New-Object System.IO.Ports.SerialPort COM1,115200,None,8,one
        $port.ReadTimeout = 1000
        $port.NewLine = "`r"

        $port.Open()

        function Write-Log{
          param([string]$Message)

          # $timestamp = Get-Date -Format "yyyy.MM-dd HH:mm:ss.fff"
          # Add-Content -Path $LogFile -Value "[$timestamp] $Message"

          Add-Content -Path $LogFile -Value $Message
        }

        try {
          $idleTimeout = 5
          $lastDataTime = Get-Date
          # check if it can login
          # -> implement here
          while (((Get-Date) - $lastDataTime).TotalSeconds -lt $idleTimeout) 
          {
            $data = $port.ReadExisting()

            if ($data)
            {
                Write-Log "RX> $data"
                # Add-Content $LogFile $data
                Write-Host "RX> $data"
                $lastDataTime = Get-Date
                Write-Host "The device is not ready to operate, please try again later" -ForegroundColor Red
                Write-Error "The devce is not ready to operate, please try again later"
                exit 1
            }
            #if data exist before starting the process means it is booting
            # hence terminate the process as it won't start properly
          }
          # Send username
          $port.WriteLine("root")
          Start-Sleep 1

          # Send password
          $port.WriteLine("thalesSDR")
          Start-Sleep 1

          Write-Host "Connected to COM1"

          $data = $port.ReadExisting()
          #-------------------------------------------------------------------------------------------------
          # check which mru side is connected
          $port.Write("if [ -f /etc/trusted ]; then echo 'TRUSTED'; elif [ -f /etc/untrusted ]; then echo 'UNTRUSTED'; else echo 'UNKNOWN'; fi`r")
          Start-Sleep 1
          $data = $port.ReadExisting()
          $configuringMRUSide = "UNKNOWN"
          $lines = $data -split "`r?`n"
          $untrustedMatches = $lines | Where-Object {$_ -match "^UNTRUSTED"}
          $trustedMatches = $lines | Where-Object {$_ -match "^TRUSTED"}
          if($untrustedMatches.Count -eq 1)
          {
            $configuringMRUSide = "UNTRUSTED"
          }
          elseif($trustedMatches.Count -eq 1)
          {
            $configuringMRUSide = "TRUSTED"
          }

          if ($configuringMRUSide -eq "UNTRUSTED")
          {
            Write-Host "You got the wrong side, this is the ${configuringMRUSide} side, please try again on the TRUSTED side!!!" -ForegroundColor Red
            Write-Error "Configure-Wrong-MRU-side"
            $port.WriteLine("exit")
            exit 1
          }
          elseif ($configuringMRUSide -eq "TRUSTED")
          {
            Write-Host "Good Job! you are on the TRUSTED side" -ForegroundColor Green
          }
          else
          {
            Write-Host "You got the wrong side, this is the ${configuringMRUSide} side, please try again!!!" -ForegroundColor Red
            Write-Error "Configure-Wrong-MRU-side"
            $port.WriteLine("exit")
            exit 1
          }
          #-------------------------------------------------------------------------------------------------
  
          $port.WriteLine("openssl x509 -in /mnt/data/etc/certs/local.crt -noout -text | grep 'IP Address'")
          Start-Sleep 1
          $portReading = $port.ReadExisting()
          if ($portReading -match 'IP Address:([\d\.]+)')
          {
            $MRUCertIP = $matches[1]
          }
  
          $octets = $MRUCertIP.Split('.').Trim()
          $thirdOctet = $octets[2]
          $fourthOctet = $octets[3]
          $MRUCertCabSide = "UNKNOWN"
          $MRUCertTrainID = ""
          if ($fourthOctet -ne "")
          {
            $MRUCertTrainID = $fourthOctet
          }
  
          $MRUID = ""
          if ($thirdOctet -eq "208")
          {
            $MRUCertCabSide = "DOWN"
            $MRUID = "MRU${MRUCertTrainID}A"

          }
          elseif ($thirdOctet -eq "209")
          {
            $MRUCertCabSide = "UP"
            $MRUID = "MRU${MRUCertTrainID}B"
          }
  

          if ($MRUCertCabSide -eq "UNKNOWN" -or $MRUCertTrainID -eq "" -or $MRUID -eq "") 
          {
            Write-Log "UNKNOWN Cert detected, Please try again!"
            Write-Host "UNKNOWN Cert detected, Please try again!" -ForegroundColor Red
            Write-Error "UNKNOWN Cert detected"
            Write-Log "TX> exit"
            Write-Host "TX> exit"
            $port.WriteLine("exit")
            exit 1

          }
          Write-Log "This MRU cert is from Train ${MRUCertTrainID} ${MRUCertCabSide} cab side, ${MRUID}"
          Write-Host "This MRU cert is from Train ${MRUCertTrainID} ${MRUCertCabSide} cab side, ${MRUID}" -ForegroundColor Cyan
          #-------------------------------------------------------------------------------------------------

          $Commands = @(
                "lsusb",
                "mount /mnt/usb",
                "mkdir -p /mnt/usb/certs/${MRUID}",
                "cp -f /mnt/data/etc/certs/ca.* /mnt/usb/certs/${MRUID}",
                "cp -f /mnt/data/etc/certs/local.key /mnt/usb/certs/${MRUID}",
                "cp -f /mnt/data/etc/certs/local.crt /mnt/usb/certs/${MRUID}",
                "umount /mnt/usb",
                "exit"
            )
          foreach ($cmd in $Commands) {
            # confirm USB is mounted after inserted
            if ($cmd -eq "mount /mnt/usb")
            {
                Start-Sleep 10
            }

            Write-Log "TX> $cmd"
            Write-Host "TX> $cmd" -ForegroundColor Cyan

            try{
                $port.WriteLine($cmd)
            }
            catch {
                Write-Log "TX> Connection lost while sending '$cmd'"
                Write-Host "Connection lost while sending '$cmd'" -ForegroundColor Red
                break
            }

            Start-Sleep 5
            $lastDataTime = Get-Date
        # -----------------------------------------------------------------------
            while (((Get-Date) - $lastDataTime).TotalSeconds -lt $idleTimeout) 
            {
                $data = $port.ReadExisting()

                if ($data.Length -gt 0)
                {
                    Write-Log "RX> $data"
        #            Add-Content $LogFile $data
                    Write-Host "RX> $data"
                    $lastDataTime = Get-Date
                }
                # Verify usb is mounted
                if ($cmd -eq "lsusb")
                {
                    $lines = $data -split "`r?`n"
                    $matches = $lines | Where-Object {$_ -match "Bus 001 Device \d{3}:"}
                    if($matches.Count -eq 2) {
                        Write-Host "USB Exists" -ForegroundColor Green
                        Start-Sleep 5
                        break
                    }
                    elseif($matches.Count -lt 2) 
                    {
                        Start-Sleep 5
                        Write-Host "USB not exists" -ForegroundColor Red
                        Write-Error "USB not exists"
                        Write-Log "TX> exit"
                        Write-Host "TX> exit"
                        $port.WriteLine("exit")
                        exit 1
                    }
                }

                if ($data -match "mount: mounting /dev/sda1 on /mnt/usb failed: No such device or address")
                {
                    Write-Host "USB device is not mounted." -ForegroundColor Red
                    Write-Error "USB device is not mounted."
                    $port.WriteLine("exit")
                    exit 1
                }

                Start-Sleep -Milliseconds 100
            }
        # -----------------------------------------------------------------------
          }
          exit 0
        }
        Catch
        {
          Write-Host "An error occurred: $_" -ForegroundColor Red
          exit 1
        }
        finally{
          if ($port.IsOpen) {
            $port.Close()
          }

          Write-Host "Exit with exitcode $LASTEXITCODE."
          Write-Host "Press Enter to exit" -ForegroundColor Green
          Read-Host
        }
        break
    }

    # ---------------------------------Configure MRU---------------------------------
    {$_ -eq 2}
    {
        Write-Host "This will erase everything on the MRU" -ForegroundColor Yellow
        $continueConfigMRU = Read-Host "Are you sure you want to continue? (y/N)"
        Write-Host
        if($continueConfigMRU -notmatch "y"){break}

        [int]$trainId = Read-Host "Please enter Train ID"

        if ($trainId -lt 1 -or $trainId -gt 129)
        {
	        echo "Invalid choice."
	        Read-Host "Please enter to exit"
	        exit
        }

        $folderpath = ".\Config_MRU"
        If (-not (Test-Path -Path $folderpath)) {
        New-Item -Path $folderpath -ItemType Directory | Out-NUll
        }

        $LogFile = ".\SerialLog.log"
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        Write-Host ""
        $cab =  (Read-Host "Select Current Cab (A=DOWN, B=UP)").ToUpper().Trim()

        Write-Host ""
        $mruSide =  Read-Host "Select connected MRU side (A=un-trusted, B=trusted)"

        $copyCert = "y"

        $usbMRUCertFolderPath = "/mnt/usb/certs/MRU${trainId}${cab}"

        if ($mruSide -match "b")
        {
            $copyCert =  Read-Host "Copy and Check Cert (Y/n), default is Y"

            if ($copyCert -match "n" -or $copyCert -match "no")
            {
                $copyCert = "n"
            }
            else
            {
                $copyCert = "y"
            }
        }

        if ($cab -match "a" -and $mruSide -match "a") {
            $LogFile = "$folderpath\Train$trainId-MRUA-untrusted-$timestamp.log"
            $Commands = @(
        #        "lsusb",
                "mount /mnt/usb",
                "cp -p -r /mnt/usb/untrusted/* /var/xfer",
                "umount /mnt/usb",
                "cd /var/xfer",
                "./writeOS.sh",
                "./writeData.sh",
        #        "fw_setenv bootdelay 205",
                "./writeProject.sh untrusted mru ${trainId}A",
                "./reboot.sh"
            )
        }
        elseif ($cab -match "a" -and $mruSide -match "b") {
            $LogFile = "$folderpath\Train$trainId-MRUA-trusted-$timestamp.log"
            $Commands = @(
        #        "lsusb",
                "mount /mnt/usb",
                "cp -p -r /mnt/usb/trusted/* /var/xfer",
                "cd /var/xfer",
                "./writeOS.sh",
                "./writeData.sh",
                "./writeProject.sh trusted mru ${trainId}A",
                "cp ${usbMRUCertFolderPath}/ca.* /mnt/data/etc/certs",
                "cp ${usbMRUCertFolderPath}/local.crt /mnt/data/etc/certs",
                "cp ${usbMRUCertFolderPath}/local.key /mnt/data/etc/certs",
                "umount /mnt/usb",
                "openssl x509 -in /mnt/data/etc/certs/local.crt -noout -text |more",
                "openssl x509 -in /mnt/data/etc/certs/local.crt -noout -text | grep 'IP Address'",
                "exit"
            )
        }
        elseif ($cab -match "b" -and $mruSide -match "a") {
            $LogFile = "$folderpath\Train$trainId-MRUB-untrusted-$timestamp.log"
            $Commands = @(
         #       "lsusb",
                "mount /mnt/usb",
                "cp -p -r /mnt/usb/untrusted/* /var/xfer",
                "umount /mnt/usb",
                "cd /var/xfer",
                "./writeOS.sh",
                "./writeData.sh",
         #       "fw_setenv bootdelay 205",
                "./writeProject.sh untrusted mru ${trainId}B",
                "./reboot.sh"
            )
        }
        elseif ($cab -match "b" -and $mruSide -match "b") {
            $LogFile = "$folderpath\Train$trainId-MRUB-trusted-$timestamp.log"
            $Commands = @(
         #       "lsusb",
                "mount /mnt/usb",
                "cp -p -r /mnt/usb/trusted/* /var/xfer",
                "cd /var/xfer",
                "./writeOS.sh",
                "./writeData.sh",
                "./writeProject.sh trusted mru ${trainId}B",
                "cp ${usbMRUCertFolderPath}/ca.* /mnt/data/etc/certs",
                "cp ${usbMRUCertFolderPath}/local.crt /mnt/data/etc/certs",
                "cp ${usbMRUCertFolderPath}/local.key /mnt/data/etc/certs",
                "umount /mnt/usb",
                "openssl x509 -in /mnt/data/etc/certs/local.crt -noout -text |more",
                "openssl x509 -in /mnt/data/etc/certs/local.crt -noout -text | grep 'IP Address'",
                "exit"
            )
        }
        else {
	        echo "Invalid choice."
	        Read-Host "Please enter to exit"
	        exit 1
        }



        Write-Host

        $port = New-Object System.IO.Ports.SerialPort COM1,115200,None,8,one
        $port.ReadTimeout = 1000
        $port.NewLine = "`r"

        $port.Open()

        function Write-Log{
          param([string]$Message)

          # $timestamp = Get-Date -Format "yyyy.MM-dd HH:mm:ss.fff"
          # Add-Content -Path $LogFile -Value "[$timestamp] $Message"

          Add-Content -Path $LogFile -Value $Message
        }

        try {
          $idleTimeout = 8
          $lastDataTime = Get-Date
          # check if it can login
          # -> implement here
          while (((Get-Date) - $lastDataTime).TotalSeconds -lt $idleTimeout) 
          {
            $data = $port.ReadExisting()

            if ($data)
            {
                Write-Log "RX> $data"
                # Add-Content $LogFile $data
                Write-Host "RX> $data"
                $lastDataTime = Get-Date
                Write-Host "The device is not ready to config, please try again later" -ForegroundColor Red
                exit 1
            }
            #if data exist before starting the process means it is booting
            # hence terminate the process as it won't start properly
          }

          # Send username
          $port.WriteLine("root")
          Start-Sleep 1

          # Send password
          $port.WriteLine("thalesSDR")
          Start-Sleep 1

          Write-Host "Connected to COM1"

          $data = $port.ReadExisting()

          # check which mru side is connected
          # ----------------------------------------------------------------------------------------------------------
          $port.Write("if [ -f /etc/trusted ]; then echo 'TRUSTED'; elif [ -f /etc/untrusted ]; then echo 'UNTRUSTED'; else echo 'UNKNOWN'; fi`r")
          Start-Sleep 2
          $data = $port.ReadExisting()
          $configuringMRUSide = "UNKNOWN"
          $lines = $data -split "`r?`n"
          $untrustedMatches = $lines | Where-Object {$_ -match "^UNTRUSTED"}
          $trustedMatches = $lines | Where-Object {$_ -match "^TRUSTED"}
          if($untrustedMatches.Count -eq 1)
          {
            $configuringMRUSide = "UNTRUSTED"
          }
          elseif($trustedMatches.Count -eq 1)
          {
            $configuringMRUSide = "TRUSTED"
          }

          if ($mruSide -match "a" -and $configuringMRUSide -eq "UNTRUSTED")
          {
            Write-Host "Good Job! you are configuring the UNTRUSTED side" -ForegroundColor Green
          }
          elseif ($mruSide -match "b" -and $configuringMRUSide -eq "TRUSTED")
          {
            Write-Host "Good Job! you are configuring the TRUSTED side" -ForegroundColor Green
          }
          else
          {
             Write-Host "You got the wrong side, this is the ${configuringMRUSide} side, please try again on the other side!!!" -ForegroundColor Red
             Write-Error "Configure-Wrong-MRU-side"
             $port.WriteLine("exit")
             exit 1
          }
          # ----------------------------------------------------------------------------------------------------------
          # Check trusted, untrusted and certs folder exist
  

          # ----------------------------------------------------------------------------------------------------------
          foreach ($cmd in $Commands) {
            if ($copyCert -eq "n")
            {
                if ($cmd -like "cp /mnt/usb/certs/*")
                {
                    continue
                }
                if ($cmd -like "openssl x509 -in /mnt/data/etc/certs/local.crt -noout*")
                {
                    continue
                }

            }

            # confirm USB is mounted after inserted
            if ($cmd -eq "mount /mnt/usb")
            {
                Start-Sleep 10
            }

            Write-Log "TX> $cmd"
            #Write-Log $cmd
            Write-Host "TX> $cmd" -ForegroundColor Cyan

            try{
                $port.WriteLine($cmd)
            }
            catch {
                Write-Log "TX> Connection lost while sending '$cmd'"
                Write-Host "Connection lost while sending '$cmd'"  -ForegroundColor Red
                break
            }

            # it takes time to copy a lot of files from trusted/untrusted folder
            if ($cmd -like "cp -p -r*")
            {
                Start-Sleep 40
            }
            Start-Sleep 5

            $lastDataTime = Get-Date
        # -----------------------------------------------------------------------
            while (((Get-Date) - $lastDataTime).TotalSeconds -lt $idleTimeout) 
            {
                $data = $port.ReadExisting()

                if ($cmd -eq "./reboot.sh" -and $data -match "\(y/N\)")
                {
                    $port.Write("y`r")
                }

                if ($data.Length -gt 0)
                {
                    Write-Log "RX> $data"
                    # Add-Content $LogFile $data
                    Write-Host "RX> $data"
                    $lastDataTime = Get-Date
                }

                # Verify usb is mounted
                if ($cmd -eq "lsusb")
                {
                    $lines = $data -split "`r?`n"
                    $matches = $lines | Where-Object {$_ -match "Bus 001 Device \d{3}:"}
                    if($matches.Count -eq 2) {
                        Write-Host "USB Exists" -ForegroundColor Green
                        Start-Sleep 5
                        break
                    }
                    elseif($matches.Count -lt 2) 
                    {
                        Start-Sleep 5
                        Write-Host "USB not exist" -ForegroundColor Red
                        Write-Error "USB not exist"
                        Write-Log "TX> exit"
                        Write-Host "TX> exit"
                        $port.WriteLine("exit")
                        exit 1
                    }
                }

                if ($cmd -eq "mount /mnt/usb")
                {
                  if ($mruSide -match "a")
                  {
                      $port.Write("test -d '/mnt/usb/untrusted' && echo 'Exists' || echo 'Untrusted Folder Not Exist'`r")
                      Start-Sleep 2
                      $data = $port.ReadExisting()
                      $lines = $data -split "`r?`n"

                      $untrustedFolderNotExist = $lines | Where-Object {$_ -match "^Untrusted Folder Not Exist"}

                      if($untrustedFolderNotExist.Count -gt 0)
                      {
                        Write-Host "Untrusted folder not exist" -ForegroundColor Red
                        Write-Error "Untrusted folder not exist"
                        Write-Log "TX> exit"
                        Write-Host "TX> exit"
                        $port.WriteLine("exit")
                        exit 1
                      }
                  }
                  elseif ($mruSide -match "b")
                  {
                    $port.Write("test -d '/mnt/usb/trusted' && echo 'Exists' || echo 'Trusted Folder Not Exist'`r")
                    $port.Write("test -d '/mnt/usb/certs/MRU${trainId}${cab}' && echo 'Exists' || echo 'Certs/TrainId Folder Not Exist'`r")
                    Start-Sleep 2
                      $data = $port.ReadExisting()
                      $lines = $data -split "`r?`n"
                    $trustedFolderNotExist = $lines | Where-Object {$_ -match "^Trusted Folder Not Exist"}
                    $certsFolderNotExist = $lines | Where-Object {$_ -match "^Certs/TrainId Folder Not Exist"}

                    if($trustedFolderNotExist.Count -gt 0)
                    {
                      Write-Host "Trusted folder not exist" -ForegroundColor Red
                      Write-Error "Trusted folder not exist"
                      Write-Log "TX> exit"
                      Write-Host "TX> exit"
                      $port.WriteLine("exit")
                      exit 1
                    }

                      if($certsFolderNotExist.Count -gt 0)
                      {
                        Write-Host "Certs/TrainId folder not exist" -ForegroundColor Red
                        Write-Error "Certs/TrainId folder not exist"
                        Write-Log "TX> exit"
                        Write-Host "TX> exit"
                        $port.WriteLine("exit")
                        exit 1
                      }
                  }
                  break
                }

                if ($data -match "mount: mounting /dev/sda1 on /mnt/usb failed: No such device or address")
                {
                    Write-Host "USB device is not mounted." -ForegroundColor Red
                    Write-Error "USB device is not mounted."
                    $port.WriteLine("exit")
                    exit 1
                }

                if ($cmd -eq "openssl x509 -in /mnt/data/etc/certs/local.crt -noout -text |more")
                {
                    $port.Write(" ")
                    Start-Sleep -Milliseconds 100
                    $port.Write(" ")
                    Start-Sleep -Milliseconds 100
                    $data = $port.ReadExisting()

                    if ($data.Length -gt 0)
                    {
                        Write-Log "RX> $data"
                        # Add-Content $LogFile $data
                        Write-Host "RX> $data"
                        $lastDataTime = Get-Date
                    }
                    break
                }

                if ($cmd -eq "openssl x509 -in /mnt/data/etc/certs/local.crt -noout -text | grep 'IP Address'")
                {
                    if ($cab -match "a" -and $data -notmatch "172.22.208.${trainId}")
                    {
                        Write-Log "You got the WRONG Cert. The correct cert should be 172.22.208.${trainId}"
                        # Add-Content $LogFile $data
                        Write-Host "You got the WRONG Cert. The correct cert should be 172.22.208.${trainId}" -ForegroundColor Red
                    }
                    elseif ($cab -match "b" -and $data -notmatch "172.22.209.${trainId}")
                    {
                        Write-Log "You got the WRONG Cert. The correct cert should be 172.22.209.${trainId}"
                        # Add-Content $LogFile $data
                        Write-Host "You got the WRONG Cert. The correct cert should be 172.22.209.${trainId}" -ForegroundColor Red
                    }
                    else
                    {
                        Write-Log "You got the CORRECT Cert. Great JOB!"
                        # Add-Content $LogFile $data
                        Write-Host "You got the CORRECT Cert. Great JOB!" -ForegroundColor Green
                    }

                    break
                }

                if ($data -match "Hit any key to stop autoboot")
                {
                    $port.Write("`r")
                    Start-Sleep 5
                    $port.WriteLine("boot")
                }
        
                Start-Sleep -Milliseconds 100
            }
    

        # -----------------------------------------------------------------------
          }

          exit 0
        } 
        Catch
        {
          Write-Host "An error occurred: $_" -ForegroundColor Red
          exit 1
        }
        finally{
          if ($port.IsOpen) {
            $port.Close()
          }

          Write-Host "Exit with exitcode $LASTEXITCODE."
          Write-Host "Press Enter to exit" -ForegroundColor Green
          Read-Host
        }
        break
    }
    default 
    {
    Write-Host "Please enter a valid option!" -ForegroundColor Red
    Read-Host
    }
}
$continueUseMRUTool = Read-Host "Continue? (y/N)"
if($continueUseMRUTool -match "y") {continue}
else{$usingMRUTool = $false}

}