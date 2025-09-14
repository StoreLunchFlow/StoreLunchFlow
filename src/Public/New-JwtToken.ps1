function New-JwtToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Secret,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Payload,
        
        [Parameter(Mandatory=$false)]
        [int]$ExpiryMinutes = 60
    )
    
    $header = @{
        alg = "HS256"
        typ = "JWT"
    }
    
    $payload["exp"] = [DateTimeOffset]::UtcNow.AddMinutes($ExpiryMinutes).ToUnixTimeSeconds()
    $payload["iat"] = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    
    $headerBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($header | ConvertTo-Json -Compress)))
    $payloadBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Compress)))
    
    $signatureData = "$headerBase64.$payloadBase64"
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Text.Encoding]::UTF8.GetBytes($Secret)
    $signature = [Convert]::ToBase64String($hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($signatureData)))
    
    return "$headerBase64.$payloadBase64.$signature"
}
