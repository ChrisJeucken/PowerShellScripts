# SCRIPT INFO -------------------
# --- Install Intel Meltdown-Spectre registry updates ---
# By Chris Jeucken
# v0.1
# ------------------------------------------------------
# Run on target machine
# -------------------------------

# VARIABLES ---------------------
    # Create variable with update (with full path)
    $Targets = "$[RegistryUpdateTargets]"

    # Include reboot after script?
    $Reboot = "$[IncludeRebootRegistry]"
# -------------------------------

# SCRIPT ------------------------
    # Check if Hyper-V is installed
    $HyperV = (Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State

    # Check if Remote Desktop Services is installed
    $OSVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
    if ($OSVersion -like "Windows Server*") {
        $RDS = (Get-WindowsFeature -Name Remote-Desktop-Services).InstallState
    }

    # Create Function for performing the actual registry updates
    Function PerformRegistryUpdates {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name FeatureSettingsOverride -Value 0 -Type Dword -Confirm:$false -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name FeatureSettingsOverrideMask -Value 3 -Type Dword -Confirm:$false -Force
        if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization") {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization" -Name MinVmVersionForCpuBasedMitigations -Value "1.0" -Type String -Confirm:$false -Force
        }
        # Reboot if allowed
        if ($Reboot -eq "Yes") {
            Write-Host Rebooting system
            Restart-Computer -Force
        }
    }
    
    # Determine if registry updates should be done
    if ($Targets -eq "OnlyHyperV") {
        if ($HyperV -eq "Enabled") { 
            Write-Host Hyper-V detected, performing registry updates
            PerformRegistryUpdates 
        }
    }
    
    if ($Targets -eq "OnlyRDS") {
        if ($RDS -eq "Installed") { 
            Write-Host Remote Desktop Services detected, performing registry updates..
            PerformRegistryUpdates 
        }
    }

    if ($Targets -eq "OnlyHyperVRDSH" ) {
        if ($HyperV -eq "Enabled") { 
            Write-Host Hyper-V detected, performing registry updates...
            PerformRegistryUpdates 
        }
        if ($RDS -eq "Installed") { 
            Write-Host Remote Desktop Services detected, performing registry updates...
            PerformRegistryUpdates 
        }
    }

    if ($Targets -eq "AllServers") {
        Write-Host Performing registry updates...
        PerformRegistryUpdates
    }
    
    if ($Targets -eq "None") {
        Write-Host Not performing registry updates...
    }

# -------------------------------