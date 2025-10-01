# Quick test script for simple example (PowerShell)
param(
    [switch]$Deploy,
    [switch]$Destroy
)

Write-Host "=== Testing Simple Proxylity Example ===" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "main.tf")) {
    Write-Error "main.tf not found. Run this script from examples/simple directory."
    exit 1
}

try {
    Write-Host "1. Initializing Terraform..." -ForegroundColor Yellow
    terraform init -upgrade

    Write-Host "2. Validating configuration..." -ForegroundColor Yellow
    terraform validate

    Write-Host "3. Formatting check..." -ForegroundColor Yellow
    terraform fmt -check

    Write-Host "4. Creating plan..." -ForegroundColor Yellow
    terraform plan -out=tfplan

    Write-Host "✅ Simple example validation completed successfully!" -ForegroundColor Green
    
    if ($Deploy) {
        Write-Host "5. Deploying infrastructure..." -ForegroundColor Yellow
        terraform apply tfplan
        
        Write-Host "6. Showing outputs..." -ForegroundColor Yellow
        terraform output
    } elseif ($Destroy) {
        Write-Host "5. Destroying infrastructure..." -ForegroundColor Red
        terraform destroy -auto-approve
    } else {
        Write-Host ""
        Write-Host "To deploy:" -ForegroundColor Cyan
        Write-Host "  .\test.ps1 -Deploy"
        Write-Host ""
        Write-Host "To cleanup:" -ForegroundColor Cyan
        Write-Host "  .\test.ps1 -Destroy"
    }
}
catch {
    Write-Error "Test failed: $_"
    exit 1
}