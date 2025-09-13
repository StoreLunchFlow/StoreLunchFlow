<#
.SYNOPSIS
    Demo script for testing Web APIs with CryptoSphere-Suite
.DESCRIPTION
    This demo shows how to use the Test-WebApi function with secure headers
    and cryptographic random data for API testing.
#>

Write-Host "?? CryptoSphere Suite API Testing Demo" -ForegroundColor Cyan
Write-Host "=" * 60

# Import the module
try {
    Import-Module "../src/CryptoSphere-Suite.psm1" -Force -ErrorAction Stop
    Write-Host "? Module imported successfully" -ForegroundColor Green
}
catch {
    Write-Host "? Failed to import module: $_" -ForegroundColor Red
    exit 1
}

# Test 1: Basic API test using httpbin.org (public test API)
Write-Host "`n1. Testing basic API call to httpbin.org..." -ForegroundColor Yellow
$testResult = Test-WebApi -Endpoint "https://httpbin.org/post" -Body @{
    test = "hello"
    timestamp = (Get-Date).ToString()
    randomData = (Get-CryptoRandomBytes -ByteCount 8 -OutputFormat Hex)
} -Method POST

if ($testResult.Success) {
    Write-Host "? API Test Successful!" -ForegroundColor Green
    Write-Host "   Status: $($testResult.StatusCode)" -ForegroundColor White
    Write-Host "   URL: $($testResult.Response.url)" -ForegroundColor White
} else {
    Write-Host "? API Test Failed: $($testResult.Error)" -ForegroundColor Red
}

# Test 2: With security headers
Write-Host "`n2. Testing with security headers..." -ForegroundColor Yellow
$secureResult = Test-WebApi -Endpoint "https://httpbin.org/post" -Body @{
    secureData = Get-CryptoRandomBytes -ByteCount 16 -OutputFormat Base64
    operation = "secure-demo"
} -Method POST -IncludeSecurityHeaders

if ($secureResult.Success) {
    Write-Host "? Secure API Test Successful!" -ForegroundColor Green
    Write-Host "   Request ID: $($secureResult.Response.headers.'X-Request-ID')" -ForegroundColor White
    Write-Host "   Nonce: $($secureResult.Response.headers.'X-Nonce')" -ForegroundColor White
    Write-Host "   Data Size: $($secureResult.Response.json.secureData.Length) bytes" -ForegroundColor White
} else {
    Write-Host "? Secure API Test Failed: $($secureResult.Error)" -ForegroundColor Red
}

# Test 3: Generate crypto material demo
Write-Host "`n3. Generating cryptographic material..." -ForegroundColor Yellow
Write-Host "   API Key: $(Get-CryptoRandomBytes -ByteCount 32 -OutputFormat Hex)" -ForegroundColor Magenta
Write-Host "   Auth Token: $(Get-CryptoRandomBytes -ByteCount 24 -OutputFormat Base64)" -ForegroundColor Magenta
Write-Host "   Session ID: $(Get-CryptoRandomBytes -ByteCount 16 -OutputFormat Hex)" -ForegroundColor Magenta

Write-Host "`n?? Demo completed successfully!" -ForegroundColor Green
Write-Host "   All cryptographic operations completed securely" -ForegroundColor White
