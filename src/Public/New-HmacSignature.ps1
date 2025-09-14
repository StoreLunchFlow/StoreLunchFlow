function New-HmacSignature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Secret,
        
        [Parameter(Mandatory=$true)]
        [string]$Data,
        
        [Parameter(Mandatory=$false)]
        [string]$Method = "POST",
        
        [Parameter(Mandatory=$false)]
        [string]$Endpoint
    )
    
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $signatureData = "$Method|$Endpoint|$Data|$timestamp"
    
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Text.Encoding]::UTF8.GetBytes($Secret)
    $signature = [Convert]::ToBase64String($hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($signatureData)))
    
    return "$signature|$timestamp"
}
