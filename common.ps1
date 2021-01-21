
. "$PSScriptRoot\auxiliary.ps1"

function Disable-ServerManagerStartupPopup {
    Write-Output "Disabling Server Manager popup on startup..."
    Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -Name "DoNotOpenServerManagerAtLogon" `
        -Type DWord -Value 1
    Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\Oobe" -Name "DoNotOpenInitialConfigurationTasksAtLogon" `
        -Type DWord -Value 1
}

function Disable-WindowsFirewall {
    Write-Output "Disabling Windows Firewall..."
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
    Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Security Center" -Name "FirewallDisableNotify" -Type DWord -Value 1
}

function Set-UnidentifiedNetworksToPrivateLocation {
    Write-Output "Setting unidentified networks to Private Location..."
    Set-Registry -Name "Category" -Type DWord -Value "1" `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\010103000F0000F0010000000F0000F0C967A3643C3AD745950DA7859209176EF5B87C875FA20DF21951640E807D7C24"
}

function Disable-WindowsUpdate {
    Write-Output "Disabling Windows Update..."
    Set-Service -Name "wuauserv" -StartupType Disabled
    Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" `
        -Name "AUOptions" -Type DWord -Value 1
}

function Disable-Screensaver {
    Write-Output "Disabling screensaver..."
    Set-Registry -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveActive" -Type String -Value "0"
    Set-Registry -Path "HKCU:\Control Panel\Desktop" -Name "SCRNSAVE.EXE" -Type String -Value ""
}

function Disable-PowerSavingOptions {
    Write-Output "Disabling power saving options..."
    Execute-Command -Path "powercfg.exe" -Arguments "-change -monitor-timeout-ac 0"
    Execute-Command -Path "powercfg.exe" -Arguments "-change -disk-timeout-ac 0"
    Execute-Command -Path "powercfg.exe" -Arguments "-change -standby-timeout-ac 0"
    Execute-Command -Path "powercfg.exe" -Arguments "-hibernate off"
}

function Enable-PowerShellRemoting {
    Write-Output "Enabling powershell remoting..."
    Start-Sleep -Seconds 30
    Set-NetConnectionProfile -NetworkCategory Private
    Execute-Command -Path 'C:\Windows\System32\winrm.cmd' -Arguments 'quickconfig -q'
    Execute-Command -Path 'C:\Windows\System32\winrm.cmd' -Arguments 'set winrm/config "@{MaxTimeoutms="14400000"}"'
    Execute-Command -Path 'C:\Windows\System32\winrm.cmd' -Arguments 'set winrm/config/service/auth "@{Basic="true"}"'
    Execute-Command -Path 'C:\Windows\System32\winrm.cmd' -Arguments 'set winrm/config/service "@{AllowUnencrypted="true"}"'
}

function Remove-WindowsGUI {
    Write-Output "Removing windows GUI..."
    Remove-WindowsFeature Server-Gui-Shell, Server-Gui-Mgmt-Infra
}
