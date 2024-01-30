# SCRIPT INFO -------------------
# --- VDI non-persistent deployment script ---
# By Leon van Efferen & Chris Jeucken
# v0.99
# Various script sections borrowed from Thomas Fuhrmann
# -------------------------------------------------------
# Create target devices divided over two VMware vSphere clusters with local storage and multiple VLANs
# Run on machine with:
#   - Citrix Studio
#   - Citrix Provisioning Services Console
#   - VMware vSphere PowerCLI 6.x
# -------------------------------

# PREREQUISITES -----------------
    Write-Host "1. Import Modules and Snapins" -ForegroundColor Green
    $ErrorActionPreference = 'Stop'
# Import Active Directory PowerShell module ("Active Directory Module for Windows Powershell"-feature has to be installed on the machine where the script is executed)
    Import-Module ActiveDirectory
# Add vSphere PowerShell Snapin
    Import-Module -Name "VMware.VimAutomation.Core"  
# Install and add Citrix PowerShell Snapins
    $InstallCTXUtil = $env:systemroot + '\Microsoft.NET\Framework64\v4.0.30319\installutil.exe'
    & $InstallCTXUtil $env:programfiles + '\Citrix\Provisioning Services Console\Citrix.PVS.SnapIn.dll' | Out-Null
    Add-PSSnapin Citrix* | Out-Null
# Set decimal culture
    $DecimalCulture = New-Object System.Globalization.CultureInfo -ArgumentList "en-us",$false
    $DecimalCulture.NumberFormat.PercentDecimalDigits = 2
    Write-Host "`n"
# -------------------------------

# TRANSCENDING VARIABLES --------
    Write-Host "2. Set transcending variables" -ForegroundColor Green
# Define vCenter server hostname and credentials
	$VCHost = "vCenter01.local.lan" # <<< REPLACE THIS!
	$VCUser = "LOCAL\SVC-vCenter" # <<< REPLACE THIS!
	$VCPassword = "Password01" # <<< REPLACE THIS!
# Define Provisioning Services server hostname
	$PVSHost = "PVS1.local.lan" # <<< REPLACE THIS!
# Define XenDesktop Delivery Controller hostname
    $XDDCHost = "XDDC1.local.lan" # <<< REPLACE THIS!
# Define maximum amount of VM's per host
    $MaxVMHost = 65  # <<< REPLACE THIS!
# Define Active Directory domain for deployment
    $DomainFQDN = "LOCAL.LAN"  # <<< REPLACE THIS!
    $DomainNetBIOS = "LOCAL"  # <<< REPLACE THIS!
# Define Provisioning Services device description
	$PVSDescription = "Deployed with VDI deploy script -" # <<< REPLACE THIS!
# Define Provisioning Services site for deployment
	$PVSSite = "PVS-Site" # <<< REPLACE THIS!
# Define Provisioning Services store for deployment
    $PVSStore = "PVS-Store" # <<< REPLACE THIS!
# Define XenDesktop Hypervisor Connection name
    $XDHypervisorName = "vSphere-Hypervisor" # <<< REPLACE THIS!
# Setup current time variable
    $CurrentTime = (Get-Date).ToString('dd/MM/yyyy HH:mm:ss')   
    Set-PSBreakpoint -variable currenttime -mode Read -Action { $global:CurrentTime = (Get-Date).ToString('dd/MM/yyyy HH:mm:ss') } | Out-Null
# Define global deployment result variable
    [System.Collections.ArrayList]$GlobalDeployResults = @()
    Write-Host "`n"
# -------------------------------

# ENVIRONMENT VARIABLES ---------
	Write-Host "3. Set environment specific variables" -ForegroundColor Green
# Define template to be used for deployment
	$VMTemplateName = "VM-Template" # <<< REPLACE THIS!
# Define vSphere datacenter and clusters for deployment
    $VMDatacenterName = "Datacenter" # <<< REPLACE THIS!
	$VMClusterName1 = "Session-1" # <<< REPLACE THIS!
	$VMClusterName2 = "Session-2" # <<< REPLACE THIS!
# Define networkprefix of VDI networks
	$NetworkA = "VDI-A-" # <<< REPLACE THIS!
	$NetworkP = "VDI-P-" # <<< REPLACE THIS!
    $NetworkSize = 1000 # <<< REPLACE THIS!
# Define smaller networks (if any)
    $SmallNetwork1 = "VDI-P-01" # <<< REPLACE THIS IF NEEDED!
    $SmallNetwork1Size = 500 # <<< REPLACE THIS IF NEEDED!
