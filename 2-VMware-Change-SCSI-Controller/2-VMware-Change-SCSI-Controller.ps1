# SCRIPT INFO -------------------
# --- Change SCSI controller for VMware vSphere VM ---
# By Chris Jeucken
# v0.99
# -------------------------------------------------------
# Run on machine with:
#   - VMware vSphere PowerCLI
# -------------------------------

# VARIABLES ---------------------
    $vCenterServer = ""
    $vCenterUser = ""
    $vCenterPassword = ""

    $TargetVMWildcard = "vm*"
# -------------------------------

# PREREQUISITES -----------------
# Modules
    Import-Module VMware.PowerCLI | Out-Null

# Connect to vCenter
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
    Connect-VIServer -Server $vCenterServer -User $vCenterUser -Password $vCenterPassword
# -------------------------------

# SCRIPT ------------------------
# Get target VMs with a number in the name
    $TargetVMs = Get-VM -Name $TargetVMWildcard | Where-Object {$_.Name -match ".*\d+.*"}

# Work through each VM and change the controller if it's powered off
    $Counter = 0
    foreach ($TargetVM in $TargetVMs) {
        $Counter++
        Write-Host $Counter "of" $TargetVMs.Count "-" $TargetVM.Name "-" -NoNewline
        if ($TargetVM.PowerState -like "PoweredOn") {
            Write-Host "Machine is powered on. Doing nothing with it."
        } elseif ($TargetVM.PowerState -like "PoweredOff") {
            $ScsiController = Get-HardDisk -VM $TargetVM.Name | Select-Object -First 1 | Get-ScsiController
            if ($ScsiController.Type -eq "VirtualLsiLogicSAS") {
                Write-Host "Machine is powered off. Switching SCSI controller to type Paravirtual."
                Set-ScsiController -ScsiController $ScsiController -Type ParaVirtual
            } elseif ($ScsiController.Type -eq "ParaVirtual") {
                Write-Host "Machine is powered off but SCSI controller is already type Paravirtual."
            }            
        } else {
            Write-Host "Machine has a different power state. Doing nothing with it."
        }
    }
# -------------------------------