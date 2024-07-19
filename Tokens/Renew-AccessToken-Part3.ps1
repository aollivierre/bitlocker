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
$RedirectUri = $secrets.RedirectUri
$refreshToken = $secrets.RefreshToken

# Output the variables for verification (optional)
Write-Output "ClientId: $clientId"
Write-Output "TenantName: $tenantName"
Write-Output "TenantId: $tenantID"
Write-Output "RedirectUri: $RedirectUri"
Write-Output "RefreshToken: $refreshToken"



# Token endpoint
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# Prepare the request body. Exclude 'client_secret' if your app is a public client.
$body = @{
    client_id     = $clientId
    grant_type    = "refresh_token"
    refresh_token = $refreshToken
    # Uncomment the next line if your application is a confidential client
    #client_secret = $clientSecret
    scope         = "https://graph.microsoft.com/.default"  # Adjust this scope according to your needs
}

# Make the POST request
$response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

# Output the new access token and refresh token
Write-Host "New Access Token: $($response.access_token)"
# Some authorization servers might not return a new refresh token every time you refresh an access token
if ($response.refresh_token) {
    Write-Host "New Refresh Token: $($response.refresh_token)"
}