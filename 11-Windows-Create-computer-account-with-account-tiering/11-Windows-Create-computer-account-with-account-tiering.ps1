# SCRIPT INFO -------------------
# --- Create Master Target Device computer account with account tiering ---
# By Chris Jeucken
# v0.4
# -------------------------------
# Run on target machine
# ------------------------------- 

# VARIABLES ---------------------
    $MachineName = $env:COMPUTERNAME
    $TargetOU = "OU=Computers,DC=domain,DC=local"
    $ComputerAccountDescription = "Computer description"
    $DomainName = "domain.local"
# Credentials
    $Tier1Usage = "Yes"
    $Tier1Username = "DOMAIN\Admin"
    $Tier1Password = "" # <-- TODO: Convert to encrypted password
    $Tier2Username = "DOMAIN\LocalAdmin"
    $Tier2Password = ""  # <-- TODO: Convert to encrypted password
# -------------------------------

# PREREQUISITES -----------------
# PowerShell modules
    Write-Host "*** Setup PowerShell module ***"
    $PSModule = "RSAT-AD-PowerShell"
    if ((Get-WindowsFeature -Name $PSModule).InstallState -ne "Installed") {
        Write-Host "Active Directory PowerShell module not installed. Installing..."
        if (!(Install-WindowsFeature -Name $PSModule)) {
            Write-Host "Active Directory PowerShell module installation failed. Stopping script..."
            Return
        }
    }

# Create credentials object
    Write-Host "*** Setup credentials ***"
    if ($Tier1Usage -eq "Yes") {
    # Use tier 1 account
        Write-Host "Specified usage of tier 1 credentials. Using account $Tier1Username."
        $Tier1PasswordSecure = ConvertTo-SecureString $Tier1Password -AsPlainText -Force
        $ADCredentials = New-Object System.Management.Automation.PSCredential ($Tier1Username,$Tier1PasswordSecure)
        $DomainUsername = $Tier1Username
    } else {
    # Use tier 2 account
        Write-Host "Using account $Tier2Username."
        $Tier2PasswordSecure = ConvertTo-SecureString $Tier2Password -AsPlainText -Force
        $ADCredentials = New-Object System.Management.Automation.PSCredential ($Tier2Username,$Tier2PasswordSecure)
        $DomainUsername = $Tier2Username
    }

# Domain Controller
    Write-Host "*** Determine domain controller ***"
    $ADDCIPInfo = Test-NetConnection -ComputerName $DomainName
    $ADDCHostname = (Resolve-DnsName -Name $ADDCIPInfo.RemoteAddress).NameHost
    if (!(Get-ADDomainController -Server $ADDCHostname -Credential $ADCredentials)) {
        Write-Host "No domain controller found, is domain $DomainName reachable from this machine?"
        Return
    } else {
        Write-Host "Found domain controller $ADDCHostname at" $ADDCIPInfo.RemoteAddress
    }
# -------------------------------

# SCRIPT ------------------------
# Set intial action (which is 'do diddly squat')
    $CreateAccountRequired = $false

# Check if organizational unit exists
    Write-Host "*** Check if organizational unit exists ***"
    try {
        Get-ADOrganizationalUnit -Identity $TargetOU -Server $ADDCHostname -Credential $ADCredentials
    } catch {
        Write-Host "Organizational unit $TargetOU does not exist. Please correct this."
        Return
    }

# Check if computer account already exists
    if (!($CreateAccountRequired)) {
        Write-Host "*** Check if computer account already exists ***"
        try {
            $MTDAccount = Get-ADComputer -Identity $MachineName -Server $ADDCHostname -Credential $ADCredentials
        } catch {
            Write-Host "Computer account $MachineName does not exist. Computer account creation required."
            $CreateAccountRequired = $true
        }
        if ($MTDAccount) {
            Write-Host "Computer account already exists:" $MTDAccount.Name
        }
    }

# Check if computer account is in the correct OU
    if (!($CreateAccountRequired)) {
        Write-Host "*** Check if computer account is in the correct OU ***"
        $MTDAccount = Get-ADComputer -Identity $MachineName -Server $ADDCHostname -Credential $ADCredentials
        if ($MTDAccount.DistinguishedName -notlike "*$TargetOU") {
            Write-Host "Computer account is not in the correct OU ($TargetOU). Computer account recreation required."
            $DeleteAccountRequired = $true
            $CreateAccountRequired = $true
        } else {
            Write-Host "Computer account is in the correct OU:" $TargetOU
        }
    }

