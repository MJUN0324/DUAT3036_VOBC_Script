@echo off
setlocal enabledelayedexpansion

REM =====================================================
REM Trainborne Ping Test Summary Script
REM =====================================================
REM Purpose   : generate summary result table
REM
REM Author    : MIYAJIMA Jun
REM Team      : Customer Support
REM Version   : v1.1
REM Created   : 2026-06-09
REM
REM Notes:
REM - Output log read from ping_result.txt
REM =====================================================


REM =====================================================
REM Change History
REM =====================================================
REM v1.0  2026-06-09  Initial version
REM v1.1  2026-06-10  Handled Destination Host Unreachab^
REM le packets count as invalid packets
REM =====================================================

set INPUT_FILE=ping_result.txt

if not exist "%INPUT_FILE%" (
    echo File not found: %INPUT_FILE%
    pause
    exit /b
)

powershell -Command "(Get-Content %INPUT_FILE%) -replace '<','-' | Set-Content %INPUT_FILE%"

echo ---------------------------------------------------------------
echo ^| Component              ^| Ping Test Result   ^| Result        ^|
echo ---------------------------------------------------------------

for /f "delims=" %%L in (%INPUT_FILE%) do (

    set LINE=%%L

    REM -------------------------------------------------
    REM Skip reply lines containing time^<1ms
    REM -------------------------------------------------


    REM --------------------------------------------
    REM Extract Component
    REM --------------------------------------------

    echo !LINE! | findstr /B /C:"Pinging:" >nul

    if !errorlevel! == 0 (

        set "UNREACHABLE=0"

        REM Remove leading text
        set FULL=!LINE:Pinging: "=!

        REM Remove ending quote
        set FULL=!FULL:"=!

        REM Get component before =
        for /f "tokens=1 delims==" %%A in ("!FULL!") do (
            set COMPONENT=%%A
        )

        REM echo LINE: !LINE!
        REM echo FULL: !FULL!
        REM echo COMPONENT: !COMPONENT!
    )

    
    REM -------------------------------------------------
    REM Detect Destination Host Unreachable
    REM -------------------------------------------------

    echo !LINE! | findstr /I /C:"Destination host unreachable" >nul

    if !errorlevel! == 0 (
        set /a UNREACHABLE+=1
    )


    REM --------------------------------------------
    REM Extract Ping Statistics
    REM --------------------------------------------

    echo !LINE! | findstr /C:"Packets:" >nul

    if !errorlevel! == 0 (

        for /f "tokens=3,5 delims==, " %%A in ("!LINE!") do (
            set SENT=%%A
            set RECEIVED=%%B
        )
       
        REM Remove spaces
        set SENT=!SENT: =!
        set RECEIVED=!RECEIVED: =!


        REM ---------------------------------------------
        REM Exclude Destination Host Unreachable count
        REM ---------------------------------------------

        set /a VALIDRECEIVED=!RECEIVED!-!UNREACHABLE!

        if !VALIDRECEIVED! LSS 0 (
            set VALIDRECEIVED=0
        )


        REM ---------------------------------------------
        REM Determine Result
        REM ---------------------------------------------

        if !VALIDRECEIVED! GEQ 3 (
            set RESULT=Success
        ) else (
            set RESULT=Fail
        )

        set PINGRESULT=!VALIDRECEIVED! out of !SENT!
        
        :Row
        set "C1=!COMPONENT!                    "
        set "C2=!PINGRESULT!                    "
        set "C3=!RESULT!          "

        echo ^| !C1:~0,22! ^| !C2:~0,18! ^| !C3:~0,13! ^|

        REM echo ^| !COMPONENT! ^| !RECEIVED! out of !SENT! ^| !RESULT! ^|
    )
)

echo ---------------------------------------------------------------

echo.


for /f %%a in ('powershell -command "(Get-Item \"%INPUT_FILE%\").CreationTime.ToString(\"yyyyMMdd\")"') do set filecreationdate=%%a

echo Creation date: %filecreationdate% (yyyyMMdd)
pause