# SCRIPT INFO -------------------
# --- Prepare local disks ---
# By Chris Jeucken
# v0.3
# -------------------------------
# Run on target machine

# SCRIPT ------------------------
    Write-Host "Primary Disk -----------"
    Write-Host "Extending primary disk to maximum size"
    $Size = (Get-PartitionSupportedSize -DriveLetter C)
    if ((Get-Partition -DriveLetter C).Size -ne $Size.SizeMax) {
        $ExtendSize = $Size.SizeMax - (Get-Partition -DriveLetter C).Size
        if ($ExtendSize -gt "2000000") {
            Resize-Partition -DriveLetter C -Size $Size.SizeMax
        } else {
            Write-Host "Extend too small, not resizing"
        }
    }

    Write-Host "Secondary Disk ---------"
    $ClearDisk = Get-Disk | Where-Object {$_.Number -eq "1"}
        if (!($ClearDisk)) {
        Write-Host "No secondary disk found. Is it even there?"
        Return
    } else {
        Write-Host "Wiping secondary disk."
        $ClearDisk | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false -ErrorAction SilentlyContinue
    }

    $NotInitializedDisk = Get-Disk | Where-Object {$_.PartitionStyle -eq "RAW"} | Select-Object -First 1
    if ($NotInitializedDisk) {
        Write-Host "---------------------------------"
        Write-Host "Disk found in 'RAW' state. Initializing disk."
        Initialize-Disk -InputObject $NotInitializedDisk -PartitionStyle MBR
    }

    $OfflineDisk = Get-Disk | Where-Object {$_.OperationalStatus -eq "Offline"} | Select-Object -First 1
    if ($OfflineDisk) {
        Write-Host "---------------------------------"
        Write-Host "Disk found in 'offline' state:"
        Write-Host $OfflineDisk
        Write-Host "Setting it online"
        Set-Disk -InputObject $OfflineDisk -IsOffline $false
    }

    Write-Host "---------------------------------"
    Write-Host "Creating partition on secondary disk."
    $SecondaryDisk = Get-Disk | Where-Object {$_.Number -eq "1"} | Select-Object -Property *
    $SecondaryDisk | New-Partition -AssignDriveLetter -UseMaximumSize -ErrorAction SilentlyContinue
    if ($SecondaryDisk.IsReadOnly -eq $True) {
        $SecondaryDisk | Set-Disk -IsReadOnly $False
    }
    $CurrentPartition = Format-Volume -DriveLetter D -FileSystem NTFS -Confirm:$false
# -------------------------------