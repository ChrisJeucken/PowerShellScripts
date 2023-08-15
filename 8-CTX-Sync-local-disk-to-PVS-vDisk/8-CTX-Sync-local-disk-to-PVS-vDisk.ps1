# SCRIPT INFO -------------------
# --- Synchronize Master Target Device disk to Citrix Provisioning Services vDisk ---
# By Richard Donker & Chris Jeucken
# v0.5
# -------------------------------
# Run on master target device:
#   - Must be able to connect to Provisioning Services server with PowerShell remote
# -------------------------------

# VARIABLES ---------------------
    Write-Host "1. Set variables" -ForegroundColor Green
# Define Provisioning Services servers
    $PVSHost1 = "" # FQDN, Hostname or IP address of Citrix Provisioning Services server
    $PVSHost2 = "" # FQDN, Hostname or IP address of Citrix Provisioning Services server
# Define Provisioning Services information
    $PVSvDiskPrefix = "" # Prefix of vDisk name (E.g.: CTX-)
    $PVSvDiskSuffix = "" # Suffix of vDisk name (E.g.: -PRD)
    $PVSStore = "" # Name of Citrix Provisioning Services store
    $PVSvDiskDescription = "" # Description for vDisk
    $PVSvDiskWriteCacheSizeMB = "" # Specified WriteCache size in MegaBytes
    $PVSvDiskCounterLength = "3" # How many characters are used in the vDisk counter (e.g.: 001, 002, 003 is 3 characters)							  
# -------------------------------

# SCRIPT ------------------------
# Determine target Provisioning Services server
    Write-Host "2. Determine target Provisioning Services server" -ForegroundColor Green
    if (Test-Connection -ComputerName $PVSHost1 -Count 1 -ErrorAction SilentlyContinue) {
        $PVSHost = $PVSHost1
    } elseif (Test-Connection -ComputerName $PVSHost2 -Count 1 -ErrorAction SilentlyContinue) {
        $PVSHost = $PVSHost2
    } else {
        Write-Host "Provisioning Services hosts" $PVSHost1 "&" $PVSHost2 "cannot be reached. Stopping script." -ForegroundColor Red
        Return
    }
    Write-Host "Provisioning Services server" $PVSHost "will be used." -ForegroundColor Yellow

# Testing PowerShell remoting on target Provisioning Services server
    Write-Host "3. Testing PowerShell remoting on target Provisioning Services server" -ForegroundColor Green
    if (Test-WSMan -ComputerName $PVSHost -ErrorAction SilentlyContinue) {
        Write-Host "PowerShell remoting in working order on" $PVSHost -ForegroundColor Yellow
    } else {
        Write-Host "PowerShell remoting is not working for" $PVSHost -ForegroundColor Red
        Write-Host "Has this been correctly configured?" -ForegroundColor Red
        Return
    }

