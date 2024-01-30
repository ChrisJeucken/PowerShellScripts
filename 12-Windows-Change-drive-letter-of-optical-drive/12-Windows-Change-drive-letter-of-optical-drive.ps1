# SCRIPT INFO -------------------
# --- Change drive letter of optical drive ---
# By Chris Jeucken
# v0.2
# -------------------------------
# Run on target machine

# VARIABLES ---------------------
    $TargetOpticalDriveLetter = "Y:"
# -------------------------------

# SCRIPT ------------------------
    $OpticalDrive = Get-WmiObject -Class Win32_Volume -Filter "DriveType=5"
    if (!($OpticalDrive)) {
        Write-Host "No optical drive found"
        Return
    } else {
        $CurrentOpticalDriveLetter = $OpticalDrive | Select-Object -ExpandProperty DriveLetter
        if ($CurrentOpticalDriveLetter -eq $TargetOpticalDriveLetter ) {
            Write-Host "Optical drive found which already has driveletter" $TargetOpticalDriveLetter
            Write-Host "Ending script"
            Return
        } else {
            Write-Host "Optical drive found with drive letter" $CurrentOpticalDriveLetter
            Write-Host "Changing driveletter to" $TargetOpticalDriveLetter
            try 
            {
                $OpticalDrive | Set-WmiInstance -Arguments @{DriveLetter=$TargetOpticalDriveLetter} -WarningAction Stop -ErrorAction Stop
            }
            catch
            {
                if (Get-Module -Name Microsoft.PowerShell.Management) {
                    $OpticalDrive | Set-WmiInstance -Arguments @{DriveLetter=$TargetOpticalDriveLetter}
                } else {
                    Import-Module -Name Microsoft.PowerShell.Management
                    $OpticalDrive | Set-WmiInstance -Arguments @{DriveLetter=$TargetOpticalDriveLetter}
                }
            }
        }
    }
# -------------------------------