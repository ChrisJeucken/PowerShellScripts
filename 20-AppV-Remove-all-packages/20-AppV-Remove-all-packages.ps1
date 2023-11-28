# SCRIPT INFO -------------------
# --- Remove all App-V packages ---
# By Chris Jeucken
# v0.1
# -------------------------------

# VARIABLES ---------------------
    $AppVFolder = $env:ProgramData + "\App-V"
# -------------------------------

# SCRIPT ------------------------
    Write-Host "Stop App-V virtual processes" -ForegroundColor Yellow
    Get-AppvVirtualProcess | Stop-Process

    Write-Host "Stop App-V client packages" -ForegroundColor Yellow
    Get-AppvClientPackage -All | Stop-AppvClientPackage

    Write-Host "Unpublish App-V client packages" -ForegroundColor Yellow
    Get-AppvClientPackage -All | Unpublish-AppvClientPackage -Global

    Write-Host "Remove App-V client packages" -ForegroundColor Yellow
    Get-AppvClientPackage -All | Remove-AppvClientPackage

    Write-Host "Take ownership of App-V folder" -ForegroundColor Yellow
    & $env:WinDir\System32\takeown.exe /f $AppvFolder /r >NUL

    Write-Host "Set full control on App-V folder" -ForegroundColor Yellow
    $ACL = Get-Acl -Path $AppVFolder
    $CurrentUser = $env:UserDomain + "\" + "$env:UserName"
    $NewACL = New-Object System.Security.AccessControl.FileSystemAccessRule("$CurrentUser","FullControl","Allow")
    $ACL.AddAccessRule($NewACL)
    Set-Acl -Path $AppVFolder $ACL

    Write-Host "Remove all files from App-V folder" -ForegroundColor Yellow
    Remove-Item -Path $AppVFolder -Recurse -Force

    Write-Host "Remove App-V registry keys" -ForegroundColor Yellow
    Remove-Item -Path HKLM:\SOFTWARE\Microsoft\AppV\Client\Packages -Recurse -Force
    Remove-Item -Path HKLM:\SOFTWARE\Microsoft\AppV\Client\Integration\Packages -Recurse -Force
    Remove-Item -Path HKLM:\SOFTWARE\Microsoft\AppV\Client\Streaming\Packages -Recurse -Force
    Remove-Item -Path HKLM:\SOFTWARE\Microsoft\AppV\MAV\Configuration\Packages -Recurse -Force

    Write-Host "Restart App-V client service" -ForegroundColor Yellow
    Restart-Service -Name AppVClient -Force
# -------------------------------
