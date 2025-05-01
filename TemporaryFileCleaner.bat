@echo off
title XACO - Custom Cleanup v2
color 0A
cls

echo.
echo -------------------------------------------------------
echo                XACO: Custom Cleanup v2                 
echo -------------------------------------------------------
echo.

:: [1] Delete custom registry key
echo [1/10] Deleting custom registry key...
reg delete "HKCU\severe v2" /f >nul 2>&1

:: [2] Delete file at C:\v2
echo [2/10] Deleting C:\v2 file...
del /f /q "C:\v2" >nul 2>&1

:: [3] Mass registry deletion
echo [3/10] Running advanced registry cleanup...
reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store" /f /va >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\WinRAR\ArcHistory" /f /va >nul 2>&1
reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU\dll" /f /va >nul 2>&1
reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU\exe" /f /va >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" /f /va >nul 2>&1
reg delete "HKEY_CLASSES_ROOT\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /f /va >nul 2>&1
reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery" /f /va >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist" /f /va >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\BagMRU" /f /va >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\Bags" /f /va >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\ShellNoRoam\BagMRU" /f /va >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\ShellNoRoam\Bags" /f /va >nul 2>&1
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search\RecentApps" /f /va >nul 2>&1
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\bam\UserSettings" /f /va >nul 2>&1

:: [4] USN Journal and Event Logs
echo [4/10] Cleaning USN Journal and Event Logs...
taskkill /F /FI "SERVICES eq eventlog" >nul
timeout /t 2 >nul
fsutil usn deletejournal /d C: >nul
fsutil usn deletejournal /d D: >nul
timeout /t 2 >nul
del /f /q "C:\Windows\System32\winevt\Logs\Application.evtx" >nul
timeout /t 2 >nul
sc start eventlog >nul
echo Journal Shit on
echo Journal Shit on
echo Journal Shit on
echo Journal Shit on
echo Journal Shit on
echo Journal Shit on

:: [5] Delete prefetch files
echo [5/10] Deleting prefetch files...
del /q /f "%SystemRoot%\Prefetch\*.*" >nul 2>&1

:: [6] Clean user temp
echo [6/10] Cleaning user temp files...
del /q /f "%temp%\*" >nul 2>&1
rd /s /q "%temp%" >nul 2>&1

:: [7] Clean system temp
echo [7/10] Cleaning system temp files...
del /q /f "C:\Windows\Temp\*" >nul 2>&1
rd /s /q "C:\Windows\Temp" >nul 2>&1

:: [8] Clean recent files
echo [8/10] Cleaning recent items...
del /q /f "%APPDATA%\Microsoft\Windows\Recent\*" >nul 2>&1

:: [9] Clear admin credentials
echo [9/10] Clearing stored admin credentials...
for /f "tokens=3" %%i in ('cmdkey /list ^| findstr Target') do cmdkey /delete %%i >nul 2>&1

:: [10] Clean NVIDIA ConsoleHost and PowerShell history
echo [10/10] Cleaning NVIDIA and PowerShell history...
powershell -Command "$HistoryFilePath = Join-Path ([Environment]::GetFolderPath('UserProfile')) -ChildPath 'ConsoleHost_history.txt'; Remove-Item -Path $HistoryFilePath -Force -ErrorAction SilentlyContinue"

echo.
echo -------------------------------------------------------
echo                Custom Cleanup Complete!                
echo -------------------------------------------------------
timeout /t 3 /nobreak >nul
exit
