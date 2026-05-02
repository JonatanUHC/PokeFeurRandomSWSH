@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%"
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%CustomSwShRandomizer.ps1"
if errorlevel 1 (
    echo.
    echo Le randomizer a plante. Lis l'erreur ci-dessus puis envoie-moi le message si besoin.
    pause
)
popd
endlocal
