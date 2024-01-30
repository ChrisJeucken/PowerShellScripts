# SCRIPT INFO -------------------
# --- Disable screensaver in local group policy ---
# By Chris Jeucken
# v1.0
# -------------------------------
# Run on target server
# Requires PolicyFileEditor PowerShell module

# MODULES --------------------
    if (Get-InstalledModule -Name PolicyFileEditor -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) {
        Import-Module -Name PolicyFileEditor
    } else {
        Write-Host "INFO: PolicyFileEditor PowerShell module is not installed. Installing..." -ForegroundColor Red
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
        Install-Module -Name PolicyFileEditor -RequiredVersion 3.0.0 -Scope CurrentUser
        if (!(Get-InstalledModule -Name PolicyFileEditor -ErrorAction SilentlyContinue -WarningAction SilentlyContinue)) {
            Write-Host "ERROR: PolicyFileEditor PowerShell module still not installed. No internet connection available?"
            Exit 1
        }
    }
# ----------------------------

# VARIABLES ------------------
    $UserPolicy = $env:windir + "\system32\GroupPolicy\User\registry.pol"
    $MachinePolicy = $env:windir + "\system32\GroupPolicy\User\registry.pol"
    $TargetItems = "USER,Software\Policies\Microsoft\Windows\Control Panel\Desktop,ScreenSaveTimeout",
                   "USER,Software\Policies\Microsoft\Windows\Control Panel\Desktop,ScreenSaverIsSecure",
                   "USER,Software\Policies\Microsoft\Windows\Control Panel\Desktop,ScreenSaveActive",
                   "USER,Software\Policies\Microsoft\Windows\Control Panel\Desktop,SCRNSAVE.EXE"
# ----------------------------

# SCRIPT ---------------------
    foreach ($TargetItem in $TargetItems) {
        $TargetItem = $TargetItem -split(",")
        if ($TargetItem[0] -eq "USER") {
            Remove-PolicyFileEntry -Path $UserPolicy -Key $TargetItem[1] -ValueName $TargetItem[2]
        } elseif ($TargetItem[0] -eq "MACHINE") {
            Remove-PolicyFileEntry -Path $MachinePolicy -Key $TargetItem[1] -ValueName $TargetItem[2]
        } else {
            Write-Host "Failed to specify USER or MACHINE hive in TargetItem"
        }
    }
# ----------------------------