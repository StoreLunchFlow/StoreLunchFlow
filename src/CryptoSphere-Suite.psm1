# Dot-source all function files from the Public directory
$PublicFunctions = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )

foreach ($file in $PublicFunctions) {
    try {
        . $file.FullName
        Write-Verbose "Imported function: $($file.BaseName)"
    }
    catch {
        Write-Warning "Failed to import function from $($file.Name): $_"
    }
}

# Also import the helper functions (they're in Public directory now)
. $PSScriptRoot\Public\New-HmacSignature.ps1
. $PSScriptRoot\Public\New-JwtToken.ps1

# Export all public functions including helpers
$functionsToExport = @(
    (Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 | ForEach-Object { $_.BaseName })
    'New-HmacSignature'
    'New-JwtToken'
)

Export-ModuleMember -Function $functionsToExport
