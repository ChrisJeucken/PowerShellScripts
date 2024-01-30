# SCRIPT INFO -------------------
# Script that installs all Visual C++ Redistributables available in the Citrix XenDesktop installation files
# Run on a machines that will receive a Virtual Delivery Agent
# By Chris Jeucken
# -------------------------------

# PREREQUISITES -----------------
	Write-Host "1. Do prerequisite actions"
# Set Execution Policy Bypass
	Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
# Set Stop on error
	$ErrorActionPreference = "Stop"
# Disable open file security warnings
	$env:SEE_MASK_NOZONECHECKS = 1
    Write-Host "`n"
# -------------------------------

# VARIABLES ---------------------
	Write-Host "2. Set variables"
# User defined variables
	$XDSource = "\\dom1\Software\Citrix\XenDesktop 7.15"
# Pre-defined variables
# Four numbers (Year) variable
	[regex]$FourNumbers="\d{4}"
# Visual C++ Redistributable version variable
   	$VCVersions = New-Object System.Collections.Generic.List[System.Object]
# Unattended installation switches Visual C++ Redistributable
	$VC2008Switches = "/q"
	$VC2010Switches = "/q norestart"
	$VC2012Switches = "/q norestart"
	$VC20xxSwitches = "/install /quiet /norestart"
    Write-Host "`n"
# -------------------------------
	
# SCRIPT ------------------------
	Write-Host "3. Run actual script - Install all available Visual C++ Redistributables"
    Write-Host "`n"
# Query Operation System architecture
	$Architecture = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
# Query available Visual C++ Redistributable versions
	$Installer = Get-ChildItem -Path "$XDSource\Support\VCRedist_*"
	foreach ($Folder in $Installer.Name) {
		$VCVersions.Add($FourNumbers.match($Folder).Value)
	}
	$VCVersions = $VCVersions | select -Unique	
	
# Install all available Visual C++ Redistributables - 32-bit & 64-bit
    if(($Architecture) -like "64-bit") {
        foreach ($Installer in Get-ChildItem -Path "$XDSource\Support\VCRedist_*" -Recurse -Include *x64.exe, *x86.exe) { 
            foreach ($Version in $VCVersions) {
                if (($Installer.FullName) -like "*VcRedist_$Version*" ) {
                    $InstallerInfo = $Installer.Directory.Name + "\" + $Installer.Name
				    if ($Version -gt 2012) { $Switches = $VC20xxSwitches }
					if ($Version -lt 2013) { $Switches = Get-Variable VC${Version}Switches -ValueOnly }
					Write-Host Install Visual C++ Redistributable $Version - $InstallerInfo
                    Start-Process $Installer.FullName $Switches -Wait
                }
            }
        }
    }

# Install all available Visual C++ Redistributables - 32-bit
    if(($Architecture) -like "32-bit") {
        foreach ($Installer in Get-ChildItem -Path "$XDSource\Support\VCRedist_*" -Recurse -Include *x64.exe, *x86.exe) { 
            foreach ($Version in $VCVersions) {
                if (($Installer.FullName) -like "*VcRedist_$Version*" ) {
                    $InstallerInfo = $Installer.Directory.Name + "\" + $Installer.Name
				    if ($Version -gt 2012) { $Switches = $VC20xxSwitches }
					if ($Version -lt 2013) { $Switches = Get-Variable VC${Version}Switches -ValueOnly }
					Write-Host Install Visual C++ Redistributable $Version - $InstallerInfo
                    Start-Process $Installer.FullName $Switches -Wait
                }
            }
        }
    }
# -------------------------------