# SCRIPT INFO -------------------
# --- Update VMware tools remotely ---
# By Chris Jeucken
# v0.99
# -------------------------------
# Run on machine with:
#   - VMware vSphere PowerCLI
# -------------------------------

# VARIABLES ---------------------
    $vCenterServer = ""
    $vCenterUser = ""
    $vCenterPassword = ""
    $TargetVM = ""
# -------------------------------

# PREREQUISITES -----------------
# Import PowerCLI module
    Import-Module -Name "VMware.PowerCLI" | Out-Null
# Connect to vCenter
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
    Connect-VIServer -Server $vCenterserver -User $vCenterUser -Password $vCenterPassword | Out-Null
# -------------------------------

# SCRIPT ------------------------
# Get current VMware Tools status
    $VM = Get-VM -Name $TargetVM
    $VMToolsStatus = $VM.ExtensionData.Guest | Select-Object Hostname,Tools*

# Upgrade VMware Tools if needed
    if ($VMToolsStatus.ToolsVersionStatus -eq "guestToolsNeedUpgrade") {
        Write-Host "VMware Tools upgrade needed. Starting upgrade."
        $VM | Update-Tools -NoReboot
        # Wait for VMware Tools version to report as current
        while ($UpdateStatus -ne "guestToolsCurrent") {
            Start-Sleep -Seconds 15
            $UpdateStatus = ((Get-VM -Name $TargetVM).ExtensionData.Guest | Select-Object -Property Hostname,Tools*).ToolsVersionStatus
        }
    }
# -------------------------------