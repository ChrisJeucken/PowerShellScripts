# SCRIPT INFO -------------------
# --- Remove users group from NTFS permissions on specific folders ---
# By Chris Jeucken
# v0.1
# -------------------------------

# VARIABLES ---------------------
    $TargetFolders = "C:\LOG",
                     "C:\TEMP"
    $TargetGroup = "BUILTIN\Users"
# -------------------------------

# SCRIPT ------------------------
# Change ACL for each folder
    foreach ($TargetFolder in $TargetFolders) {
        if (Test-Path -Path $TargetFolder -ErrorAction SilentlyContinue) {
# Get current ACL for target folder
            $ACL = Get-Acl -Path $TargetFolder
# Disable inheritance and retain rights
            $ACL.SetAccessRuleProtection($true,$true)
            Set-Acl -Path $TargetFolder -AclObject $ACL
# Remove BUILTIN\Users from permissions
            foreach ($AccessGroup in $ACL.Access) {
                if ($AccessGroup.IdentityReference.Value -eq $TargetGroup) {
                    $ACL.RemoveAccessRule($AccessGroup) | Out-Null
                }
            }
            Set-Acl -Path $TargetFolder -AclObject $ACL
            Remove-Variable -Name ACL
        }
    }
# -------------------------------
