# SCRIPT INFO -------------------
# --- Install Windows update with wusa.exe ---
# By Chris Jeucken
# v0.1
# -------------------------------------------------------
# Run on target machine
# -------------------------------

# VARIABLES ---------------------
# Create variable with update (with full path)
    $UpdateFile = "" # E.g.: windows10.0-kb5006744-x64.msu
    $UpdateLocation = "" # C:\TEMP
    $Update = $UpdateLocation + "\" + $UpdateFile
    $KBNumber = ($UpdateFile -split "-")[1]

# Include reboot after update?
    $Reboot = "Yes"

# Specify logfile
    $LogFile = "C:\Log\" + $env:COMPUTERNAME + "-Update.evtx"
    $LogFile = "/log:" + $LogFile

# Show variables (for troubleshooting)
    Write-Host --- Used Variables ---
    Write-Host Update: $Update
    Write-Host Include Reboot: $Reboot
    Write-Host Logfile: $LogFile
    Write-Host ----------------------
# -------------------------------

# SCRIPT ------------------------
    # Check if hotfix is already installed
    if (!(Get-HotFix -id $KBNumber -ErrorAction SilentlyContinue)) {

        # Determine if 64-bit or 32-bit
        if (!(Test-Path $env:systemroot\SysWOW64\wusa.exe)) {
            Write-Host 32-bit Windows Update Standalone Installer will be used
            $Wusa = "$env:systemroot\System32\wusa.exe"
        } else {
            Write-Host 64-bit Windows Update Standalone Installer will be used
            $Wusa = "$env:systemroot\SysWOW64\wusa.exe"
        }

        # Run actual update
        if ($Reboot -eq "Yes") { 
            Write-Host Running update with automatic reboot
            Start-Process -FilePath $Wusa -ArgumentList ($Update, "/quiet", "$LogFile") -Wait
        }
        if ($Reboot -eq "No") {
            Write-Host Running Update without automatic reboot
            Start-Process -FilePath $Wusa -ArgumentList ($Update, "/quiet", "/noreboot", "$LogFile") -Wait
        }
    } else {
        Write-Host Hotfix $KBNumber is already installed.
    }
# -------------------------------