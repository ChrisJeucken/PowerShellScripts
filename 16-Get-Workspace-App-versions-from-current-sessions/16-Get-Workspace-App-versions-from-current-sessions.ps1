# SCRIPT INFO -------------------
# --- Get Workspace App versions from current sessions ---
# By Chris Jeucken
# v0.1
# -------------------------------
# Run on machine with Citrix Studio or Citrix Virtual and Apps Desktops PowerShell SDK

# VARIABLES ---------------------
    $DeliveryController1 = "CTX-DDC01.local.lan"
    $DeliveryController2 = "CTX-DDC02.local.lan"
    $ExportFileManaged = $env:TEMP + "\All-Workspace-App-versions.csv"
# -------------------------------

# SCRIPT ------------------------
# Get working Citrix Delivery Controller
    if (Test-NetConnection -ComputerName $DeliveryController1 -ErrorAction SilentlyContinue) {
        $DeliveryController = $DeliveryController1
    } elseif (Test-NetConnection -ComputerName $DeliveryController2 -ErrorAction SilentlyContinue) {
        $DeliveryController = $DeliveryController2
    } else {
        Write-Host "Can't reach both Delivery Controllers. Is something wrong?" -ForegroundColor Red
        Return
    }

# Get all sessions
    $AllSessions = Get-BrokerSession -AdminAddress $DeliveryController -MaxRecordCount 65535 | Select-Object -Property UserName,DesktopGroupName,ClientPlatform,ClientVersion,ClientName
    Write-Host $AllSessions.Count -ForegroundColor Green -NoNewline
    Write-Host " sessions found."

# Group objects and rename column name
    $AllSessions = $AllSessions | Select-Object -Property ClientVersion,ClientPlatform
    $ClientsGrouped = $AllSessions | Group-Object -Property ClientVersion,ClientPlatform | Select-Object -Property @{Name="ClientSpecs"; Expression = {$_.Name}},Count

# Replace empty values
    $ClientsGrouped | ForEach-Object {
        if ($_.ClientSpecs -eq ", Windows") {
            $_.ClientSpecs = "Version Unknown - Windows"
        } elseif ($_.ClientSpecs -like "*,*") {
            $_.ClientSpecs = $_.ClientSpecs -replace ","," -"
        }
        $_
    }

# Sort array based on counts
    $ClientsGrouped = $ClientsManagedGrouped | Sort-Object -Property Count -Descending

# Export to file
    $ClientsGrouped | Export-Csv -Path $ExportFileManaged -NoTypeInformation -Verbose
# -------------------------------