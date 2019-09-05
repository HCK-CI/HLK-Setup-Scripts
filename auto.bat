setlocal EnableDelayedExpansion
SET PASSWORD=Qum5net.
SET "FILTERS=https://go.microsoft.com/fwlink/?linkid=875139"
SET KIT=HLK
:: SET KIT=HCK
SET HLKKITVER=1709
SET REMOVEGUI=false
SET DEBUG=false

call :Resume
goto %current%
goto :eof

:one
::Add script to Run key
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v %~n0 /d %~dpnx0 /f
echo two >%~dp0current.txt

echo Enabling Administrator account...
net user administrator /active:yes

echo Setting Administrator account password...
net user administrator "%PASSWORD%" 

echo Enabling auto-logon for Administrator...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoAdminLogon" /t REG_SZ /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultDomainName" /t REG_SZ /d "WORKGROUP" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultUserName" /t REG_SZ /d "Administrator" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassword" /t REG_SZ /d "%PASSWORD%" /f

if %DEBUG% equ true pause
shutdown -r -t 0
goto :eof

:two
echo three >%~dp0current.txt

echo Disabling Server Manager popup on startup...
reg add "HKLM\SOFTWARE\Microsoft\ServerManager" /v "DoNotOpenServerManagerAtLogon" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\ServerManager\Oobe" /v "DoNotOpenInitialConfigurationTasksAtLogon" /t REG_DWORD /d "1" /f

echo Disabling Windows Firewall...
netsh advfirewall set allprofiles state off
reg add "HKLM\SOFTWARE\Microsoft\Security Center" /v "FirewallDisableNotify" /t REG_DWORD /d "1" /f

echo Setting unidentified networks to Private Location...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\010103000F0000F0010000000F0000F0C967A3643C3AD745950DA7859209176EF5B87C875FA20DF21951640E807D7C24" /v "Category" /t REG_DWORD /d "1" /f

echo Disabling Windows Update...
sc config wuauserv start= disabled
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "AUOptions" /t REG_DWORD /d "1" /f

echo Disabling screensaver...
reg add "HKCU\Control Panel\Desktop" /v "ScreenSaveActive" /t REG_SZ /d "0" /f
reg add "HKCU\Control Panel\Desktop" /v "SCRNSAVE.EXE" /t REG_SZ /d "" /f

echo Disabling power saving options...
powercfg -change -monitor-timeout-ac 0
powercfg -change -disk-timeout-ac 0
powercfg -change -standby-timeout-ac 0
powercfg -hibernate off

echo Enabling powershell remoting...
timeout /t 30 /nobreak > NUL
powershell "Set-NetConnectionProfile -NetworkCategory Private"
cmd.exe /c winrm quickconfig -q
cmd.exe /c winrm set winrm/config "@{MaxTimeoutms="14400000"}"
cmd.exe /c winrm set winrm/config/service/auth "@{Basic="true"}"
cmd.exe /c winrm set winrm/config/service "@{AllowUnencrypted="true"}"

echo Renaming hostname to STUDIO
WMIC ComputerSystem where Name="%computername%" call Rename Name="STUDIO"

if %DEBUG% equ true pause
shutdown -r -t 0
goto :eof

:three
echo four >%~dp0current.txt

for /f "delims=" %%a in ('getmac /fo csv /nh /v') do (
    set line=%%a
    set line=!line:"=,!
    for /f "delims=,,, tokens=1,3" %%b in ("!line!") do (
        set name=%%b
        set mac=%%c
        if "!mac:~-2!"=="DD" (
            echo Renaming External Network adapter..
            netsh interface set interface name="!name!" newname="External"
        )
        if "!mac:~-2!"=="CC" (
            echo Setting static IP address to control Network adapter..
            netsh interface ip set address name="!name!" static 192.168.100.1 255.255.255.0
            echo Renaming Control Network adapter..
            netsh interface set interface name="!name!" newname="Control"
        )
    )
)

echo Adding clients Powershell remoting port proxy...
netsh interface portproxy add v4tov4 listenport=4002 connectaddress=192.168.100.2 connectport=5985
netsh interface portproxy add v4tov4 listenport=4003 connectaddress=192.168.100.3 connectport=5985

if %DEBUG% equ true pause
shutdown -r -t 0
goto :eof

:four
echo five >%~dp0current.txt

echo Installing %KIT%, this might take a while...

if %KIT% equ HLK (
  if exist %~dp0Kits\HLK%HLKKITVER%\HLKSetup.exe (
    %~dp0Kits\HLK%HLKKITVER%\HLKSetup.exe /q
  ) else (
    %~dp0Kits\HLK%HLKKITVER%Setup.exe /q
  )
) else (
  if exist %~dp0Kits\HCK\HCKSetup.exe (
    %~dp0Kits\HCK\HCKSetup.exe /q
  ) else (
    %~dp0Kits\HCKSetup.exe /q
  )
)

:B

TASKLIST | FINDSTR /I "HLKSetup.exe"
IF ERRORLEVEL 1 (GOTO :SetupEnded) ELSE (timeout /t 10 /nobreak > NUL)
GOTO :B
:SetupEnded

echo %KIT% Studio setup has finished...

if %DEBUG% equ true pause
shutdown -r -t 0
goto :eof

:five
echo six >%~dp0current.txt

if %REMOVEGUI% equ true (
    echo Removing windows GUI..
    powershell "Remove-WindowsFeature Server-Gui-Shell, Server-Gui-Mgmt-Infra -Restart"
)

if %DEBUG% equ true pause
shutdown -r -t 0
goto :eof

:six
::Remove script from Run key
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v %~n0 /f
del %~dp0current.txt

echo Downloading and updating Filters
bitsadmin /transfer "Downloading Filters" "%FILTERS%" "%~dp0FilterUpdates.cab"
expand -i "%~dp0FilterUpdates.cab" -f:UpdateFilters.sql "%DTMBIN%\"
del FilterUpdates.cab
pushd "%DTMBIN%\"
"%DTMBIN%\updatefilters.exe" /s
del UpdateFilters.sql
popd

cls

sc query winrm
sc query tlntsvr
echo %DTMBIN%

if %DEBUG% equ true pause
shutdown -r -t 0
goto:eof

:resume
if exist %~dp0current.txt (
    set /p current=<%~dp0current.txt
) else (
    set current=one
)
