# SCRIPT INFO -------------------
# --- Update Windows Defender ---
# By Chris Jeucken
# v0.1
# -------------------------------
# Run on target session host

# VARIABLES ---------------------
# Fallback Defender signature location
    if ($env:USERDNSDOMAIN) {
        $DomainFQDN = $env:USERDNSDOMAIN
    } else {
        $DomainFQDN = "domain.local"
    }
    $FallbackSignatureLocation = "\\server\share\DefenderUpdates\Full"

# Defender registry location
    $DefenderRegistryLocation = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
# Log file
    $LogFile = $env:LOGDIR + "\DS151-Defender-Update.log"
# -------------------------------

# SCRIPT ------------------------
# Setup transcript for logfile
    Start-Transcript -Path $LogFile -Append
    Write-Host "Starting Windows Defender update script at" (Get-Date -format "dd-MM-yyyy HH:mm")

# Verify Defender installation
    if (!(Test-Path -Path $DefenderRegistryLocation)) {
        Write-Host "Defender registry key not found. Checking feature installation."
        $OSVersion = (Get-WmiObject -class Win32_OperatingSystem).Caption
        if ($OSVersion -like "*2016*") {
            $DefenderFeature = "Windows-Defender-Features"
        } elseif ($OSVersion -like "*2019*") {
            $DefenderFeature = "Windows-Defender"
        } else {
            Write-Host "Not a Windows Server 2016 or 2019 server. Ending script."
            Return
        }

        if ((Get-WindowsFeature -Name $DefenderFeature).InstallState -ne "Installed") {
            Write-Host "Windows Defender not installed. Ending script."
            Return
        }
    }

# Verify signature update location and available version
    if (Get-ItemProperty -Path "$DefenderRegistryLocation\Signature Updates" -Name "DefinitionUpdateFileSharesSources" -ErrorAction SilentlyContinue) {
        $CurrentUpdateFileShare = (Get-ItemProperty -Path "$DefenderRegistryLocation\Signature Updates" -Name "DefinitionUpdateFileSharesSources" -ErrorAction SilentlyContinue).DefinitionUpdateFileSharesSources
        $CurrentUpdateSource = (Get-ItemProperty -Path "$DefenderRegistryLocation\Signature Updates" -Name "FallbackOrder" -ErrorAction SilentlyContinue).FallbackOrder
        Write-Host "Currently defined signature update location" $CurrentUpdateFileShare
    } else {
        Write-Host "No signature update location configured. Has the GPO been applied correctly?"
        Write-Host "Configuring fallback signature update location for now:" $FallbackSignatureLocation
        Set-ItemProperty -Path "$DefenderRegistryLocation\Signature Updates" -Name "DefinitionUpdateFileSharesSources" -Value $FallbackSignatureLocation -Force
        $CurrentUpdateFileShare = (Get-ItemProperty -Path "$DefenderRegistryLocation\Signature Updates" -Name "DefinitionUpdateFileSharesSources" -ErrorAction SilentlyContinue).DefinitionUpdateFileSharesSources
    }

    if ($CurrentUpdateSource -ne "FileShares") {
        Write-Host "Signature update fallbackorder is not set to 'FileShares'. Correcting..."
        Set-ItemProperty -Path "$DefenderRegistryLocation\Signature Updates" -Name "FallbackOrder" -Value "FileShares" -Force
    }

    if (Test-Path -Path $CurrentUpdateFileShare -ErrorAction SilentlyContinue) {
        if (Test-Path -Path "$CurrentUpdateFileShare\x64\mpam-fe.exe" -ErrorAction SilentlyContinue) {
            $ShareSignatureVersion = (Get-Item -Path "$CurrentUpdateFileShare\x64\mpam-fe.exe" | Select-Object -Property VersionInfo).VersionInfo.ProductVersion
            Write-Host "Current path is reachable."
            Write-Host "Found signature update version:" $ShareSignatureVersion
        } else {
            Write-Host "Current path is reachable but nog signature update found. Is this path correct?"
            Return
        }
    } else {
        Write-Host "Current path is not reachable. Stopping script."
        Return
    }

    if (!(Get-Command -Name "Get-MpComputerStatus" -ErrorAction SilentlyContinue)) {
        Write-Host "Windows Defender status Powershell command not found. Is the feature installed correctly?"
    } else {
        $LocalDefenderStatus = Get-MpComputerStatus
        $LocalSignatureVersion = ($LocalDefenderStatus.AntivirusSignatureVersion)
        Write-Host "Local signature version:" $LocalSignatureVersion
    } 

    if (!(Get-Command -Name "Update-MpSignature" -ErrorAction SilentlyContinue)) {
        Write-Host "Windows Defender update Powershell command not found. Is the feature installed correctly?"
        Write-Host "Using MpCmdRun.exe as fallback:"
        & $env:ProgramFiles"\Windows Defender\MpCmdRun.exe -SignatureUpdate"
        Start-Process -FilePath $env:ProgramFiles"\Windows Defender\MpCmdRun.exe" -ArgumentList "-SignatureUpdate" 
    } else {
        Write-Host "Running Windows Defender update."
        Update-MpSignature -Verbose
    }

    if (!(Get-Command -Name "Get-MpComputerStatus" -ErrorAction SilentlyContinue)) {
        Write-Host "Windows Defender status Powershell command not found. Is the feature installed correctly?"
    } else {
        $LocalDefenderStatus = Get-MpComputerStatus
        $LocalSignatureVersion = ($LocalDefenderStatus.AntivirusSignatureVersion)
        Write-Host "Local signature version (after update):" $LocalSignatureVersion
    } 

# Clean up
    Write-Host "Stopping Windows Defender update script at" (Get-Date -format "dd-MM-yyyy HH:mm")
    Stop-Transcript
# -------------------------------