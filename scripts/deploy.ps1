# ==============================================================================
# Windows Deployment Script: deploy.ps1
# Deploys Flask application locally in the background and tracks Process ID (PID)
# ==============================================================================

[CmdletBinding()]
param(
    [int]$Port = 5000,
    [string]$HostAddress = "127.0.0.1",
    [string]$PythonExe = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
Set-Location $RootDir

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Starting Deployment for DevOps CI/CD App... " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Determine Python Executable
if (-not $PythonExe) {
    if (Test-Path "$RootDir\venv\Scripts\python.exe") {
        $PythonExe = "$RootDir\venv\Scripts\python.exe"
        Write-Host "[INFO] Using virtual environment Python: $PythonExe" -ForegroundColor Green
    } else {
        $PythonExe = "python"
        Write-Host "[INFO] Virtual environment not found; defaulting to system Python: $PythonExe" -ForegroundColor Yellow
    }
}

# 2. Stop Any Existing Process via app.pid
$PidFile = "$RootDir\app.pid"
if (Test-Path $PidFile) {
    $OldPid = Get-Content $PidFile -ErrorAction SilentlyContinue | Out-String
    $OldPid = $OldPid.Trim()
    if ($OldPid -match '^\d+$') {
        Write-Host "[INFO] Found existing app.pid ($OldPid). Attempting to stop..." -ForegroundColor Yellow
        try {
            $oldProcId = [int]$OldPid
            $runningProc = Get-Process -Id $oldProcId -ErrorAction SilentlyContinue
            if ($runningProc) {
                Stop-Process -Id $oldProcId -Force -ErrorAction SilentlyContinue
                Write-Host "[SUCCESS] Stopped previous process $oldProcId." -ForegroundColor Green
            }
        } catch {
            Write-Host "[WARN] Could not stop process ${OldPid} - $_" -ForegroundColor Yellow
        }
    }
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
}

# 3. Check and Clear Port Collisions (Port 5000)
try {
    $PortConnections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($PortConnections) {
        foreach ($conn in $PortConnections) {
            $ConflictPid = $conn.OwningProcess
            if ($ConflictPid -and $ConflictPid -ne 0) {
                Write-Host "[WARN] Port $Port is occupied by PID $ConflictPid. Terminating..." -ForegroundColor Yellow
                Stop-Process -Id $ConflictPid -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 1
            }
        }
    }
} catch {
    # Ignore if NetTCPConnection is restricted
}

# 4. Start the Application in Background
Write-Host "[INFO] Launching app.py on ${HostAddress}:${Port} ..." -ForegroundColor Cyan
$env:PORT = $Port.ToString()
$env:HOST = $HostAddress
$env:JENKINS_NODE_COOKIE = "dontKillMe"

$process = Start-Process `
    -FilePath $PythonExe `
    -ArgumentList "app.py" `
    -WorkingDirectory $RootDir `
    -WindowStyle Hidden `
    -PassThru

if (-not $process -or $process.HasExited) {
    Write-Error "[FATAL] Failed to start application process."
    exit 1
}

# 5. Save PID to app.pid
$process.Id | Out-File -FilePath $PidFile -Encoding ascii -Force
Write-Host "[SUCCESS] Application started with PID: $($process.Id)" -ForegroundColor Green

# 6. Grace Period & Readiness Check
Write-Host "[INFO] Waiting 2 seconds for server startup..." -ForegroundColor Cyan
Start-Sleep -Seconds 2

$check = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
if ($null -eq $check -or $check.HasExited) {
    Write-Error "[FATAL] Process $($process.Id) exited prematurely."
    exit 1
}

Write-Host "[SUCCESS] Deployment completed successfully! PID $($process.Id) saved to app.pid." -ForegroundColor Green
exit 0
