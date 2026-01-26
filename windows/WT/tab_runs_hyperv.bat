@echo off
set VM_NAME=docker_ubuntu
set VM_USER=asierra
set VM_IP=172.19.110.30

REM Comprobar estado de la VM
for /f "tokens=*" %%i in ('powershell -command "(Get-VM -Name '%VM_NAME%').State"') do set VM_STATE=%%i

if /I "%VM_STATE%" NEQ "Running" (
    echo Iniciando la máquina virtual "%VM_NAME%"...
    powershell -command "Start-VM -Name '%VM_NAME%'"
)

REM Esperar hasta que el puerto SSH esté disponible
echo Esperando que SSH esté disponible en %VM_IP%:22 ...
:WAIT_FOR_SSH
ping -n 2 %VM_IP% >nul
powershell -Command ^
"$client = New-Object Net.Sockets.TcpClient; ^
$connected = $false; ^
try { $client.Connect('%VM_IP%', 22); $connected = $client.Connected } ^
catch {} ^
finally { $client.Close(); if (-not $connected) { exit 1 } }"

if errorlevel 1 (
    timeout /t 2 >nul
    goto WAIT_FOR_SSH
)

echo Conectando por SSH a %VM_USER%@%VM_IP%...
start "" ssh %VM_USER%@%VM_IP%
