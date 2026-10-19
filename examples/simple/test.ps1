param(
    [switch]$Deploy,
    [switch]$Destroy
)

$ErrorActionPreference = "Stop"
if ($Deploy -and $Destroy) {
    throw "Choose either -Deploy or -Destroy."
}

Push-Location $PSScriptRoot
try {
    terraform init -input=false
    if ($LASTEXITCODE -ne 0) { throw "Terraform initialization failed." }
    terraform validate
    if ($LASTEXITCODE -ne 0) { throw "Terraform validation failed." }
    terraform fmt -check
    if ($LASTEXITCODE -ne 0) { throw "Terraform formatting check failed." }

    if ($Destroy) {
        terraform destroy
        if ($LASTEXITCODE -ne 0) { throw "Terraform destroy failed." }
    } else {
        terraform plan -out=tfplan
        if ($LASTEXITCODE -ne 0) { throw "Terraform plan failed." }
        if ($Deploy) {
            terraform apply tfplan
            if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed." }
            terraform output
            if ($LASTEXITCODE -ne 0) { throw "Terraform output failed." }
        }
    }
} finally {
    Pop-Location
}
