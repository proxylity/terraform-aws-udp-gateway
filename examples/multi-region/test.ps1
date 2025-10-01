# Quick test script for multi-region example (PowerShell)
param(
    [switch]$Deploy,
    [switch]$Destroy
)

Write-Host "=== Testing Multi-Region Proxylity Example ===" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "main.tf")) {
    Write-Error "main.tf not found. Run this script from examples/multi-region directory."
    exit 1
}

try {
    Write-Host "1. Checking AWS access to all regions..." -ForegroundColor Yellow
    $regions = @("us-west-2", "us-east-1", "eu-west-1")
    foreach ($region in $regions) {
        aws sts get-caller-identity --region $region --output table | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Cannot access region $region"
        }
    }
    Write-Host "   ✅ All regions accessible" -ForegroundColor Green

    Write-Host "2. Initializing Terraform..." -ForegroundColor Yellow
    terraform init -upgrade

    Write-Host "3. Validating configuration..." -ForegroundColor Yellow
    terraform validate

    Write-Host "4. Formatting check..." -ForegroundColor Yellow
    terraform fmt -check

    Write-Host "5. Creating plan..." -ForegroundColor Yellow
    terraform plan -out=tfplan

    Write-Host "✅ Multi-region example validation completed successfully!" -ForegroundColor Green
    
    if ($Deploy) {
        Write-Host "6. Deploying infrastructure..." -ForegroundColor Yellow
        terraform apply tfplan
        
        Write-Host "7. Showing outputs..." -ForegroundColor Yellow
        terraform output
        
        Write-Host "8. Testing connection..." -ForegroundColor Yellow
        $endpoint = terraform output -raw connection_info | ConvertFrom-Json | Select-Object -ExpandProperty endpoint
        Write-Host "UDP Endpoint: $endpoint" -ForegroundColor Cyan
        
    } elseif ($Destroy) {
        Write-Host "6. Destroying infrastructure..." -ForegroundColor Red
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