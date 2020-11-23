@echo off
setlocal EnableDelayedExpansion
SET KIT=HLK
:: SET KIT=HCK
SET CERTIFICATE=VirtIOTestCert.cer
SET PASSWORD=Qum5net.
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

for /f "delims=" %%a in ('wmic nic Where "NetConnectionID is not null" get NetConnectionID^,macaddress /format:csv ^| find /v "Node"') do (
    set line=%%a
    set line=!line:"=,!
    for /f "delims=,,, tokens=2,3" %%b in ("!line!") do (
        set mac=%%b
        set name=%%c
        if "!mac:~-9!"==":01:CC:CC" (
            echo Setting static IP address to MessageDevice Network adapter..
            netsh interface ip set address name="!name!" static 192.168.100.2 255.255.255.0 192.168.100.1
            echo Renaming External Network adapter..
            netsh interface set interface name="!name!" newname="MessageDevice"
            echo Renaming hostname to CL1
            WMIC ComputerSystem where Name="%computername%" call Rename Name="CL1"
        )
        if "!mac:~-9!"==":02:CC:CC" (
            echo Setting static IP address to MessageDevice Network adapter..
            netsh interface ip set address name="!name!" static 192.168.100.3 255.255.255.0 192.168.100.1
            echo Renaming MessageDevice Network adapter..
            netsh interface set interface name="!name!" newname="MessageDevice"
            echo Renaming hostname to CL2
            WMIC ComputerSystem where Name="%computername%" call Rename Name="CL2"
        )
    )
)

echo Setting TestSigning on...
bcdedit /set testsigning on

shutdown -r -t 0
goto :eof

:three
echo four >%~dp0current.txt

echo Enabling powershell remoting...
powershell "Set-NetConnectionProfile -NetworkCategory Private"
cmd.exe /c winrm quickconfig -q
cmd.exe /c winrm set winrm/config "@{MaxTimeoutms="14400000"}"
cmd.exe /c winrm set winrm/config/service/auth "@{Basic="true"}"
cmd.exe /c winrm set winrm/config/service "@{AllowUnencrypted="true"}"

echo Copying %KIT% client installation from studio to client
mkdir Client
xcopy "\\STUDIO\%KIT%Install\Client" Client

echo Starting %KIT% client installation.
echo Shutdown studio machine before continuing.
pause
echo %KIT% client setup has started...
:: HLK Installer
if exist "Client\setup.cmd" (
  cmd /C "Client\setup.cmd" /qn ICFAGREE=Yes
)
:: HCK Installer
if exist "Client\setup.exe" (
  cmd /C "Client\setup.exe" /qn ICFAGREE=Yes
)
:B
TASKLIST | FINDSTR /I "Setup*.exe"
IF ERRORLEVEL 1 (GOTO :SetupEnded) ELSE (timeout /t 10 /nobreak > NUL)
GOTO :B
:SetupEnded
echo %KIT% client setup has finished...

shutdown -r -t 0
goto :eof

:four
::Remove script from Run key
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v %~n0 /f
del %~dp0current.txt

goto :eof

:resume
if exist %~dp0current.txt (
    set /p current=<%~dp0current.txt
) else (
    set current=one
)