# Define blocked network for deployment (if any)
    $BlockedNetwork1 = "VDI-P-02" # <<< REPLACE THIS IF NEEDED!
    $BlockedNetwork2 = "" # <<< REPLACE THIS IF NEEDED!
# Define VM name prefix and first number
	$VMPrefix = "VDI-W10-" # <<< REPLACE THIS!
    $VMNumber = 1
# Define Active Directory organizational unit for deployment
	$OUA = "Resources/VDI-W10/A" # <<< REPLACE THIS!
	$OUP = "Resources/VDI-W10/P" # <<< REPLACE THIS!
# Define Provisioning Services device collection for deployment
	$PVSCollectionA = "Acceptance" # <<< REPLACE THIS!
	$PVSCollectionP = "Production" # <<< REPLACE THIS!
# Define Provisioning Services vDisk for deployment
    $PVSvDiskA = "vDisk-Win10-v1" # <<< REPLACE THIS!
    $PVSvDiskP = "vDisk-Win10-v2" # <<< REPLACE THIS!
# Define XenDesktop Machine Catalog for deployment
    $XDCatalogNameA = "Catalog-Acceptance" # <<< REPLACE THIS!
    $XDCatalogNameP = "Catalog-Production" # <<< REPLACE THIS!
    Write-Host "`n"
# -------------------------------

# USER-DEFINED VARIABLES --------
    Write-Host "4. Ask for user-defined parameters" -ForegroundColor Green
    Write-Host "`n"

# Ask for variables
	Write-Host "For which environment do you want to deploy VDIs?" -ForegroundColor Yellow
	$Environment = Read-Host "Press A for ACCEPTANCE or P for PRODUCTION"

	If ($Environment -ne "A" -and $Environment -ne "P") {
		Write-Host "You have supplied an invalid answer." -ForegroundColor Red
		Exit
	}

	Write-Host "`n"

# Set variables
	if ($Environment -eq "A") {
        $PVSCollection = $PVSCollectionA
        $PVSvDisk = $PVSvDiskA  
		$OU = $OUA
		$XDCatalogName = $XDCatalogNameA
		$Network = $NetworkA
	}

	If ($Environment -eq "P") {
        $PVSCollection = $PVSCollectionP
        $PVSvDisk = $PVSvDiskP
		$OU = $OUP
		$XDCatalogName = $XDCatalogNameP
		$Network = $NetworkP
	}

# Ask for amount of VDIs to create
    Write-Host "How many VDIs do you want to create?" -ForegroundColor Yellow
    $Num_VMs_Total = Read-Host "Please specify the amount"
	If ($Num_VMs_Total -le 0) {
		Write-Host "Please enter number greater than 0"
		$Num_VMs_Total = 1
	}
    Write-Host "`n"

# Provide planned deployment summary
	Write-Host "VMs will be created as follows:"
	Write-Host "Amount = " -NoNewline
	Write-Host "$Num_VMs_Total VMs" -ForegroundColor Yellow
	Write-Host "Name prefix = " -NoNewline 
	Write-Host "$VM_Prefix" -ForegroundColor Yellow 
	Write-Host "Network = " -NoNewline 
	Write-Host "$Network" -ForegroundColor Yellow
	Write-Host "Provisioning Services = " -NoNewline
	Write-Host "Collection $PVSCollection in site $PVSSite with vDisk $PVSvDisk" -ForegroundColor Yellow 
	Write-Host "Active Directory OU = " -NoNewline
	Write-Host "$OU" -ForegroundColor Yellow 
	Write-Host "Hypervisor = " -NoNewline
	Write-Host "Cluster $VMClusterName1 and $VMClusterName2 in datacenter $VMDatacenterName" -ForegroundColor Yellow
	Write-Host "XenDesktop = " -NoNewline
	Write-Host "Machine catalog $XDCatalogName" -ForegroundColor Yellow
	Write-Host "--------------------------------------------"
	Write-Host "Would you like to continue?" -ForegroundColor Yellow
	$Continue = Read-Host "Press (Y)es to continue or any other key to quit."
	If ($Continue -ne "Y") {
		Write-Host "Script cancelled by user" -ForegroundColor Red
		exit
	}
# -------------------------------

# SCRIPT ------------------------
	Write-Host "5. Create machines" -ForegroundColor Green
	Write-Host "5.1 Connect to backend servers" -ForegroundColor Cyan
