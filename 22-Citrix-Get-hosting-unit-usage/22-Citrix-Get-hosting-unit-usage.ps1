<#
.SYNOPSIS
    Show Citrix VAD hosting unit usage.
.DESCRIPTION
    List all Citrix VAD hosting units and show which provisioning schemes/machine catalogs use this hosting unit.
.EXAMPLE
    <ScriptName>.ps1 -DeliveryControllers "CTXDC1.domain.local,CTXDC2.domain.local"
.LINK
    https://github.com/ChrisJeucken/PowerShellScripts/tree/main/22-Citrix-Get-hosting-unit-usage
.NOTES
  Version:          1.0
  Author:           Chris Jeucken
  Creation Date:    14 November 2024
  Website:          https://chrisjeucken.com
.PARAMETER DeliveryControllers
    Specify Fully Qualified Domain Name, hostname or IP address of the Citrix VAD Delivery Controllers.
    Divide multiple DC's with a comma or don't specify this parameter if this script is run on a Delivery Controller.
    E.g.: CTXDC1.domain.local,CTXDC2.domain.local
#>

# PARAMETERS --------------------
    param(
        [Parameter()]
        [string]$DeliveryControllers
    )

# PREREQUISITES -----------------
# Import Citrix PowerShell Snapins
    Add-PSSnapin -Name "Citrix*"
# -------------------------------

# SCRIPT ------------------------
# Determine working Citrix VAD Delivery Controller
    if ($DeliveryControllers) {
        $DeliveryControllers = $DeliveryControllers.Split(",")
        foreach ($DeliveryController in $DeliveryControllers) {
            if (Test-Connection -ComputerName $DeliveryController -Count 1 -ErrorAction SilentlyContinue) {
                $TargetDC = $DeliveryController
                Break
            }
        }
    } else {
        $TargetDC = "localhost"
    } 


    if (!($TargetDC)) {
        Write-Error "No working Citrix VAD Delivery Controller found. Stopping script."
        Return
    }

# Verify availability of Citrix cmdlets
    if (!(Get-Command -Name Get-BrokerHypervisorConnection -Erroraction SilentlyContinue)) {
        Write-Error "Citrix cmdlets not found. Is Citrix Studio installed on this machine?"
        Return
    }

# Get hosting units
    if (!(Get-PSDrive -Name "XDHyp")) {
        Write-Error "XDHyp PSDrive does not exist. Have the Citrix PowerShell snapins loaded correctly?"
        Return
    } else {
        $HostingUnits = Get-ChildItem "XDHyp:\HostingUnits\" -AdminAddress $TargetDC
    }

# Get provisioning schemes
    $ProvSchemes = Get-ProvScheme -AdminAddress $TargetDC

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