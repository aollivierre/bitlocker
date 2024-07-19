# Define the path to the secrets.json file
$secretsFilePath = Join-Path -Path $PSScriptRoot -ChildPath "secrets.json"

# Check if the secrets.json file exists
if (-Not (Test-Path -Path $secretsFilePath)) {
    Write-Error "The secrets.json file was not found at path: $secretsFilePath"
    return
}

# Read the contents of the secrets.json file
$secretsContent = Get-Content -Path $secretsFilePath -Raw

# Convert the JSON content to a PowerShell object
$secrets = $secretsContent | ConvertFrom-Json

# Assign the values from the secrets object to the corresponding variables
$clientId = $secrets.ClientId
$tenantName = $secrets.TenantName
$tenantID = $secrets.TenantId
$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
$URL = $secrets.URL

# Output the variables for verification (optional)
Write-Output "ClientId: $clientId"
Write-Output "TenantName: $tenantName"
Write-Output "TenantId: $tenantID"
Write-Output "RedirectUri: $RedirectUri"
Write-Output "URL: $URL"

# Assume $url contains the full redirect URL


# Extract the code from the URL
$code = $url -split "code=" | Select-Object -Last 1
$code = $code -split "&" | Select-Object -First 1

# Output the code
Write-Host "Authorization Code: $code"

# Define the token URL
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# Prepare the body for the POST request
$body = @{
    client_id    = $clientId
    scope        = "https://graph.microsoft.com/.default"  # Adjust the scope as necessary
    code         = $code
    redirect_uri = $RedirectUri  # Ensure this matches the redirect URI registered in Azure AD
    grant_type   = "authorization_code"
    # Do not include the client_secret for a public client
}

# Make the POST request
$response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

# Output the access and refresh tokens
Write-Host "Access Token: $($response.access_token)"
Write-Host "Refresh Token: $($response.refresh_token)"