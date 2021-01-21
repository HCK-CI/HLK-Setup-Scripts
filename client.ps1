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

    Get-NetAdapter | ForEach-Object {
        $adapterName = $_.Name
        $adapterMac = $_.MacAddress

        $macSegments = $adapterMac.Split('-')

        if (($macSegments[5] -eq "CC") -and ($macSegments[4] -eq "CC")) {
            $clientNumber = [int32]("0x" + $macSegments[3])
            $clientIp = $clientNumber + 1
            $clientName = "$CLIENTCOMPUTERNAME$clientNumber"

            Write-Output "Renaming hostname to $clientName"
            Rename-Computer -NewName "$clientName"
            Write-Output "Setting static IP address to MessageDevice Network adapter..."
            New-NetIPAddress -InterfaceAlias "$adapterName" -IPAddress "192.168.100.$clientIp" `
                -PrefixLength 24 -DefaultGateway "192.168.100.1"
            Write-Output "Renaming MessageDevice Network adapter..."
            Rename-NetAdapter -Name "$adapterName" -NewName "MessageDevice"

        } else {
            Write-Output "Adapter $adapterName with MAC $adapterMac. Skipped..."
        }
    }

    Write-Output "Setting TestSigning on..."
    Execute-Command -Path "bcdedit.exe" -Arguments "/set testsigning on"

    Enable-PowerShellRemoting

    Safe-Restart
}

function Stage-Two {
    Remove-Stage
    Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "install"

    Write-Output "Copying $KITTYPE client installation from studio to client..."

    $clientInstallerFolder = "$env:TEMP\Client"
    Copy-Item -Path "\\STUDIO\${KITTYPE}Install\Client" -Destination "$clientInstallerFolder" -Recurse

    Write-Output "Starting $KITTYPE client installation..."
    # HLK Installer
    if (Test-Path -Path "$clientInstallerFolder\setup.cmd") {
        & "$clientInstallerFolder\setup.cmd" "/qb" "ICFAGREE=Yes"
    }
    # HCK Installer
    if (Test-Path -Path "$clientInstallerFolder\setup.exe") {
        & "$clientInstallerFolder\setup.exe" "/qb" "ICFAGREE=Yes"
    }

    Write-Output "$KITTYPE client setup has finished..."

    if ($REMOVEGUI -eq $TRUE) {
        Remove-WindowsGUI
    }

    Get-Service -Name "winrm"
    Safe-Shutdown
}

Start-Stage