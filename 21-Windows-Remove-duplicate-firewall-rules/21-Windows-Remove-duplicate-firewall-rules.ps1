# SCRIPT INFO -------------------
# --- Remove duplicate firewall rules ---
# By Chris Jeucken
# v0.1
# -------------------------------
# Run on target session host

# SCRIPT ------------------------
# Remove duplicate inbound firewall rules
    $FirewallInboundRules  = Get-NetFirewallRule -Direction Inbound | Where-Object {$_.Owner -ne $Null} | Sort-Object Displayname, Owner
    $FirewallInboundRulesUnique = Get-NetFirewallRule -Direction Inbound | Where-Object {$_.Owner -ne $Null} | Sort-Object Displayname, Owner -Unique
    Write-Host "Found inbound firewall rules: " $FirewallInboundRules.Count -ForegroundColor Yellow
    Write-Host "Found inbound firewall rules (Unique): " $FirewallInboundRulesUnique.Count -ForegroundColor Yellow   
    if ($FirewallInboundRules.Count -ne $FirewallInboundRulesUnique.Count) {
        Write-Host "Found firewall rules to remove: " (Compare-Object -ReferenceObject $FirewallInboundRules -DifferenceObject $FirewallInboundRulesUnique).Count
        Compare-Object -ReferenceObject $FirewallInboundRules -DifferenceObject $FirewallInboundRulesUnique | Select-Object -ExpandProperty InputObject | Remove-NetFirewallRule
    }

# Remove duplicate outbound firewall rules
    $FirewallOutboundRules  = Get-NetFirewallRule -Direction Outbound | Where-Object {$_.Owner -ne $Null} | Sort-Object Displayname, Owner
    $FirewallOutboundRulesUnique = Get-NetFirewallRule -Direction Outbound | Where-Object {$_.Owner -ne $Null} | Sort-Object Displayname, Owner -Unique
    Write-Host "Found outbound firewall rules: " $FirewallOutboundRules.Count -ForegroundColor Yellow
    Write-Host "Found outbound firewall rule (Unique): " $FirewallOutboundRulesUnique.Count -ForegroundColor Yellow      
    if ($FirewallOutboundRules.Count -ne $FirewallOutboundRulesUnique.Count) {
        Write-Host "Found firewall rules to remove: " (Compare-Object -ReferenceObject $FirewallOutboundRules -DifferenceObject $FirewallOutboundRulesUnique).Count
        Compare-Object -referenceObject $FirewallOutboundRules -DifferenceObject $FirewallOutboundRulesUnique | Select-Object -ExpandProperty InputObject | Remove-NetFirewallRule
    }
# -------------------------------
