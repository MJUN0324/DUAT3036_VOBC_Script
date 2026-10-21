@echo off
setlocal enabledelayedexpansion

REM =====================================================
REM Trainborne Ping Test Automation Script
REM =====================================================
REM Purpose   : Execute component ping test and
REM             generate summary result table
REM
REM Author    : MIYAJIMA Jun
REM Team      : Customer Support
REM Version   : v1.4
REM Created   : 2026-06-09
REM
REM Notes:
REM - Success criteria = Received packets >= 3
REM - Output log saved to ping_result.txt
REM =====================================================


REM =====================================================
REM Change History
REM =====================================================
REM v1.0  2026-06-05  Initial version
REM v1.1  2026-06-09  Added summary table
REM v1.2  2026-06-10  Modified user input message
REM v1.3  2026-06-11  Added backup ping test result
REM v1.4  2026-06-30  Added Q-Train IP
REM =====================================================

echo =====================================================
echo Trainborne Ping Test Automation Script v1.4
echo =====================================================
echo.
REM Output file
set OUTPUT=ping_result.txt

REM Clear old result
if exist %OUTPUT% del %OUTPUT%

if not exist %OUTPUT% (
    type nul > %OUTPUT%
    powershell -command "(Get-Item '%OUTPUT%').CreationTime = Get-Date"
)


set /p trainId=Enter a train id (1-129): 

REM Validate input range
if %trainId% LSS 1 goto end
if %trainId% GTR 129 goto end

set /a thirdOctet=((trainId-1)*128+2)/256
set /a fourthOctet=((trainId-1)*128+2)%%256
set "VOBC1R1=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*128+2)/256+128
set /a fourthOctet=((trainId-1)*128+2)%%256
set "VOBC1R2=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+6)/256
set /a fourthOctet=((trainId-1)*64+6)%%256
set "VOBC1RIOL=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+6+64)/256
set /a fourthOctet=((trainId-1)*64+7+64)%%256
set "VOBC1RIOR=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*128+5)/256
set /a fourthOctet=((trainId-1)*128+5)%%256
set "VOBC1LDCEth1=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*128+5)/256+128
set /a fourthOctet=((trainId-1)*128+5)%%256
set "VOBC1LDCEth2=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+4)/256
set /a fourthOctet=((trainId-1)*64+4)%%256
set "VOBC1PTODEth1=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+4)/256+128
set /a fourthOctet=((trainId-1)*64+4)%%256
set "VOBC1PTODEth2=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+3)/256
set /a fourthOctet=((trainId-1)*64+3)%%256
set "VOBC1STODEth1=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+3)/256+128
set /a fourthOctet=((trainId-1)*64+3)%%256
set "VOBC1STODEth2=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*128+2)/256
set /a fourthOctet=((trainId-1)*128+2+64)%%256
set "VOBC2R1=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*128+2)/256+128
set /a fourthOctet=((trainId-1)*128+2+64)%%256
set "VOBC2R2=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+6+64)/256+128
set /a fourthOctet=((trainId-1)*64+6+64)%%256
set "VOBC2RIOL=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+6)/256+128
set /a fourthOctet=((trainId-1)*64+7)%%256
set "VOBC2RIOR=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*128+5)/256
set /a fourthOctet=((trainId-1)*128+5+64)%%256
set "VOBC2LDCEth1=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*128+5)/256+128
set /a fourthOctet=((trainId-1)*128+5+64)%%256
set "VOBC2LDCEth2=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+4)/256
set /a fourthOctet=((trainId-1)*64+4+32)%%256
set "VOBC2PTODEth1=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+4)/256+128
set /a fourthOctet=((trainId-1)*64+4+32)%%256
set "VOBC2PTODEth2=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+3)/256
set /a fourthOctet=((trainId-1)*64+3+32)%%256
set "VOBC2STODEth1=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+3)/256+128
set /a fourthOctet=((trainId-1)*64+3+32)%%256
set "VOBC2STODEth2=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+1)/256+128
set /a fourthOctet=((trainId-1)*64+1)%%256
set "UpCabMRU=10.13.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+2)/256+128
set /a fourthOctet=((trainId-1)*64+16)%%256
set "UpCabNS1=10.13.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+2)/256
set /a fourthOctet=((trainId-1)*64+16)%%256
set "UpCabNS2=10.13.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+2)/256+128
set /a fourthOctet=((trainId-1)*64+18)%%256
set "UpCabNS1Repeater=10.13.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+2)/256
set /a fourthOctet=((trainId-1)*64+18)%%256
set "UpCabNS2Repeater=10.13.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+2)/256
set /a fourthOctet=((trainId-1)*64+15)%%256
set "DownCabNS1=10.13.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+2)/256+128
set /a fourthOctet=((trainId-1)*64+15)%%256
set "DownCabNS2=10.13.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+2)/256
set /a fourthOctet=((trainId-1)*64+17)%%256
set "DownCabNS1Repeater=10.13.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+2)/256+128
set /a fourthOctet=((trainId-1)*64+17)%%256
set "DownCabNS2Repeater=10.13.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+1)/256
set /a fourthOctet=((trainId-1)*64+1)%%256
set "DownCabMRU=10.13.%thirdOctet%.%fourthOctet%"
REM ---------------------------------------------------------------------------------------------------------

