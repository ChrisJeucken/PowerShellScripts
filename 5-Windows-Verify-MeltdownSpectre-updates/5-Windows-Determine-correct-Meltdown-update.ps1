# SCRIPT INFO -------------------
# --- Determine correct Intel Meltdown/Spectre update ---
# By Chris Jeucken
# v0.1
# -------------------------------------------------------
# Run on target machine
# -------------------------------

# SCRIPT ------------------------
    # Check if 64-bit
    $OSArchitecture64 = [Environment]::Is64BitOperatingSystem

    # Get Windows version
    $OSVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName

    # Get ReleaseId (if Windows Server 2016 or Windows 10)
    if ($OSVersion -like "Windows Server 2016*" -and "Windows 10*") { 
        $OSReleaseId = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId
    }

    # Set correct update for Windows version
    if ($OSArchitecture64 -eq "True") {
        if ($OSVersion -like "Windows Server 2008*" -and "Windows 7*") { $Update = "windows6.1-kb4056897-x64_2af35062f69ce80c4cd6eef030eda31ca5c109ed.msu" }
        if ($OSVersion -like "Windows Server 2012*" -and "Windows 8*") { $Update = "windows8.1-kb4056898-v2-x64_754f420c1d505f4666437d06ac97175109631bf2.msu"}
        if ($OSVersion -like "Windows Server 2016*" -and "Windows 10*") {
            if ($OSReleaseId -eq "1709") { $Update = "windows10.0-kb4056892-x64_a41a378cf9ae609152b505c40e691ca1228e28ea.msu" }
            if ($OSReleaseId -eq "1703") { $Update = "windows10.0-kb4056891-x64_59726a743b65a221849572757d660f624ed6ca9e.msu" }
            if ($OSReleaseId -eq "1607") { $Update = "windows10.0-kb4056890-x64_1d0f5115833be3d736caeba63c97cfa42cae8c47.msu" }
            if ($OSReleaseId -eq "1511") { $Update = "windows10.0-kb4056888-x64_4477b9725a819afd8abc3e5b1f6302361005908d.msu" }
            if ($OSReleaseId -eq "1507") { $Update = "windows10.0-kb4056893-x64_d2873bb43413d31871ccb8fea213a96a714a6f87.msu" }
        }
    }
    
    if ($OSArchitecture64 -eq "False") {
        if ($OSVersion -like "Windows 7*") { $Update = "windows6.1-kb4056897-x86_bb612f57e082c407b8cdad3f4900275833449e71.msu" }
        if ($OSVersion -like "Windows 8*") { $Update = "windows8.1-kb4056898-v2-x86_f0781f0b1d96c7b12a18c66f99cf94447b2fa07f.msu" }
        if ($OSVersion -like "Windows 10*") {
            if ($OSReleaseId -eq "1709") { $Update = "windows10.0-kb4056892-x86_d3aaf1048d6f314240b8c6fe27932aa52a5e6733.msu" }
            if ($OSReleaseId -eq "1703") { $Update = "windows10.0-kb4056891-x86_5e2d98a5cc9d8369a4acd3b3115789a6b1342159.msu" }
            if ($OSReleaseId -eq "1607") { $Update = "windows10.0-kb4056890-x86_078b34bfdc198bee26c4f13e2e45cb231ba0d843.msu" }
            if ($OSReleaseId -eq "1511") { $Update = "windows10.0-kb4056888-x86_0493b29664aec0bfe7b934479afb45fe83c59cbe.msu" }
            if ($OSReleaseId -eq "1507") { $Update = "windows10.0-kb4056893-x64_d2873bb43413d31871ccb8fea213a96a714a6f87.msu" }
        }
    }

    # Print update    
    Write-Host $Update
# -------------------------------