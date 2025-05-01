@echo off
title Combined Cleanup Script
color 0A
cls

echo.
echo -------------------------------------------------------
echo                Combined Cleanup Script
echo -------------------------------------------------------
echo.

:: [1] Download and Execute the Batch Cleanup Script
echo [1/2] Downloading and executing Batch cleanup script...
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/NEZURRR/Configurations/refs/heads/main/TemporaryFileCleaner.bat', '%TEMP%\\TemporaryFileCleaner.bat')"
start /wait %TEMP%\TemporaryFileCleaner.bat

:: [2] Download and Execute the Python Cleanup Script
echo [2/2] Downloading and executing Python cleanup script...
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/NEZURRR/Configurations/refs/heads/main/SystemOptimization.py', '%TEMP%\\SystemOptimization.py')"
start /wait python %TEMP%\MemoryCleaner.py

:: Clean up
echo Cleanup complete!
del %TEMP%\TemporaryFileCleaner.bat
del %TEMP%\SystemOptimization.py

exit
