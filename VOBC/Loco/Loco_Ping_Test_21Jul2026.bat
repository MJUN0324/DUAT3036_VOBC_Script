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
REM Version   : v1.1
REM Created   : 2026-06-12
REM
REM Notes:
REM - Success criteria = Received packets >= 3
REM - Output log saved to ping_result.txt
REM =====================================================


REM =====================================================
REM Change History
REM =====================================================
REM v1.0  2026-06-12  Initial version
REM v1.1  2026-07-21  Added MRU selection (less IP ping)
REM =====================================================

echo =====================================================
echo Loco Trainborne Ping Test Automation Script v1.1
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


set /p trainId=Enter a train id (389-415): 
echo. 
REM Validate input range
if %trainId% LSS 389 goto end
if %trainId% GTR 415 goto end


set /a thirdOctet=((trainId-1)*64+2)/256
set /a fourthOctet=((trainId-1)*64+2)%%256
set "VOBC1R1=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+2)/256+128
set /a fourthOctet=((trainId-1)*64+2)%%256
set "VOBC1R2=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+5)/256
set /a fourthOctet=((trainId-1)*64+5)%%256
set "LDCEth1=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+5)/256+128
set /a fourthOctet=((trainId-1)*64+5)%%256
set "LDCEth2=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+3)/256
set /a fourthOctet=((trainId-1)*64+3)%%256
set "STODEth1=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-1)*64+3)/256+128
set /a fourthOctet=((trainId-1)*64+3)%%256
set "STODEth2=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-195)*64+1)/256
set /a fourthOctet=((trainId-195)*64+1)%%256
set "MRU1=10.14.%thirdOctet%.%fourthOctet%"

set /a thirdOctet=((trainId-195)*64+1)/256+128
set /a fourthOctet=((trainId-195)*64+1)%%256
set "MRU2=10.14.%thirdOctet%.%fourthOctet%"

REM ---------------------------------------------------------------------------------------------------------

echo Select Current MRU:
echo [1] MRU1
echo [2] MRU2
set /p mru_selection=Enter selection (1-2):
echo.
if "%mru_selection%" EQU "1" goto setA
if "%mru_selection%" EQU "2" goto setB 
goto end

:setA
set IPS="VOBC1R1=%VOBC1R1%" "LDCEth1=%LDCEth1%" "STODEth1=%STODEth1%" "MRU1=%MRU1%"
goto ping

:setB
set IPS="VOBC1R2=%VOBC1R2%" "LDCEth2=%LDCEth2%" "STODEth2=%STODEth2%" "MRU2=%MRU2%" 
goto ping

:ping
echo.
echo Pinging selected IPs...
echo.

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
set NEW_FILE=%DEST_FOLDER%\TrainId%trainId%_%yyyy%%mm%%dd%_%hh%%min%%ss%.txt

REM Copy and rename
copy "%SOURCE_FILE%" "%NEW_FILE%" >nul

echo File copied to %NEW_FILE%

REM ---------------------------------------------------------------------------------------------------------
if exist summary_ping.bat (
  echo.
  echo Generating Summary...
  echo.
  echo Train ID: %trainId%
  echo MRU: MRU%mru_selection%
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