# Check if computer account has the correct owner
    if (!($CreateAccountRequired)) {
        Write-Host "*** Check if computer account has the correct owner ***"
        $ADObjectOwner = (Get-ADComputer -Identity $MachineName -Properties ntSecurityDescriptor -Server $ADDCHostname -Credential $ADCredentials | Select-Object -ExpandProperty ntSecurityDescriptor).Owner
        if ($ADObjectOwner -like "O:S*") {
            $ADObjectOwner = $ADObjectOwner.Replace("O:","")
            $ADObjectOwnerUserName = (Get-ADUser -Identity $ADObjectOwner -Server $ADDCHostname -Credential $ADCredentials -Properties SamAccountName).SamAccountName
            $DomainNameNetBIOS = (Get-ADDomain -Identity $DomainName -Server $ADDCHostname -Credential $ADCredentials).NetBIOSName
            $ADObjectOwner = "$DomainNameNetBIOS\$ADObjectOwnerUserName"
        }
        if ($ADObjectOwner -ne $DomainUsername) {
            Write-Host "Computer account does not have the correct owner ($DomainUserName). Computer account recreation required."
            $DeleteAccountRequired = $true
            $CreateAccountRequired = $true
        } else {
            Write-Host "Computer account has the correct owner:" $ADObjectOwner
        }
    }

# Create computer account if needed.
    if ($CreateAccountRequired) {
        Write-Host "*** (Re)creating computer account ***"
        if ($DeleteAccountRequired) {
            Remove-ADComputer -Identity $MachineName -Server $ADDCHostname -Credential $ADCredentials -Confirm:$false -Verbose    
            Start-Sleep -Seconds 10
        }
        New-ADComputer -Name $MachineName -SAMAccountName $MachineName -Path $TargetOU -Enabled $true -Server $ADDCHostname -Credential $ADCredentials -Description $ComputerAccountDescription -Verbose
        Write-Host "Computer account $MachineName created."
        Start-Sleep -Seconds 10
        Write-Host "*** Verify computer account owner ***"
        $ADObjectOwnerVerify = (Get-ADComputer -Identity $MachineName -Properties ntSecurityDescriptor -Server $ADDCHostname -Credential $ADCredentials | Select-Object -ExpandProperty ntSecurityDescriptor).Owner
        if ($ADObjectOwnerVerify -like "O:S*") {
            Write-Host "Current owner SID:" $ADObjectOwnerVerify
            $ADObjectOwnerVerify = $ADObjectOwnerVerify.Replace("O:","")
            $ADObjectOwnerVerifyUserName = (Get-ADUser -Identity $ADObjectOwnerVerify -Server $ADDCHostname -Credential $ADCredentials -Properties SamAccountName).SamAccountName
            $DomainNameNetBIOS = (Get-ADDomain -Identity $DomainName -Server $ADDCHostname -Credential $ADCredentials).NetBIOSName
            $ADObjectOwnerVerify = "$DomainNameNetBIOS\$ADObjectOwnerVerifyUserName"
            Write-Host "SID resolves to:" $ADObjectOwnerVerify
        }
        if ($ADObjectOwnerVerify -eq $DomainUserName) {
            Write-Host "Computer acount owner matches the domain-join account."
        } elseif ($ADObjectOwnerVerify -like "*\Domain Admins") {
            Write-Host "Computer acount owner is set to 'Domain Admins'. This is not a problem."
        } else {
            Write-Host "Computer account owner still not correct."
        }
        Write-Host "Current computer account owner:" $ADObjectOwnerVerify
        Write-Host "Current account to perform domain-join:" $DomainUsername
        Write-Host "Waiting 2 minutes for replication."
        Start-Sleep -Seconds 120
    }

# Join computer to domain
    Write-Host "*** Join computer to domain ***"
    Add-Computer -DomainName $DomainName -Server $ADDCHostname -Credential $ADCredentials -Verbose
# -------------------------------