Write-Host "Testing CryptoSphere-Suite Module..." -ForegroundColor Cyan

# Import the module
try {
    Import-Module "./src/CryptoSphere-Suite.psm1" -Force -ErrorAction Stop
    Write-Host "? Module imported successfully" -ForegroundColor Green
}
catch {
    Write-Host "? Failed to import module: $_" -ForegroundColor Red
    exit 1
}

# Test functions
Write-Host "`nTesting Get-CryptoRandomBytes..." -ForegroundColor Yellow
try {
    $randomData = Get-CryptoRandomBytes -ByteCount 8 -OutputFormat Hex
    Write-Host "? Success: $randomData" -ForegroundColor Green
}
catch {
    Write-Host "? Get-CryptoRandomBytes failed: $_" -ForegroundColor Red
}

Write-Host "`nTesting Test-WebApi..." -ForegroundColor Yellow
try {
    $apiResult = Test-WebApi -Endpoint "https://httpbin.org/get" -Method GET
    Write-Host "? Test-WebApi success: $($apiResult.Success)" -ForegroundColor Green
}
catch {
    Write-Host "? Test-WebApi failed: $_" -ForegroundColor Red
}

Write-Host "`nTesting New-HmacSignature..." -ForegroundColor Yellow
try {
    $hmac = New-HmacSignature -Secret "test" -Data "hello"
    Write-Host "? New-HmacSignature success: $hmac" -ForegroundColor Green
}
catch {
    Write-Host "? New-HmacSignature failed: $_" -ForegroundColor Red
}

Write-Host "`n?? Module test completed!" -ForegroundColor Cyan
