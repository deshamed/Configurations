# Define the paths and registry keys to be cleaned
$pathsToDelete = @(
    "C:\assembly",
    "C:\v2",
    "$env:LOCALAPPDATA\dependencies",
    "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Recent"
)

$registryKeysToDelete = @(
    "HKCU\Software\severe v2",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExplorer\LastVisitedPidlMRU",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MuiCache",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Appswitched",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Program Compatibility Assistant\History",
    "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache",
    "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU",
    "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU\exe",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU\dll"
)

# Keywords for Prefetch cleaning
$prefetchKeywords = @(
    "authenticator",
    "software",
    "assembly",
    "wscript",
    "reg",
    "regedit",
    "taskkill",
    "smartscreen",
    "spotify",
    "discord",
    "powershell",
    "cmd"
)

# Delete specified paths
foreach ($path in $pathsToDelete) {
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Deleted: $path"
    }
}

# Delete specified registry keys
foreach ($key in $registryKeysToDelete) {
    if (Test-Path $key) {
        Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Deleted Registry Key: $key"
    }
}

# Clean Prefetch folder of specific .pf files
$prefetchPath = "C:\Windows\Prefetch"
if (Test-Path $prefetchPath) {
    Get-ChildItem -Path $prefetchPath -Filter "*.pf" | ForEach-Object {
        if ($prefetchKeywords -contains ($_.Name -split '\.')[0]) {
            Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
            Write-Host "Deleted Prefetch File: $($_.Name)"
        }
    }
}

# Delete BAM UserSettings
$bamPath = "$env:LOCALAPPDATA\Microsoft\Windows\BAM"
if (Test-Path $bamPath) {
    Remove-Item -Path "$bamPath\UserSettings.bin" -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted BAM UserSettings"
}

# Clean thumbnail and icon caches
$iconCachePath = "$env:LOCALAPPDATA\IconCache.db"
if (Test-Path $iconCachePath) {
    attrib -h -s -r $iconCachePath >nul 2>&1
    Remove-Item -Path $iconCachePath -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted Icon Cache: $iconCachePath"
}

$explorerIconCachePath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db"
if (Test-Path $explorerIconCachePath) {
    foreach ($file in Get-ChildItem -Path $explorerIconCachePath) {
        attrib -h -s -r $file.FullName >nul 2>&1
        Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
        Write-Host "Deleted Explorer Icon Cache: $($file.Name)"
    }
}

$thumbnailCachePath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db"
if (Test-Path $thumbnailCachePath) {
    Remove-Item -Path $thumbnailCachePath -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "Deleted Thumbnail Cache"
}

# Clean Jump Lists
$jumpListPath = "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations"
if (Test-Path $jumpListPath) {
    Remove-Item -Path $jumpListPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleaned Jump Lists"
}

# Taskkill Explorer and clear system memory
taskkill /f /im explorer.exe
Start-Sleep -Seconds 2
powershell -Command "& {Add-Type -AssemblyName System.DirectoryServices.AccountManagement; Start-Sleep -Seconds 2; [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers();}" >nul 2>&1

# Restart Explorer
Start-Process explorer.exe

# Verify Explorer is running and restart if necessary
Start-Sleep -Seconds 2
if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
    Start-Process explorer.exe
}

Write-Host "Cleaning complete."

# THE ORIGINAL POWERSHELL CLEANING SCRIPT THAT I'VE SAVED HERE IF ANYBODY WANTS A TEMPLATE/DEMO. ITS REALLY BAD AND THUMBNAIL + ICON CACHE CLEANING SUCKS ENTIRELY AND WILL GIVE YOU ERRORS, BESIDES THAT, EVERYTHING ELSE WORKS.