REM set /p cab=Enter which cab are you in DOWN cab or UP cab (1-2):
echo. 
echo Select Current Cab:
echo [1] DOWN Cab
echo [2] UP Cab
set /p cab=Enter selection (1-2):
echo.
echo Select Connected Network Switch:
echo [1] Network Switch 1
echo [2] Network Switch 2
set /p choice=Enter selection (1-2):
REM set /p choice=Enter which Network Switch are you connected, NS1 or NS2 (1-2): 

if "%cab%"=="1" (
  if "%choice%"=="1" (
    if %trainId% LEQ 36 goto setA
    if %trainId% GEQ 37 goto setC
  )
  if "%choice%"=="2" (
    if %trainId% LEQ 36 goto setB
    if %trainId% GEQ 37 goto setD
  ) 
  echo Invalid choice.
  goto end
) 

if "%cab%"=="2" (
  if "%choice%"=="1" (
    if %trainId% LEQ 36 goto setB
    if %trainId% GEQ 37 goto setD
  )
  if "%choice%"=="2" (
    if %trainId% LEQ 36 goto setA
    if %trainId% GEQ 37 goto setC
  )

  echo Invalid choice.
  goto end
) else (
  echo Invalid choice.
  goto end
)

:setA
REM this set of IP is applicable for DOWN cab NS1 and UP cab NS2 
REM ping to UP cab Network Switch 2
REM set IPS=%VOBC1R1% %VOBC2R2% %VOBC1RIOL% %VOBC2RIOR% %VOBC1LDCEth1% %VOBC2LDCEth2% 
REM set IPS=%IPS% %VOBC1PTODEth1% %VOBC2PTODEth2% %VOBC1STODEth1% %VOBC2STODEth2% 
REM set IPS=%IPS% %DownCabMRU% %UpCabNS1% %DownCabNS2% %DownCabNS1Repeater% %UpCabNS2Repeater%


set IPS="VOBC1R1=%VOBC1R1%" "VOBC2R2=%VOBC2R2%" "VOBC1RIOL=%VOBC1RIOL%" "VOBC2RIOR=%VOBC2RIOR%" "VOBC1LDCEth1=%VOBC1LDCEth1%" "VOBC2LDCEth2=%VOBC2LDCEth2%"
set IPS=%IPS% "VOBC1PTODEth1=%VOBC1PTODEth1%" "VOBC2PTODEth2=%VOBC2PTODEth2%" "VOBC1STODEth1=%VOBC1STODEth1%" "VOBC2STODEth2=%VOBC2STODEth2%"
set IPS=%IPS% "DownCabMRU=%DownCabMRU%" "DownCabNS1=%DownCabNS1%" "UpCabNS2=%UpCabNS2%" "DownCabNS1Repeater=%DownCabNS1Repeater%" "UpCabNS2Repeater=%UpCabNS2Repeater%"

