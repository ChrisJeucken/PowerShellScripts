# SCRIPT INFO -------------------
# --- Show Citrix VAD hosting unit usage ---
# By Chris Jeucken
# v0.1
# -------------------------------
# Run on machine with Citrix Studio or Citrix VAD PowerShell SDK installed

# VARIABLES ---------------------
# Define Citrix VAD Delivery Controllers
    $CTXDCs = "CTXDC1.domain.local", # <-- INSERT IP ADDRESS, HOSTNAME OR FQDN FOR PRIMARY CITRIX VAD DELIVERY CONTROLLER
            "CTXDC2.domain.local" # <-- INSERT IP ADDRESS, HOSTNAME OR FQDN FOR SECONDARY CITRIX VAD DELIVERY CONTROLLER
# -------------------------------

# PREREQUISITES -----------------
# Import Citrix PowerShell Snapins
    Add-PSSnapin -Name "Citrix*"
# -------------------------------

# SCRIPT ------------------------
# Determine working Citrix VAD Delivery Controller
    foreach ($CTXDCTest in $CTXDCs) {
        if (Test-Connection -ComputerName $CTXDCTest -Count 1 -ErrorAction SilentlyContinue) {
            $CTXDC = $CTXDCTest
            Break
        }
    }

    if (!($CTXDC)) {
        Write-Host "No working Citrix VAD Delivery Controller found. Stopping script."
        Return
    }

# Get hypervisor connections
    if (!(Get-Command -Name Get-BrokerHypervisorConnection -Erroraction SilentlyContinue)) {
        Write-Host "Citrix cmdlets not found. Is Citrix Studio installed on this machine?"
        Return
    } else {
        $HypervisorConnections = Get-BrokerHypervisorConnection -AdminAddress $CTXDC
    }

# Get hosting units
    if (!(Get-PSDrive -Name "XDHyp")) {
        Write-Host "XDHyp PSDrive does not exist. Have the Citrix PowerShell snapins loaded correctly?"
        Return
    } else {
        $HostingUnits = Get-ChildItem "XDHyp:\HostingUnits\" -AdminAddress $CTXDC
    }

# Get provisioning schemes
    $ProvSchemes = Get-ProvScheme -AdminAddress $CTXDC

# Check which hosting units are not specified in any provisioning scheme
    foreach ($HostingUnit in $HostingUnits) {
        Write-Host "---" $HostingUnit.HostingUnitName "---" -ForegroundColor Green
        if ($ProvSchemes.HostingUnitUid -notcontains $HostingUnit.HostingUnitUid) {
            Write-Host "No provisioning schemes found for this hosting unit."
        } else {
            (($ProvSchemes | Where-Object {$_.HostingUnitUid -eq $HostingUnit.HostingUnitUid}) | Select-Object -Property ProvisioningSchemeName).ProvisioningSchemeName
        }
    }
# -------------------------------