# Determine vDisk name
    Write-Host "4. Determine vDisk name" -ForegroundColor Green

    $ScriptBlockDeterminevDiskName = {
        Param($PVSvDiskPrefix,$PVSvDiskSuffix,$PVSStore,$PVSvDiskCounterLength)
        # Add Citrix Provisioning Services PowerShell Snapin
        $PVSSnapinDLL = $env:ProgramFiles + "\Citrix\Provisioning Services Console\Citrix.PVS.SnapIn.dll"
        Import-Module -Name $PVSSnapinDLL

        # Connect to Provisioning services
        Set-PvsConnection -Server "localhost"
        if ($PVSFarm = Get-PvsFarm) {
            Write-Host "PVS Farm found:" $PVSFarm.Name -ForegroundColor Cyan
        } else {
            Write-Host "No PVS Farm found." -ForegroundColor Red
            Return
        }
        if ($PVSSite = Get-PvsSite) {
            Write-Host "PVS Site found:" $PVSSite.Name -ForegroundColor Cyan
        } else {
            Write-Host "No PVS Site found." -ForegroundColor Red
            Return
        }

        # Check if Provisioning Services store exists
        if ($TargetPVSStore = Get-PvsStore -StoreName $PVSStore) {
            Write-Host "PVS Store found:" $TargetPVSStore.Name -ForegroundColor Cyan
            $TargetPVSStorePath = ($TargetPVSStore.Path).Replace(":","$")
        } else {
            Write-Host "PVS Store not found:" $PVSStore -ForegroundColor Red
            Return
        }

        # Determine next vDisk version number
        if ($LastVersionNumber) {
            Remove-Variable -Name LastVersionNumber
        }
        $AllDisks = Get-PvsDiskLocator | Where-Object {(($_.Name -like "$PVSvDiskPrefix*") -and ($_.Name -like "*$PVSvDiskSuffix"))}
        if (!($AllDisks)) {
            $NewVersionNumber = "1"
			if ($PVSvDiskCounterLength -gt "1") {
                $Counter = 1
                do {
                    $NewVersionNumber = $NewVersionNumber + "0"
                    $Counter++
                } while ($Counter -lt $PVSvDiskCounterLength)
            }				   
        } else {
            $LastVersion = $AllDisks | Sort-Object -Property Name | Select-Object -Last 1 -ExpandProperty Name
            $LastVersionNumber = $LastVersion.Replace("$PVSvDiskPrefix","")
            $LastVersionNumber = $LastVersionNumber.Replace("$PVSvDiskSuffix","")
            $LastVersionNumber = $LastVersionNumber.Substring(0,$PVSvDiskCounterLength)
            [int]$LastVersionNumber = [convert]::ToInt32($LastVersionNumber, 10)
            $NewVersionNumber = $LastVersionNumber + 1
        }
        $NewvDiskName = $PVSvDiskPrefix + $NewVersionNumber + $PVSvDiskSuffix
        Return $PVSSite.Name,$TargetPVSStorePath,$NewvDiskName
    }

    Write-Host "Invoke command on" $PVSHost -ForegroundColor Yellow
    $InvokevDiskNameResults = Invoke-Command -ComputerName $PVSHost -ScriptBlock $ScriptBlockDeterminevDiskName -ArgumentList $PVSvDiskPrefix,$PVSvDiskSuffix,$PVSStore,$PVSvDiskCounterLength
    $PVSSite = $InvokevDiskNameResults[0]
    $PVSStorePath = $InvokevDiskNameResults[1]
    $NewvDiskName = $InvokevDiskNameResults[2]
    Write-Host "Determined the following vDisk name:" $NewvDiskName -ForegroundColor Yellow

# Show Provisioning Services vDisk information
    Write-Host "New vDisk information:" -ForegroundColor Cyan
    Write-Host "Name:" $NewvDiskName -ForegroundColor Cyan
    Write-Host "Store:" $PVSStore -ForegroundColor Cyan
    Write-Host "Server:" $PVSHost -ForegroundColor Cyan
    Write-Host "Site:" $PVSSite -ForegroundColor Cyan

