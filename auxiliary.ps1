$FILTERS = "https://go.microsoft.com/fwlink/?linkid=875139"
$STUDIOCOMPUTERNAME = "STUDIO"
$CLIENTCOMPUTERNAME = "CL"
$KITTYPE = "HLK"
$HLKKITVER = 1809
$REMOVEGUI = $false
$DEBUG = $false
$STAGEFILE = "$env:TEMP\current-stage.txt"
$ARGSPATH = "$PSScriptRoot\args.ps1"
$EXTRASOFTWAREDIRECTORY = "$PSScriptRoot\extra-software"

if (Test-Path -Path "$ARGSPATH") {
    . "$ARGSPATH"
}

function Execute-Command ($Path, $Arguments) {
    Write-Output "Execution $Path $Arguments"

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "$Path"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = "$Arguments"
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()

    $stdout = $p.StandardOutput.ReadToEnd().Trim()
    $stderr = $p.StandardError.ReadToEnd().Trim()

    if ($p.ExitCode -ne 0) {
        Write-Error "$stdout`n$stderr"
    } else {
        if ($stdout.Length -gt 0) {
            Write-Output "$stdout"
        }
        if ($stderr.Length -gt 0) {
            Write-Output "$stderr"
        }
    }
}

function Set-NewStage() {
    param (
        $Stage
    )
    Write-Output "Set new stage to file: $Stage"
    Set-Content -Path "$STAGEFILE" -Value "$Stage"
}

function Get-CurrentStage() {
    if ((Test-Path $STAGEFILE)) {
        Get-Content -Path "$STAGEFILE"
    } else {
        Write-Output "One"
    }
}

function Remove-Stage() {
    Write-Output "Remove stage file: $STAGEFILE"
    Remove-Item -Path "$STAGEFILE"
}

function Start-Stage() {
    $stage = Get-CurrentStage
    $time = Get-Date -UFormat "%d-%m-%Y-%H-%M-%S"

    Start-Transcript -Path "$env:TEMP\install-$stage-$time.log" -Force
    Write-Output "[$time] Starting stage $stage..."
    Invoke-Expression "Stage-$stage"
}

function Safe-Restart() {
    Stop-Transcript

    if ($DEBUG -eq $true) {
        Read-Host 'Press any key to continue...'
    }

    Restart-Computer
}

function Safe-Shutdown() {
    Stop-Transcript

    if ($DEBUG -eq $true) {
        Read-Host 'Press any key to continue...'
    }

    Stop-Computer
}

function Set-Registry {
    param (
        $Path,
        $Name,
        $Value
    )

    if (Test-Path "$Path") {
        New-ItemProperty -Path "$Path" -Name "$Name" -Value "$Value" `
            -PropertyType "$Type" -Force
     } else {
        New-Item -Path "$Path" -Force
        New-ItemProperty -Path "$Path" -Name "$Name" -Value "$Value" `
            -PropertyType "$Type" -Force
     }
}
