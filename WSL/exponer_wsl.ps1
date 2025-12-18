<#
.EXPOSER WSL PUERTOS A RED LOCAL
Autor: Andrés Sierra
Descripción:
  Detecta la IP actual del WSL2 y crea reglas de portproxy + firewall
  para permitir acceso externo (SSH, HTTP, etc.) desde otros equipos LAN.

Ejemplo de uso:
  powershell -ExecutionPolicy Bypass -File .\exponer_wsl.ps1
#>

# ===============================
# CONFIGURACIÓN
# ===============================

# Lista de puertos a exponer
$Ports = @(22, 8000, 4566, 9000)   # 22 = SSH, 8000 = servidor web, 4566 localstack, 9000 sonar

# ===============================
# OBTENER IP INTERNA DEL WSL
# ===============================
$wslIP = (& wsl hostname -I).Trim().Split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)[0]

if (-not $wslIP) {
    Write-Host "❌ No se pudo obtener la IP interna del WSL." -ForegroundColor Red
    exit 1
}

Write-Host "✅ IP actual del WSL: $wslIP" -ForegroundColor Cyan

# ===============================
# CREAR PORTPROXY Y FIREWALL
# ===============================
foreach ($p in $Ports) {
    try {
        # Eliminar reglas antiguas (si existen)
        & netsh interface portproxy delete v4tov4 listenport=$p listenaddress=0.0.0.0 | Out-Null
    } catch {}

    # Crear nueva regla de redirección
    & netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$p connectaddress=$wslIP connectport=$p

    # Permitir el puerto en el firewall
    & netsh advfirewall firewall add rule name="WSL Port $p" dir=in action=allow protocol=TCP localport=$p | Out-Null

    # Mensaje limpio y compatible
    Write-Host ("→ Puerto {0} redirigido hacia {1}:{0}" -f $p, $wslIP) -ForegroundColor Green
}

Write-Host "🎉 Reglas creadas correctamente. WSL accesible desde la red LAN." -ForegroundColor Yellow
