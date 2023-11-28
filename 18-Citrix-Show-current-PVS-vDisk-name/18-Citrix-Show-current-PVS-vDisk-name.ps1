# SCRIPT INFO -------------------
# --- Show current Citrix Provisioning Services vDisk ---
# By Chris Jeucken
# v0.1
# -------------------------------

# PREREQUISITES -----------------
    Add-Type -AssemblyName PresentationCore,PresentationFramework
# -------------------------------

# SCRIPT ------------------------
# Get PVS vDisk name
    Write-Host "Get PVS vDisk name" -ForegroundColor Yellow
    $vDiskName = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\bnistack\PvsAgent" -Name DiskName -ErrorAction SilentlyContinue).DiskName
    if ($vDiskName) {
        $vDiskName = $vDiskName.Replace(".vhdx","")
    }

# Get last bootup time
    $LastBootupTime = (Get-CimInstance -ClassName win32_operatingsystem | Select-Object LastBootupTime).LastBootupTime

# Setup Message box popup
    if ($vDiskName) {
        $MessageBoxBody = "The current vDisk is: $vDiskName",
                        "`nThe hostname of this machine is: $env:COMPUTERNAME",
                        "`nThis machine was booted at: $LastBootupTime"
    } else {
        $MessageBoxBody = "This machine is not provisioned yet."
                        "`nThe hostname of this machine is: $env:COMPUTERNAME",
                        "`nThis machine was booted at: $LastBootupTime"
    }
    $MessageBoxTitle = "SBC vDisk pop-up"
    $MessageBoxButton = [System.Windows.MessageBoxButton]::OK
    $MessageBoxIcon = [System.Windows.MessageBoxImage]::Information

# Show Message box popup
    [System.Windows.MessageBox]::Show($MessageBoxBody,$MessageBoxTitle,$MessageBoxButton,$MessageBoxIcon)
# -------------------------------
