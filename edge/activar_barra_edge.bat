@echo off
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" /v HubsSidebarEnabled >nul 2>&1
if %errorlevel% neq 0 (
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" /v HubsSidebarEnabled /t REG_DWORD /d 1 /f
    echo Clave creada y barra lateral activada.
) else (
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" /v HubsSidebarEnabled /t REG_DWORD /d 1 /f
    echo Barra lateral activada.
)
exit