# Connect to vCenter server
	Write-Host "5.1.1 Connect to vCenter server" -ForegroundColor Magenta
	Set-PowerCLIConfiguration -InvalidCertificateAction "Ignore" -DisplayDeprecationWarnings:$false -Confirm:$false | out-Null
	Connect-VIServer -Server $VCHost -user $VCUser -Password $VCPassword -Force
# Connect to Provisioning Services server
	Write-Host "5.1.2 Connect to Provisioning Services server" -ForegroundColor Magenta
    Set-PvsConnection -server $PVSHost -port 54321
    Write-Host "`n"
# Read vSphere clusters
	Write-Host "5.2 Query vSphere clusters" -ForegroundColor Cyan
	$VMCluster1 = Get-Cluster -Name $VMClusterName1 | Sort-Object -Unique
	$VMCluster2 = Get-Cluster -Name $VMClusterName2 | Sort-Object -Unique
    Write-Host "`n"
# Read vSphere template 
    $VMTemplate = Get-Template -Name "$VMTemplateName" | Sort-Object -Unique
# Read XenDesktop Machine Catalog
    Write-Host "5.3 Query XenDesktop Machine Catalog" -ForegroundColor Cyan
    $XDCatalog = Get-BrokerCatalog -AdminAddress $XDDCHost -Name $XDCatalogName
# Read XenDesktop Hypervisor Connection
    Write-Host "5.4 Query XenDesktop Hypervisor Connection" -ForegroundColor Cyan
    $XDHypervisor = Get-BrokerHypervisorConnection -AdminAddress $XDDCHost -Name $XDHypervisorName
# Various stuff
	$TaskTab = @{} 
	$Counter = 0
# Set first VM name
    $VMNumber = "{0:00000}" -f $VMNumber
	$TargetVMName = $VMPrefix + $VMNumber
# Find least used network
	Write-Host "5.5 Gather all relevant networks and find least used network" -ForegroundColor Cyan
    $AllNetworks = Get-VM | Where-Object { ($_ | Get-NetworkAdapter | Where-Object {$_.networkname -match $Network -and $_.networkname -ne $BlockedNetwork1 -and $_.networkname -ne $BlockedNetwork2})} | Select-Object Name,@{N="PortGroups";E={Get-VirtualPortGroup -VM $_ | ForEach-Object {$_.Name}}}
    $PortGroups = $AllNetworks | ForEach-Object {$_.PortGroups} | Select-Object -Unique
    $AllNetworksCount = @{}
    $TempObject = @{}
    Foreach ($PortGroup in $PortGroups) {
        $TempObject.add("$PortGroup",($AllNetworks | Where-Object {$_.PortGroups -contains $PortGroup} | Measure-Object).Count)
    }
    $AllNetworksCount = $TempObject
