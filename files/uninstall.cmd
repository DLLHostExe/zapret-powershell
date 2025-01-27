@echo off

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo - You must run this script with administrative privileges to continue.
    exit /b
)

for /f "tokens=*" %%a in ('netsh interface show interface ^| findstr /i "Ethernet"') do (
    set adapter=%%a
    set adapter=!adapter:~0,15!
    netsh interface ipv4 set address name="!adapter!" source=dhcp >nul 2>&1
    netsh interface ipv6 set address name="!adapter!" source=dhcp >nul 2>&1
)

netsh interface ipv6 set teredo disabled >nul 2>&1

for /f "delims=" %%i in ('findstr /i "C:\\Windows\\Zapret\\canary-hosts" C:\\Windows\\System32\\drivers\\etc\\hosts') do (
    set "line=%%i"
    setlocal enabledelayedexpansion
    set "line=!line:C:\Windows\Zapret\canary-hosts=!"
    echo !line!>> C:\Windows\System32\drivers\etc\hosts.new
    endlocal
)

move /y C:\Windows\System32\drivers\etc\hosts.new C:\Windows\System32\drivers\etc\hosts >nul 2>&1

net stop winws1 >nul 2>&1
net stop windivert >nul 2>&1
net stop windivert14 >nul 2>&1
sc stop zapret >nul 2>&1
sc stop windivert >nul 2>&1
sc stop windivert14 >nul 2>&1
sc delete winws1 >nul 2>&1
sc delete windivert >nul 2>&1
sc delete windivert14 >nul 2>&1

for %%f in (C:\Windows\Zapret\*) do (
    if /i not "%%~xf"==".txt" del /f "%%f" >nul 2>&1
)

echo - Done
