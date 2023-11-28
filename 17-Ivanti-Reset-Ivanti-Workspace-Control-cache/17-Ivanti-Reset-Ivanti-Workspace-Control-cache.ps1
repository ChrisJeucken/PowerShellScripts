LET OP: Deze mail komt van buiten de organisatie. Klik niet op links of open bijlages, tenzij je de afzender herkend en weet dat de bijlage veilig is. 
# SCRIPT INFO -------------------
# --- Reset Ivanti Workspace Control cache ---
# By Chris Jeucken
# v0.1
# -------------------------------

# VARIABLES ---------------------
    Write-Host "1. Set variables" -ForegroundColor Green
# Ivanti Workspace Control cache location
    $IWCCachePath = "$env:ProgramFiles(x86)" + "Ivanti\Workspace Control\Data\dbcache"
# Ivanti Workspace Control registry location
    $IWCRegistryKey = "HKLM:\SOFTWARE\WOW6432Node\RES\Workspace Manager"
# Logfile
    $IWCStartupScriptLog = $env:TEMP + "\IWC-Reset-Cache.log"
# -------------------------------

# SCRIPT ------------------------
    Write-Host "2. Setup transcript" -ForegroundColor Green
# Setup transcript for logfile
    $IWCServiceName = "RES"
    Start-Transcript -Path $IWCStartupScriptLog -Append

    Write-Host "3. Stop Ivanti Workspace Control service" -ForegroundColor Green
# Stop Ivanti Workspace Control service
    if ((Get-Service -Name $IWCServiceName).Status -eq "Running") {
        Write-Host "Ivanti Workspace Control service running. Stopping service..." -ForegroundColor Yellow
        Stop-Service -Name $IWCServiceName -Force
    } else {
        Write-Host "Ivanti Workspace Control service already stopped." -ForegroundColor Yellow
    }

    Write-Host "4. Check if the local Ivanti Workspace Control cache folder exists." -ForegroundColor Green
# Check if the local Ivanti Workspace Control cache folder exists
    if (Test-Path -Path $IWCCachePath) {
        Write-Host "Local Ivanti Workspace Control cache path exists:" $IWCCachePath -ForegroundColor Yellow
    } else {
        Write-Host "Local Ivanti Workspace Control cache path does not exist:" $IWCCachePath -ForegroundColor Red
        Write-Host "Correcting issue." -ForegroundColor Red
        New-Item -Path $IWCCachePath -ItemType Directory -Force
    }

    Write-Host "5. Empty Ivanti Workspace Control cache." -ForegroundColor Green
# Empty Ivanti Workspace Control cache
    Write-Host "Emptying cache folder:" $IWCCachePath -ForegroundColor Yellow
    Remove-Item -Path "$IWCCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Remove-Item -Path "$IWCCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Emptying registry key:" $IWCRegistryKey"\UpdateGUIDs" -ForegroundColor Yellow
    $RegistryKeyUpdateGUIDs = Get-ChildItem -Path $IWCRegistryKey -Recurse -Include "UpdateGUIDs"
    foreach ($RegistryItemProperty in $RegistryKeyUpdateGUIDs.Property) {
        Remove-ItemProperty -Path "$IWCRegistryKey\UpdateGUIDs" -Name $RegistryItemProperty -Force -Verbose
    }

    Write-Host "6. Start Ivanti Workspace Control service" -ForegroundColor Green
# Start Ivanti Workspace Control service
    if ((Get-Service -Name $IWCServiceName).Status -eq "Stopped") {
        Write-Host "Ivanti Workspace Control service stopped. Starting service..." -ForegroundColor Yellow
        Start-Service -Name $IWCServiceName
    } else {
        Write-Host "Ivanti Workspace Control service already running. Restarting service..." -ForegroundColor Yellow
        Restart-Service -Name $IWCServiceName -Force
    }

    Start-Sleep -Seconds 10

# Stop transcript
    Stop-Transcript
# -------------------------------