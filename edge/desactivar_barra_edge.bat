@echo off
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" /v HubsSidebarEnabled >nul 2>&1
if %errorlevel% equ 0 (
    reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" /v HubsSidebarEnabled /f
    echo Clave eliminada y barra lateral desactivada.
)
exit
