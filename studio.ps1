$ErrorActionPreference = "Stop"

. "$PSScriptRoot\auxiliary.ps1"
. "$PSScriptRoot\common.ps1"

function Stage-One {
    Set-NewStage -Stage "Two"

    Disable-ServerManagerStartupPopup
    Disable-WindowsFirewall
    Set-UnidentifiedNetworksToPrivateLocation
    Disable-WindowsUpdate
    Disable-Screensaver
    Disable-PowerSavingOptions

    Rename-Computer -NewName "$STUDIOCOMPUTERNAME"

    Get-NetAdapter | ForEach-Object {
        $adapterName = $_.Name
        $adapterMac = $_.MacAddress

        $lastMacSegment = $adapterMac.Substring($adapterMac.Length - 2)

        switch ($lastMacSegment) {
            "CC" {
                Write-Output "Setting static IP address to control Network adapter..."
                New-NetIPAddress -InterfaceAlias $adapterName -IPAddress "192.168.100.1" -PrefixLength 24
                Write-Output "Renaming Control Network adapter..."
                Rename-NetAdapter -Name "$adapterName" -NewName "Control"
                Break
            }
            "DD" {
                Write-Output "Renaming External Network adapter..."
                Rename-NetAdapter -Name "$adapterName" -NewName "External"
                Break
            }
            Default {
                Write-Output "Adapter $adapterName with MAC $adapterMac. Skipped..."
                Break
            }
        }
    }

    Write-Output "Adding clients Powershell remoting port proxy..."
    Execute-Command -Path "netsh.exe" -Arguments "interface portproxy add v4tov4 listenport=4002 connectaddress=192.168.100.2 connectport=5985"
    Execute-Command -Path "netsh.exe" -Arguments "interface portproxy add v4tov4 listenport=4003 connectaddress=192.168.100.3 connectport=5985"

    Enable-PowerShellRemoting

    Safe-Restart
}

function Stage-Two {
    Set-NewStage -Stage "Three"

    Write-Output "Installing $KITTYPE, this might take a while..."
    $kitPath = ""
    $kitArgs = "/q"

    if ($KITTYPE -eq "HLK") {
        if (Test-Path -Path "$PSScriptRoot\Kits\HLK${HLKKITVER}\HLKSetup.exe") {
            $kitPath = "$PSScriptRoot\Kits\HLK${HLKKITVER}\HLKSetup.exe"
        } else {
            $kitPath = "$PSScriptRoot\Kits\HLK${HLKKITVER}Setup.exe"
        }
    } else {
        if (Test-Path -Path "%~dp0Kits\HCK\HCKSetup.exe") {
            $kitPath = "$PSScriptRoot\Kits\HCK\Setup.exe"
        } else {
            $kitPath = "$PSScriptRoot\Kits\HCKSetup.exe"
        }
    }

    Execute-Command -Path "$kitPath" -Arguments "$kitArgs"
    Write-Output "$KITTYPE Studio setup has finished..."

    if ($REMOVEGUI -eq $TRUE) {
        Remove-WindowsGUI
    }

    Safe-Restart
}

function Stage-Three {
    Remove-Stage
    Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "install"

    Write-Output "Downloading and updating Filters..."
    if (!(Test-Path -Path "$env:DTMBIN")) {
        Write-Error "Folder $env:DTMBIN does not exist! Please verify that you have the controller installed."
    }

    $filtersFile = "$env:TEMP\FilterUpdates.cab"

    Execute-Command -Path "bitsadmin.exe" -Arguments "/transfer `"Downloading Filters`" `"$FILTERS`" `"$filtersFile`""
    Execute-Command -Path "expand.exe" -Arguments "-i `"$filtersFile`" -f:UpdateFilters.sql `"$env:DTMBIN\`""
    Remove-Item -Path "$filtersFile"
    Push-Location -Path "$env:DTMBIN\"
    Execute-Command -Path "$env:DTMBIN\updatefilters.exe" -Arguments "/s"
    Remove-Item -Path "UpdateFilters.sql"
    Pop-Location

    Get-Service -Name "winrm"
    Write-Output "$env:DTMBIN"

    Safe-Shutdown
}

Start-Stage
