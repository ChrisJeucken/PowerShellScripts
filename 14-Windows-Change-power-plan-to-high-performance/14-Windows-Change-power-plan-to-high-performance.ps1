# SCRIPT INFO -------------------
# --- Change Windows power plan to high performance ---
# By Chris Jeucken
# v0.1
# -------------------------------
# Run on target machine

# SCRIPT ------------------------
    $PowerPlan = Get-WmiObject -Namespace root\cimv2\power -Class Win32_PowerPlan -Filter "ElementName = 'High Performance'"
    $RegEx = [regex]"{(.*?)}$"
    $PowerPlanGUID = $RegEx.Match($PowerPlan.InstanceID.ToString()).Groups[1].value

    $PowerCfg = $env:WINDIR + "\system32\Powercfg.exe"
    & $PowerCfg /SetActive $PowerPlanGUID
# -------------------------------