# Create VM section	
	1..$Num_VMs_Total | ForEach-Object {
		Write-Host "5.6 Create next VM" -ForegroundColor Cyan
# Find least used vSphere host
		Write-Host "5.6.1 Find host in specified vSphere clusters with least amount of VMs on it" -ForegroundColor Magenta
		$AllVMHosts = Get-Cluster | Where-Object {$_.Name -eq $VMCluster1.Name -or $_.Name -eq $VMCluster2.Name} | Sort-Object -Unique | Get-VMHost -State Connected | Select-Object Name,@{N="NumVM";E={@(($_ | Get-Vm )).Count}}
		$AllVMHostFilter = $AllVMHosts | Where-Object {$_.NumVM -lt $MaxVMHost}
		$LeastPopulatedVMHost = $AllVMHostFilter | Sort-Object NumVM | Select-Object -First 1 
		$TargetVMHost = Get-VMHost -Name $LeastPopulatedVMHost.Name | Sort-Object -Unique
# Find local datastore on vSphere host
		Write-Host "5.6.2 Define local datastore with most space available" -ForegroundColor Magenta
		$LeastUsedDatastore = Get-VMHost -Name $LeastPopulatedVMHost.Name | Get-Datastore | Where-Object {($_.ExtensionData.Summary.MultipleHostAccess -eq $false)} | Sort-Object FreeSpaceGB | Select-Object -Last 1
# Find least used network
		Write-Host "5.6.3 Find network with least amount of VMs" -ForegroundColor Magenta
        [array]$AllNetworksPercentage1 = $AllNetworksCount.GetEnumerator() | Where-Object {$_.Name -eq $SmallNetwork1} | Select-Object Name,Value,@{L="Percentage";E={($_.Value/$SmallNetwork1Size).ToString("P",$DecimalCulture)}}
        [array]$AllNetworksPercentage2 = $AllNetworksCount.GetEnumerator() | Where-Object {$_.Name -ne $SmallNetwork1} | Select-Object Name,Value,@{L="Percentage";E={($_.Value/$NetworkSize).ToString("P",$DecimalCulture)}}
        $AllNetworksPercentage = $AllNetworksPercentage1 + $AllNetworksPercentage2
        $LeastUsedNetwork = $AllNetworksPercentage | Sort-Object Percentage | Select-Object -First 1
        $TargetNetwork = $LeastUsedNetwork.Name
# Determine first free VM name
		Write-Host "5.6.4 Determine first free VM name" -ForegroundColor Magenta
		While ((Get-VM -Name $TargetVMName -ErrorAction SilentlyContinue) -ne $null) {
			$Counter++
			$VMNumber = $Counter
			$VMNumber = "{0:00000}" -f $VMNumber
			$TargetVMName = $VMPrefix + $VMNumber
		}
# Create VM on vSphere
		Write-Host "5.6.5 Create virtual machine $TargetVMName on $($LeastPopulatedVMHost.Name) using template $VMTemplate" -ForegroundColor Magenta
		
		$TaskTab[(New-VM -Name $TargetVMName -VMHost $TargetVMHost -Template $VMTemplate -Datastore $LeastUsedDatastore -Notes "$PVSDescription $CurrentTime" -Server $VCHost).ID]=$TargetVMName 
		$TargetVMMAC = Get-NetworkAdapter -VM $TargetVMName | ForEach-Object {$_.MacAddress} | ForEach-Object {$_ -replace ':',"-"}
		Get-NetworkAdapter -VM $TargetVMName | Set-NetworkAdapter -NetworkName $TargetNetwork -Confirm:$false
        Write-Host "`n"
# Import device in Provisioning Services (Create new or alter current one when it already exists)
		Write-Host "5.6.6 Import device in Provisioning Services to collection $PVSCollection on PVS site $PVSSite" -ForegroundColor Magenta
        $ErrorActionPreference = "SilentlyContinue"
        If ((Test-Path variable:global:PVSObject) -eq $true) { 
            Remove-Variable PVSObject 
        }
        Get-PvsDevice -Name $TargetVMName | Out-Null
        If ($? -eq $false) {
            $ErrorActionPreference = "Stop"
		    New-PvsDevice -Name $TargetVMName -CollectionName $PVSCollection -SiteName $PVSSite -DeviceMac $TargetVMMAC -Description "$PVSDescription $CurrentTime" -copyTemplate -BdmBoot | Out-Null
        } Else {
            $ErrorActionPreference = "Stop"
            $PVSObject = Get-PvsDevice -Name $TargetVMName -Fields DeviceMac
            $PVSObject.DeviceMac = $TargetVMMAC
            Set-PvsDevice $PVSObject
			Set-PvsDevice -Name $TargetVMName -Description "$PVSDescription $CurrentTime"
		}
        Write-Host "`n"
# Add machine to domain through Provisioning Services
        Write-Host "5.6.7 Add machine to domain in OU $OU" -ForegroundColor Magenta
        $ErrorActionPreference = "SilentlyContinue"
        $PVSADAccount = Get-PvsADAccount -Name $TargetVMName -Domain $DomainFQDN
        If (!$PVSADAccount) {
            $ErrorActionPreference = "Stop"
            Add-PvsDeviceToDomain -Name $TargetVMName -Domain $DomainFQDN -OrganizationUnit $OU
        } Else {
            $ErrorActionPreference = "Stop"
            Remove-PvsDeviceFromDomain -Name $TargetVMName -Domain $DomainFQDN
            Add-PvsDeviceToDomain -Name $TargetVMName -Domain $DomainFQDN -OrganizationUnit $OU
        }
        Write-Host "`n"
# Link vDisk to Provisioning Services device
        Write-Host "5.6.8 Add vDisk $PVSvDisk to device in Provisioning Services" -ForegroundColor Magenta
		$PVSObject2 = Get-PvsDevice -Name $TargetVMName | Get-PvsDiskLocator
		If ($PVSObject2) {
			Get-PvsDevice -Name $TargetVMName | Remove-PvsDiskLocatorFromDevice -DiskLocatorId $PVSObject2.DiskLocatorId
		}
        Add-PvsDiskLocatorToDevice -DeviceName $TargetVMName -DiskLocatorName $PVSvDisk -SiteName $PVSSite -StoreName $PVSStore
        Write-Host "`n"
# Add machine to XenDesktop Machine Catalog
        Write-Host "5.6.9 Add machine to XenDesktop Machine Catalog $XDCatalogName" -ForegroundColor Magenta
        Write-Host "Wait 15 seconds"
        $ErrorActionPreference = "Continue"
        Start-Sleep -s 15
        New-VIProperty -ObjectType VirtualMachine -Name Cluster -Value {$Args[0].VMHost.Parent} -Force | Out-Null
        $VMObject1 = Get-VM | Select-Object -Property Name,Cluster | Where-Object {($_.Name -like "$TargetVMName")}
        $VMDeployCluster = $VMObject1.Cluster.Name | Sort-Object -Unique
        $VMDeployPath = "XDHyp:\Connections\$XDHypervisorName\$VMDatacenterName\$VMDeployCluster.cluster\$TargetVMName.vm"
        $VMObject2 = Get-Item $VMDeployPath -AdminAddress $XDDCHost
        Get-Item $VMDeployPath -AdminAddress $XDDCHost | Out-Null
        New-BrokerMachine -CatalogUid $XDCatalog.Uid -HypervisorConnectionUid $XDHypervisor.Uid -HostedMachineId $VMObject2.Id -MachineName $DomainNetBIOS\$TargetVMName | Out-Null
        If ($?) { 
            Write-Host "Add to catalog SUCCESS"
        } Else {
            Write-Host "Add to catalog FAIL. Trying again in 30 seconds."
            Start-Sleep -s 30
            New-BrokerMachine -CatalogUid $XDCatalog.Uid -HypervisorConnectionUid $XDHypervisor.Uid -HostedMachineId $VMObject2.Id -MachineName $DomainNetBIOS\$TargetVMName | Out-Null
            If ($?) {
                Write-Host "Add to catalog SUCCESS"
            } Else {
                Write-Host "Add to catalog FAIL. Trying again in 30 seconds."
                Start-Sleep -s 30
                New-BrokerMachine -CatalogUid $XDCatalog.Uid -HypervisorConnectionUid $XDHypervisor.Uid -HostedMachineId $VMObject2.Id -MachineName $DomainNetBIOS\$TargetVMName |Out-Null
                If ($?) {
                    Write-Host "Add to catalog SUCCESS"
                } Else {
                    Write-Host "Add to catalog FAIL. Quitting script."
                    exit
                }
            }
        }
# Alter network table
        Write-Host "5.6.10 Alter current network table" -ForegroundColor Magenta
		$TempHashTable = @{}
		$AllNetworksCount.GetEnumerator() | Where-Object {$_.Name -eq $TargetNetwork} | ForEach-Object {$TempHashTable[$_.Name]=$_.value +1}
		$AllNetworksCount.Set_Item(($TempHashTable.GetEnumerator()).Name,($TempHashTable.GetEnumerator() | ForEach-Object {$_.Value}))
# Add machine to global deployment summary
        $GlobalDeployResults.add("$TargetVMName") | Out-Null
# Show deployment summary and move to next VM (if any)
        Write-Host "5.6.11 VM successfully created from $VMTemplate" -ForegroundColor Magenta
        Write-Host "Name = $TargetVMName"
        Write-Host "Network = $TargetVMMAC in $TargetNetwork"
        Write-Host "Provisioning Services = Collection $PVSCollection in site $PVSSite with vDisk $PVSvDisk"
        Write-Host "Active Directory OU = $OU"
        Write-Host "Hypervisor = Host $TargetVMHost on datastore $LeastUsedDatastore in cluster $VMDeployCluster"
        Write-Host "XenDesktop = Machine catalog $XDCatalogName"
        Write-Host "-------------------------------------------------------------------" -ForegroundColor Magenta
        Write-Host "On to next VM (if any)" -ForegroundColor Cyan
        Write-Host "`n"
    }
# -------------------------------

# CLEAN UP ----------------------
    Write-Host "6. Script completed - Cleaning up" -ForegroundColor Green
	$TaskTab = @{} 
 	Disconnect-VIServer * -Confirm:$false
    Write-Host "--- DONE ---" -ForegroundColor Green
    Write-Host "`n"
    Write-Host "Global deployment results:" -ForegroundColor Yellow
    $GlobalDeployResults
    Read-Host "--- Press ENTER to close ---"
    # -------------------------------