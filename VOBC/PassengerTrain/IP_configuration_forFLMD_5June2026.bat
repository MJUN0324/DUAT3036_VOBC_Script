@echo off

REM =====================================================
REM Trainborne Eternet Port IP configuration Script
REM =====================================================
REM Purpose   : configure FLMD Ethernet IP configuration
REM
REM Author    : MIYAJIMA Jun
REM Team      : Customer Support
REM Version   : v1.0
REM Created   : 2026-06-05
REM
REM Notes:
REM - Require administrative privileges
REM - The script must wipe out the current Ethernet IPs
REM   to execute.
REM =====================================================


REM =====================================================
REM Change History
REM =====================================================
REM v1.0  2026-06-05  Initial version
REM =====================================================

echo =====================================================
echo Trainborne Eternet Port IP configuration Script v1.0
echo =====================================================
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
  echo Requesting administrative privileges...
  powershell -Command "Start-Process '%~f0' -Verb RunAs"
  exit
)

echo =====================================================
echo Trainborne Eternet Port IP configuration Script v1.0
echo =====================================================
echo.

set INTERFACE_NAME="Ethernet"


echo This will remove ALL IPv4 addresses from the "Ethernet" interface.
echo.
set /p choice=Are you sure you want to continue? (Y/N): 

if /I "%choice%"=="Y" goto delete
if /I "%choice%"=="YES" goto delete

echo Operation cancelled.
goto end


:delete
echo.
echo Removing IP configuration...

:: Set interface to DHCP (removes static IPs)
netsh interface ip set address name="Ethernet" source=dhcp

:: Optionally clear DNS settings too
netsh interface ip set dns name="Ethernet" source=dhcp

set /p trainNo=Enter a train id (1-129): 

:: Validate input range, type A: 10.13.7.193, type B: 10.13.135.210
if %trainNo% LSS 1 goto invalid
if %trainNo% GTR 129 goto invalid


set trainId=%trainNo%


set /a thirdOctetTypeA=((trainId-1)*64+2)/256

:: echo Third Octet Type A: %thirdOctetTypeA%

set /a fourthOctetTypeA=((trainId-1)*64+18)%%256 + 1

:: echo Fourth Octet Type A: %fourthOctetTypeA%
::------------------------------------------------------------
set /a thirdOctetTypeB=((trainId-1)*64+2)/256 + 128

:: echo Third Octet Type B: %thirdOctetTypeB%

set /a fourthOctetTypeB=((trainId-1)*64+18)%%256 + 1

:: echo Fourth Octet Type B: %fourthOctetTypeB%


echo.
echo Setting new static IP...

REM Set IP and subnet ONLY
netsh interface ip set address name=%INTERFACE_NAME% source=static addr=10.14.6.24 mask=255.255.0.0

:: TYPE B

set "ipB=10.13.134.60"

for /f "tokens=1,2 delims=." %%a in ("%ipB%") do (
    set newipTypeB=%%a.%%b.%thirdOctetTypeB%.%fourthOctetTypeB%
)

netsh interface ipv4 add address %INTERFACE_NAME% %newipTypeB% 255.255.255.192

:: TYPE A
set "ipA=10.13.6.60"
for /f "tokens=1,2 delims=." %%a in ("%ipA%") do (
    set newipTypeA=%%a.%%b.%thirdOctetTypeA%.%fourthOctetTypeA%
)
netsh interface ipv4 add address %INTERFACE_NAME% %newipTypeA% 255.255.255.192

netsh interface ipv4 add address %INTERFACE_NAME% 10.88.1.60 255.252.0.0

netsh interface ipv4 add address %INTERFACE_NAME% 10.80.0.224 255.255.224.0

netsh interface ipv4 add address %INTERFACE_NAME% 10.0.96.232 255.255.224.0

netsh interface ipv4 add address %INTERFACE_NAME% 10.4.96.232 255.255.224.0
netsh interface ipv4 add address %INTERFACE_NAME% 10.8.96.232 255.252.0.0

echo IP configured 10.14.6.24 255.255.0.0
echo IP configured %newipTypeB% 255.255.255.192
echo IP configured %newipTypeA% 255.255.255.192
echo IP configured 10.88.1.60 255.252.0.0
echo IP configured 10.80.0.224 255.255.224.0
echo IP configured 10.0.96.232 255.255.224.0
echo IP configured 10.4.96.232 255.255.224.0
echo IP configured 10.8.96.232 255.252.0.0
goto end

:invalid
echo Invalid input. Please enter an integer between 1 and 129.

:end
pause