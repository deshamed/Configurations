# Define the paths and registry keys to be cleaned
$pathsToDelete = @(
    "C:\assembly",
    "C:\v2",
    "$env:LOCALAPPDATA\dependencies",
    "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Recent"
)

$registryKeysToDelete = @(
    "HKCU\Software\severe v2",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU\txt",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ShellBags",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartPage",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExplorer\LastVisitedPidlMRU",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MuiCache",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Appswitched",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Program Compatibility Assistant\History"
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
    "smartscreen"
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
del "%localappdata%\Microsoft\Windows\Explorer\thumbcache_*.db" /f /q
del "%localappdata%\IconCache.db" /f /q
Write-Host "Cleaned thumbnail and icon caches"

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
