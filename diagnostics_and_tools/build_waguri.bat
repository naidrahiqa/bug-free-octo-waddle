@echo off
setlocal
cd /d "%~dp0"
del waguri-my-bini-update.zip 2>nul
"C:\Program Files\7-Zip\7z.exe" a -tzip waguri-my-bini-update.zip module.prop META-INF customize.sh post-fs-data.sh service.sh sepolicy.rule system 2>nul
"C:\Program Files\7-Zip\7z.exe" a -tzip waguri-my-bini-update.zip waguri_my_bini\watchdog.sh >nul
if exist waguri-my-bini-update.zip (
    move /y waguri-my-bini-update.zip Waguri_My_Bini_v1.3.2-ksunext.zip >nul
    echo built Waguri_My_Bini_v1.3.2-ksunext.zip
    dir Waguri_My_Bini_v1.3.2-ksunext.zip
) else (
    echo BUILD FAILED
)
endlocal