goto ping

:setB
REM this set of IP is applicable for UP cab NS1 and DOWN cab NS2 
REM ping to UP cab Network Switch 1
REM set IPS=%VOBC2R1% %VOBC1R2% %VOBC2RIOL% %VOBC1RIOR% %VOBC2LDCEth1% %VOBC1LDCEth2% 
REM set IPS=%IPS% %VOBC2PTODEth1% %VOBC1PTODEth2% %VOBC2STODEth1% %VOBC1STODEth2%
REM set IPS=%IPS% %UpCabMRU% %UpCabNS1% %DownCabNS2% %UpCabNS1Repeater% %DownCabNS2Repeater%

set IPS="VOBC2R1=%VOBC2R1%" "VOBC1R2=%VOBC1R2%" "VOBC2RIOL=%VOBC2RIOL%" "VOBC1RIOR=%VOBC1RIOR%" "VOBC2LDCEth1=%VOBC2LDCEth1%" "VOBC1LDCEth2=%VOBC1LDCEth2%"
set IPS=%IPS% "VOBC2PTODEth1=%VOBC2PTODEth1%" "VOBC1PTODEth2=%VOBC1PTODEth2%" "VOBC2STODEth1=%VOBC2STODEth1%" "VOBC1STODEth2=%VOBC1STODEth2%"
set IPS=%IPS% "UpCabMRU=%UpCabMRU%" "UpCabNS1=%UpCabNS1%" "DownCabNS2=%DownCabNS2%" "UpCabNS1Repeater=%UpCabNS1Repeater%" "DownCabNS2Repeater=%DownCabNS2Repeater%"
goto ping

:setC
REM this set of IP is applicable for Q-Train DOWN cab NS1 and UP cab NS2 
REM ping to DOWN cab Network Switch 2
REM set IPS=%VOBC1R1% %VOBC1R2% %VOBC1RIOL% %VOBC1RIOR% %VOBC1LDCEth1% %VOBC1LDCEth2% 
REM set IPS=%IPS% %VOBC1PTODEth1% %VOBC1PTODEth2% %VOBC1STODEth1% %VOBC1STODEth2%
REM set IPS=%IPS% %UpCabMRU% %DownCabNS2%
set IPS="VOBC1R1=%VOBC1R1%" "VOBC2R2=%VOBC2R2%" "VOBC1RIOL=%VOBC1RIOL%" "VOBC2RIOR=%VOBC2RIOR%" "VOBC1LDCEth1=%VOBC1LDCEth1%" "VOBC2LDCEth2=%VOBC2LDCEth2%"
set IPS=%IPS% "VOBC1STODEth1=%VOBC1STODEth1%" "VOBC2STODEth2=%VOBC2STODEth2%"
set IPS=%IPS% "DownCabMRU=%DownCabMRU%" "DownCabNS1=%DownCabNS1%" "UpCabNS2=%UpCabNS2%" "DownCabNS1Repeater=%DownCabNS1Repeater%" "UpCabNS2Repeater=%UpCabNS2Repeater%"
goto ping

:setD
REM this set of IP is applicable for Q-Train UP cab NS1 and DOWN cab NS2 
REM ping to DOWN cab Network Switch 1
REM set IPS=%VOBC1R1% %VOBC1R2% %VOBC1RIOL% %VOBC1RIOR% %VOBC1LDCEth1% %VOBC1LDCEth2% 
REM set IPS=%IPS% %VOBC1PTODEth1% %VOBC1PTODEth2% %VOBC1STODEth1% %VOBC1STODEth2%
REM set IPS=%IPS% %UpCabMRU% %DownCabNS1%

