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
echo Loco Train Eternet Port IP configuration Script v1.0
echo =====================================================
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
  echo Requesting administrative privileges...
  powershell -Command "Start-Process '%~f0' -Verb RunAs"
  exit
)

echo =====================================================
echo Loco Train Eternet Port IP configuration Script v1.0
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

set /p trainId=Enter a train id (389-415): 

:: Validate input range, type A: 10.13.7.193, type B: 10.13.135.210
if %trainId% LSS 389 goto invalid
if %trainId% GTR 415 goto invalid


echo.
echo Setting new static IP...

REM Set IP and subnet ONLY
netsh interface ip set address name=%INTERFACE_NAME% source=static addr=10.14.6.24 mask=255.255.0.0

netsh interface ipv4 add address %INTERFACE_NAME% 10.88.1.60 255.252.0.0

netsh interface ipv4 add address %INTERFACE_NAME% 10.80.0.224 255.255.224.0

netsh interface ipv4 add address %INTERFACE_NAME% 10.0.96.232 255.255.224.0

netsh interface ipv4 add address %INTERFACE_NAME% 10.4.96.232 255.255.224.0
netsh interface ipv4 add address %INTERFACE_NAME% 10.8.96.232 255.252.0.0

echo IP configured 10.14.6.24 255.255.0.0
echo IP configured 10.88.1.60 255.252.0.0
echo IP configured 10.80.0.224 255.255.224.0
echo IP configured 10.0.96.232 255.255.224.0
echo IP configured 10.4.96.232 255.255.224.0
echo IP configured 10.8.96.232 255.252.0.0
goto end

:invalid
echo Invalid input. Please enter an integer between 389 and 415.

:end
pause