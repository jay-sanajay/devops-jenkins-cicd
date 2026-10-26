// ==============================================================================
// Jenkinsfile: Automated CI/CD Declarative Pipeline for Windows
// Keysight Technologies DevOps Project
// ==============================================================================

pipeline {
    // Run on any available Jenkins agent with Windows executor
    agent any

    // Global environment variables
    environment {
        PORT = '5000'
        HOST = '127.0.0.1'
        APP_ENV = 'production'
    }

    stages {
        // ----------------------------------------------------------------------
        // STAGE 1: CHECKOUT
        // Retrieves the latest source code from the configured GitHub repository.
        // In Jenkins multibranch or GitHub pipeline jobs, Jenkins handles this via
        // git plugin / SCM step automatically, recording the commit SHA and author.
        // ----------------------------------------------------------------------
        stage('Checkout') {
            steps {
                echo '=== Stage 1: Checkout Source Code ==='
                powershell '''
                    Write-Host "[CHECKOUT] Working Directory: $PWD"
                    git status
                    git log -1 --oneline
                '''
            }
        }

        // ----------------------------------------------------------------------
        // STAGE 2: INSTALL DEPENDENCIES
        // Creates a dedicated Python virtual environment (venv) inside workspace.
        // Installs production & development dependencies (Flask, Pytest) into venv.
        // Prevents contaminating the global system Python environment.
        // ----------------------------------------------------------------------
        stage('Install Dependencies') {
            steps {
                echo '=== Stage 2: Setting Up Virtual Environment & Dependencies ==='
                powershell '''
                    Write-Host "[SETUP] Detecting Python..."
                    python --version

                    if (-not (Test-Path "venv")) {
                        Write-Host "[SETUP] Creating virtual environment (venv)..."
                        python -m venv venv
                    } else {
                        Write-Host "[SETUP] Existing virtual environment found."
                    }

                    Write-Host "[SETUP] Upgrading pip inside venv..."
                    .\\venv\\Scripts\\python.exe -m pip install --upgrade pip

                    Write-Host "[SETUP] Installing dependencies from requirements-dev.txt..."
                    .\\venv\\Scripts\\pip.exe install -r requirements-dev.txt
                '''
            }
        }

        // ----------------------------------------------------------------------
        // STAGE 3: RUN TESTS
        // Executes automated Pytest suite. If any unit test fails, Pytest exits
        // with a non-zero exit code, which immediately halts the pipeline and
        // prevents broken code from proceeding to build or deployment stages.
        // Outputs JUnit XML format so Jenkins can publish graphical test trends.
        // ----------------------------------------------------------------------
        stage('Run Tests') {
            steps {
                echo '=== Stage 3: Running Automated Pytest Suite ==='
                powershell '''
                    if (-not (Test-Path "reports")) {
                        New-Item -ItemType Directory -Path "reports" | Out-Null
                    }

                    Write-Host "[TEST] Executing Pytest with JUnit XML output..."
                    .\\venv\\Scripts\\pytest.exe test_app.py -v --junitxml=reports/test-results.xml
                '''
            }
            post {
                always {
                    // Archive test results in Jenkins UI for pass/fail analytics
                    junit allowEmptyResults: true, testResults: 'reports/*.xml'
                }
            }
        }

        // ----------------------------------------------------------------------
        // STAGE 4: BUILD & VALIDATE
        // For interpreted languages like Python, the 'Build' stage validates
        // code syntax, checks compilation to bytecode (.pyc), and verifies
        // configuration integrity before deploying.
        // ----------------------------------------------------------------------
        stage('Build') {
            steps {
                echo '=== Stage 4: Validating Code & Bytecode Compilation ==='
                powershell '''
                    Write-Host "[BUILD] Compiling Python source to bytecode (.pyc)..."
                    .\\venv\\Scripts\\python.exe -m py_compile app.py test_app.py
                    Write-Host "[BUILD] Syntax and bytecode compilation validated successfully!"
                '''
            }
        }

        // ----------------------------------------------------------------------
        // STAGE 5: DEPLOY
        // Deploys the application locally in the background using deploy.ps1.
        // Safely terminates any stale process, prevents port collisions, launches
        // the app in background, and tracks its Process ID (PID) in app.pid.
        // ----------------------------------------------------------------------
        stage('Deploy') {
            steps {
                echo '=== Stage 5: Deploying Application Locally ==='
                powershell '''
                    $env:JENKINS_NODE_COOKIE = "dontKillMe"
                    Write-Host "[DEPLOY] Running scripts/deploy.ps1..."
                    powershell.exe -ExecutionPolicy Bypass -File .\\scripts\\deploy.ps1 -Port $env:PORT -HostAddress $env:HOST
                '''
            }
        }

        // ----------------------------------------------------------------------
        // STAGE 6: SMOKE TEST
        // Performs an end-to-end HTTP health check against the live endpoint.
        // If the server crashed or returns non-200 / unhealthy status,
        // the pipeline is marked as failed.
        // ----------------------------------------------------------------------
        stage('Smoke Test') {
            steps {
                echo '=== Stage 6: Running Live Smoke Test / Health Check ==='
                powershell '''
                    $healthUrl = "http://" + $env:HOST + ":" + $env:PORT + "/health"
                    Write-Host "[SMOKE TEST] Querying $healthUrl ..."

                    $maxRetries = 5
                    $retryCount = 0
                    $isHealthy = $false

                    while ($retryCount -lt $maxRetries) {
                        try {
                            $response = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 5
                            Write-Host "[SMOKE TEST] Response: $($response | ConvertTo-Json -Compress)"
                            if ($response.status -eq "healthy") {
                                Write-Host "[SMOKE TEST PASSED] Service is verified healthy!" -ForegroundColor Green
                                $isHealthy = $true
                                break
                            }
                        } catch {
                            Write-Host "[WAIT] App warming up, retrying in 2s... ($($retryCount + 1)/$maxRetries)"
                            Start-Sleep -Seconds 2
                        }
                        $retryCount++
                    }

                    if (-not $isHealthy) {
                        Write-Error "[SMOKE TEST FAILED] Health check failed to receive healthy status from $healthUrl."
                        exit 1
                    }
                '''
            }
        }
    }

    // --------------------------------------------------------------------------
    // PIPELINE POST ACTIONS
    // Notifications and clean up executed after all stages complete.
    // --------------------------------------------------------------------------
    post {
        success {
            echo '================================================================='
            echo ' PIPELINE STATUS: SUCCESS'
            echo ' All stages passed: Code checked out, tested, built, and deployed!'
            echo '================================================================='
        }
        failure {
            echo '================================================================='
            echo ' PIPELINE STATUS: FAILED'
            echo ' A stage failed. Pipeline execution was stopped immediately.'
            echo ' Please inspect the console log output above to troubleshoot.'
            echo '================================================================='
        }
        always {
            echo "Pipeline run completed at: ${new Date()}"
        }
    }
}