set IPS="VOBC2R1=%VOBC2R1%" "VOBC1R2=%VOBC1R2%" "VOBC2RIOL=%VOBC2RIOL%" "VOBC1RIOR=%VOBC1RIOR%" "VOBC2LDCEth1=%VOBC2LDCEth1%" "VOBC1LDCEth2=%VOBC1LDCEth2%"
set IPS=%IPS% "VOBC2STODEth1=%VOBC2STODEth1%" "VOBC1STODEth2=%VOBC1STODEth2%"
set IPS=%IPS% "UpCabMRU=%UpCabMRU%" "UpCabNS1=%UpCabNS1%" "DownCabNS2=%DownCabNS2%" "UpCabNS1Repeater=%UpCabNS1Repeater%" "DownCabNS2Repeater=%DownCabNS2Repeater%"
goto ping

:ping
echo.
echo Pinging selected IPs...
echo.

REM for %%i in (%IPS%) do (
    REM echo Pinging %%i ...
    REM ping -n 4 %%i 
    REM >nul
    REM if errorlevel 1 (
    REM     echo %%i - FAILED
    REM ) else (
    REM     echo %%i - SUCCESS
    REM )
REM    echo.
REM )

for %%A in (!IPS!) do (
    set "pair=%%~A"
    REM echo Pinging: %%A >> %OUTPUT%
    REM echo. >> %OUTPUT%

    
    call :WriteLine Pinging: %%A
    echo. >> %OUTPUT%
    echo.

    for /f "tokens=1,2 delims==" %%B in ("!pair!") do (
        set NAME=%%B
        set IP=%%C
   
        REM ping -n 4 !IP! >> %OUTPUT%
        
        for /f "delims=" %%P in ('ping !IP! -n 4') do (
            echo %%P
            echo %%P>>%OUTPUT%
        )

REM        echo Pinging !NAME! !IP!
REM        echo Name: !NAME!
REM        echo IP: !IP!
        REM echo ---------------- >> %OUTPUT%
        call :WriteLine ---------------
    )
  echo.
)
REM ---------------------------------------------------------------------------------------------------------
REM Copy Ping Test Result to another folder
REM Set source file path
set SOURCE_FILE=.\%OUTPUT%

REM Set destination folder
set DEST_FOLDER=.\Ping Test Results

REM Create folder if it doesn't exist
if not exist "%DEST_FOLDER%" mkdir "%DEST_FOLDER%"

REM Get current date and time (formatted)
for /f "tokens=1-3 delims=/" %%a in ("%date%") do (
    set yyyy=%%c
    set mm=%%a
    set dd=%%b
)

for /f "tokens=1-3 delims=:." %%a in ("%time%") do (
    set hh=%%a
    set min=%%b
    set ss=%%c
)

REM Clean leading space in hour
set hh=%hh: =0%

REM Build new file name
set NEW_FILE=%DEST_FOLDER%\TrainId%trainId%_VOBC%cab%_NS%choice%_%yyyy%%mm%%dd%_%hh%%min%%ss%.txt

REM Copy and rename
copy "%SOURCE_FILE%" "%NEW_FILE%" >nul

echo File copied to %NEW_FILE%

REM ---------------------------------------------------------------------------------------------------------
if exist summary_ping.bat (
  echo.
  echo Generating Summary...
  echo.
  echo Train ID: %trainId%
  if %cab%==1 (
    echo DOWN Cab
  )
  if %cab%==2 (
    echo UP Cab
  )
  if %choice%==1 (
    echo Network Switch 1
  )
  if %choice%==2 (
    echo Network Switch 2
  )
  call summary_ping.bat
) else (
  goto :end
)

:end
pause


:WriteLine
echo %*
echo %*>>%OUTPUT%
exit /b
