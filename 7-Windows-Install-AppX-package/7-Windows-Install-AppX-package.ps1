# SCRIPT INFO -------------------
# --- Install AppX package ---
# By Chris Jeucken
# v0.1
# -------------------------------
# Run on target machine
# (Microsoft AAD BrokerPlugin required for correctly logging in to Office 365)
# -------------------------------

# VARIABLES ---------------------
    $TargetAppxPackage = "Microsoft.AAD.BrokerPlugin"
    $TargetAppxPackageFull = "Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy"
# -------------------------------

# SCRIPT ------------------------
# Enable/Start Windows Firewall service
    $FirewallService = Get-Service -Name mpssvc | Select-Object *
    if ($FirewallService.StartType -ne "Automatic") {
      Set-Service -Name mpssvc -StartupType Automatic
    }
    if ($FirewallService.Status -ne "Running") {
        Start-Service -Name mpssvc
    }

# Add AppX package
    $TargetAppxPackageManifest = $env:windir + "\SystemApps\" + $TargetAppxPackageFull + "\Appxmanifest.xml"
    if (!(Get-AppxPackage $TargetAppxPackage)) { 
        Add-AppxPackage -Register $TargetAppxPackageManifest -DisableDevelopmentMode -ForceApplicationShutdown
    }
# -------------------------------