# Sync master target device disk to Provisioning Services vDisk
    Write-Host "5. Sync local disk to vdisk" -ForegroundColor Green

    $ImagingWizard = $env:ProgramFiles + "\Citrix\Provisioning Services\ImagingWizard.exe"
	if (!(Test-Path -Path $ImagingWizard -ErrorAction SilentlyContinue)) {
        Write-Host "Citrix PVS Imaging Wizard not found." -ForegroundColor Red
        Write-Host "Has the Citrix PVS Target Device software been installed?" -ForegroundColor Red
        Write-Host "Exiting script." -ForegroundColor Red
        Return
    }																	   
    $UsedPVSStorePath = "\\" + $PVSHost + "\" + $PVSStorePath
    $FullvDiskPath = $UsedPVSStorePath + "\" + $NewvDiskName + ".vhdx"

    & $ImagingWizard P2Vhdx $NewvDiskName $UsedPVSStorePath C:
    while (Get-Process -Name ImagingWizard -ErrorAction SilentlyContinue) {
        Start-Sleep -Seconds 30
        $FileSize = [math]::Round((((Get-Item -Path $FullvDiskPath).Length)/1GB),2)
        Write-Host "Syncing to vDisk: " -NoNewline
        Write-Host $FileSize "GB" -ForegroundColor Yellow
        if ($FileSize) {
            Remove-Variable -Name FileSize
        }
    }
    Start-Sleep -Seconds 10

    if (Test-Path -Path $FullvDiskPath -ErrorAction SilentlyContinue) {
        if ((Get-Item -Path $FullvDiskPath).Length -gt 20GB) {
            Write-Host "vDisk created succesfully" -ForegroundColor Yellow
        } else {
            Write-Host "vDisk created but too small, did something go wrong?" -ForegroundColor Red
            Return
        }
    } else {
        Write-Host "vDisk not created." -ForegroundColor Red
        Write-Host "Is the PVS store path reachable from the master target device?" $UsedPVSStorePath -ForegroundColor Red
        Return
    }

# Import Provisioning Services vDisk
    Write-Host "6. Import vDisk to Provisioning Services" -ForegroundColor Green

    $ScriptBlockImportvDisk = {
        Param($PVSStore,$PVSvDiskDescription,$PVSvDiskWriteCacheSizeMB,$NewvDiskName)
        # Add date to Provisioning Services vDisk description
        $PVSvDiskDescription = $PVSvDiskDescription + " " + (Get-Date -Format "dd-MM-yyyy HH:mm")

        # Add Citrix Provisioning Services PowerShell Snapin
        $PVSSnapinDLL = $env:ProgramFiles + "\Citrix\Provisioning Services Console\Citrix.PVS.SnapIn.dll"
        Import-Module -Name $PVSSnapinDLL

        # Connect to Provisioning services
        Set-PvsConnection -Server "localhost"
        if ($PVSFarm = Get-PvsFarm) {
            Write-Host "PVS Farm found:" $PVSFarm.Name -ForegroundColor Cyan
        } else {
            Write-Host "No PVS Farm found." -ForegroundColor Red
            Return
        }
        if ($PVSSite = Get-PvsSite) {
            Write-Host "PVS Site found:" $PVSSite.Name -ForegroundColor Cyan
        } else {
            Write-Host "No PVS Site found." -ForegroundColor Red
            Return
        }

        # Check if Provisioning Services store exists
        if ($TargetPVSStore = Get-PvsStore -StoreName $PVSStore) {
            Write-Host "PVS Store found:" $TargetPVSStore.Name -ForegroundColor Cyan
        } else {
            Write-Host "PVS Store not found:" $PVSStore -ForegroundColor Red
            Return
        }

        # Import Provisioning Services vDisk
        $ImportResult = New-PvsDiskLocator -Name $NewvDiskName -StoreName $PVSStore -ServerName $env:ComputerName -SiteName $PVSSite.Name -Description $PVSvDiskDescription -VHDX
        # Change Provisioning Services vDisk write cache configuration and licensing mode
        $EditvDiskResult = Set-PvSDisk -Name $NewvDiskName -StoreName $PVSStore -SiteName $PVSSite.Name -WriteCacheType "9" -WriteCacheSize $PVSvDiskWriteCacheSizeMB -LicenseMode 2

        Return $ImportResult,$EditvDiskResult
    }

    Write-Host "Invoke command on" $PVSHost -ForegroundColor Yellow
    $InvokeImportvDisk = Invoke-Command -ComputerName $PVSHost -ScriptBlock $ScriptBlockImportvDisk -ArgumentList $PVSStore,$PVSvDiskDescription,$PVSvDiskWriteCacheSizeMB,$NewvDiskName
    $ImportResult = $InvokeImportvDisk[0]
    $EditvDiskResult = $InvokeImportvDisk[1]
# -------------------------------