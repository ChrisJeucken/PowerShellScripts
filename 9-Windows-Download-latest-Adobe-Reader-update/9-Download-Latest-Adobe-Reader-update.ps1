# SCRIPT INFO -------------------
# --- Download latest Adobe Reader DC (.MSP) ---
# By Chris Jeucken
# v0.1
# -------------------------------
# Run on Target Device
# Internet access required (direct or through proxy)

# VARIABLES ---------------------
    $TargetFolder = $env:TEMP + "\AdobeReader"
    $TargetFilePrefix = "AcroRdrDC"
    $TargetFileSuffix = "_en_US.exe"
    $AdobeReaderVersionRepository = "https://rdc.adobe.io/reader/products"
    $AdobeReaderDownloadRepository = "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC"
    $Proxy = "" # <--- Leave empty if you don't want to use a proxy
    $ShowProgress = $false # <--- Disabling progress greatly speeds up the download
# -------------------------------

# SCRIPT ------------------------
    $TargetURL = $AdobeReaderVersionRepository + "?lang=en&site=enterprise&os=Windows 10&api_key=dc-get-adobereader-cdn"
    if ($Proxy) {
        $TargetVersion = (Invoke-RestMethod -Uri $TargetURL -Proxy $Proxy).Products.Reader.Version
    } else {
        $TargetVersion = (Invoke-RestMethod -Uri $TargetURL).Products.Reader.Version
    }
    if (!($TargetVersion)) {
        Write-Host "*** No target version could be determined, please check Internet connectivity"
        Return
    }
    $TargetVersionShort = $TargetVersion.Replace(".","")
    Write-Host "*** Adobe Reader DC version $TargetVersion found, proceeding to download..."

    if (!(Test-Path -Path $TargetFolder -ErrorAction SilentlyContinue)) {
        New-Item -Path $TargetFolder -ItemType Directory -Force
    }
    $TargetFile = $TargetFilePrefix + $TargetVersionShort + $TargetFileSuffix
    $TargetFileDestination = $TargetFolder + "\" + $TargetFile
    $DownloadURI = $AdobeReaderDownloadRepository + "/" + $TargetVersionShort + "/" + $TargetFile

    if (Test-Path -Path $TargetFileDestination -ErrorAction SilentlyContinue) {
        Write-Host "*** Found existing file, removing..."
        Remove-Item -Path $TargetFileDestination -Force
    }
    Write-Host "*** Downloading Adobe Reader update file: $TargetFile"
    if ($ShowProgress) {
        $ProgressPreference = "Continue"
    } else {
        $ProgressPreference = "SilentlyContinue"
    }
    if ($Proxy) {
        Invoke-WebRequest -Uri $DownloadURI -OutFile $TargetFileDestination -Proxy $Proxy    
    } else {
        Invoke-WebRequest -Uri $DownloadURI -OutFile $TargetFileDestination
    }
    Write-Host "*** Download Adobe Reader update file completed: $TargetFileDestination"
# -------------------------------