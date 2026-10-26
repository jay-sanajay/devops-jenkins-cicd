# ==============================================================================
# Windows Stop Script: stop.ps1
# Gracefully stops the background Flask application
# ==============================================================================

[CmdletBinding()]
param(
    [int]$Port = 5000
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$PidFile = "$RootDir\app.pid"

if (Test-Path $PidFile) {
    $TargetPid = (Get-Content $PidFile -ErrorAction SilentlyContinue).Trim()
    if ($TargetPid -match '^\d+$') {
        Write-Host "Stopping application process (PID: $TargetPid)..." -ForegroundColor Yellow
        try {
            $procId = [int]$TargetPid
            Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
            Write-Host "Application process $procId stopped successfully." -ForegroundColor Green
        } catch {
            Write-Host "Process $TargetPid was not running or could not be stopped: $_" -ForegroundColor Yellow
        }
    }
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "No app.pid file found. Checking port $Port for listening processes..." -ForegroundColor Cyan
    try {
        $conns = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        foreach ($conn in $conns) {
            if ($conn.OwningProcess -and $conn.OwningProcess -ne 0) {
                Write-Host "Stopping process PID $($conn.OwningProcess) bound to port $Port..." -ForegroundColor Yellow
                Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Write-Host "Could not query port $Port."
    }
}
