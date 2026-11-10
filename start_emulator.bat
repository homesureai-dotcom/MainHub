@echo off
title Android Emulator - Medium_Phone_API_35
echo ========================================================
echo Starting Android Virtual Device with GPU Host rendering...
echo ========================================================
"C:\Android\Sdk\emulator\emulator.exe" -avd Medium_Phone_API_35 -no-snapshot-load -gpu angle_indirect
pause
