function Test-WebApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,
        
        [Parameter(Mandatory=$false)]
        [object]$Body,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string]$Method = 'POST',
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSec = 30,
        
        [Parameter(Mandatory=$false)]
        [switch]$IncludeSecurityHeaders,
        
        # Advanced features
        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 0,
        
        [Parameter(Mandatory=$false)]
        [int]$RetryDelayMs = 1000,
        
        [Parameter(Mandatory=$false)]
        [string]$ApiKey,
        
        [Parameter(Mandatory=$false)]
        [string]$BearerToken,
        
        [Parameter(Mandatory=$false)]
        [string]$HmacSecret,
        
        [Parameter(Mandatory=$false)]
        [int]$RateLimitDelayMs = 0,
        
        [Parameter(Mandatory=$false)]
        [scriptblock]$ResponseValidator
    )
    
    begin {
        # Generate secure headers
        $headers = @{
            "Content-Type" = "application/json"
            "User-Agent" = "CryptoSphere-Suite/1.0"
        }
        
        # Add security headers if requested
        if ($IncludeSecurityHeaders) {
            try {
                # Try to use the module function first
                $headers["X-Request-ID"] = CryptoSphere-Suite\Get-CryptoRandomBytes -ByteCount 8 -OutputFormat Hex
                $headers["X-Nonce"] = CryptoSphere-Suite\Get-CryptoRandomBytes -ByteCount 4 -OutputFormat Hex
            }
            catch {
                # Fallback to direct .NET implementation
                Write-Warning "Module function not available, using .NET fallback for random bytes"
                $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
                $bytes8 = New-Object byte[] 8
                $bytes4 = New-Object byte[] 4
                $rng.GetBytes($bytes8)
                $rng.GetBytes($bytes4)
                $headers["X-Request-ID"] = ($bytes8 | ForEach-Object { $_.ToString('X2') }) -join ''
                $headers["X-Nonce"] = ($bytes4 | ForEach-Object { $_.ToString('X2') }) -join ''
                $rng.Dispose()
            }
            $headers["X-Timestamp"] = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        }
        
        # Add authentication headers
        if ($ApiKey) {
            $headers["X-API-Key"] = $ApiKey
        }
        
        if ($BearerToken) {
            $headers["Authorization"] = "Bearer $BearerToken"
        }
        
        # Initialize retry counter
        $attempt = 0
        $lastResponse = $null
    }
    
    process {
        do {
            $attempt++
            try {
                # Rate limiting delay
                if ($RateLimitDelayMs -gt 0 -and $attempt -gt 1) {
                    Write-Verbose "Rate limiting: waiting $RateLimitDelayMs ms"
                    Start-Sleep -Milliseconds $RateLimitDelayMs
                }
                
                # Prepare request parameters
                $params = @{
                    Uri = $Endpoint
                    Method = $Method
                    Headers = $headers
                    TimeoutSec = $TimeoutSec
                    ErrorAction = 'Stop'
                }
                
                # Add HMAC signature if secret provided
                if ($HmacSecret -and $Body) {
                    $requestBody = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Compress }
                    $signature = New-HmacSignature -Secret $HmacSecret -Data $requestBody -Method $Method -Endpoint $Endpoint
                    $headers["X-Signature"] = $signature
                    $params.Body = $requestBody
                }
                elseif ($Body -and @('POST', 'PUT', 'PATCH') -contains $Method) {
                    $params.Body = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 10 -Compress }
                }
                
                Write-Verbose "API attempt $attempt : $Method $Endpoint"
                
                # Execute request
                $response = Invoke-RestMethod @params
                $lastResponse = $response
                
                # Response validation
                if ($ResponseValidator) {
                    $validationResult = & $ResponseValidator $response
                    if (-not $validationResult) {
                        throw "Response validation failed"
                    }
                }
                
                return @{
                    Success = $true
                    Response = $response
                    StatusCode = 200
                    Headers = $headers
                    Attempts = $attempt
                }
            }
            catch [System.Net.WebException] {
                $statusCode = [int]$_.Exception.Response.StatusCode
                $statusDesc = $_.Exception.Response.StatusDescription
                $lastError = $_.Exception.Message
                
                # Check if we should retry (5xx errors or network issues)
                $shouldRetry = ($statusCode -ge 500 -or $statusCode -eq 0) -and $attempt -le $MaxRetries
                
                if ($shouldRetry) {
                    Write-Warning "Attempt $attempt failed ($statusCode). Retrying in $RetryDelayMs ms..."
                    Start-Sleep -Milliseconds $RetryDelayMs
                    continue
                }
                
                Write-Warning "API test failed with status $statusCode : $statusDesc"
                
                return @{
                    Success = $false
                    StatusCode = $statusCode
                    StatusDescription = $statusDesc
                    Error = $lastError
                    Attempts = $attempt
                    LastResponse = $lastResponse
                }
            }
            catch {
                $lastError = $_.Exception.Message
                
                # Check if we should retry
                $shouldRetry = $attempt -le $MaxRetries
                
                if ($shouldRetry) {
                    Write-Warning "Attempt $attempt failed. Retrying in $RetryDelayMs ms..."
                    Start-Sleep -Milliseconds $RetryDelayMs
                    continue
                }
                
                Write-Error "Unexpected error: $lastError"
                
                return @{
                    Success = $false
                    Error = $lastError
                    Attempts = $attempt
                    LastResponse = $lastResponse
                }
            }
        } while ($attempt -le $MaxRetries)
    }
}
