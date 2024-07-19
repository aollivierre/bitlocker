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
$clientSecret = $secrets.ClientSecret
$tenantName = $secrets.TenantName
$tenantID = $secrets.TenantId
$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"

# Output the variables for verification (optional)
Write-Output "ClientId: $clientId"
Write-Output "ClientSecret: $clientSecret"
Write-Output "TenantName: $tenantName"
Write-Output "TenantId: $tenantID"
Write-Output "RedirectUri: $RedirectUri"


# Define variables
# $tenantId = "<Your-Tenant-ID>"
# $clientId = "<Your-Client-ID>"
# $redirectUri = "http://localhost:8080/"


$scope = "openid%20offline_access%20User.Read%20Mail.Read" # Include 'offline_access' for refresh token
$authUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&scope=$scope&response_mode=query"

# Start a listener on port 8080
Start-Process "powershell" -ArgumentList "-Command `"`$Listener = [System.Net.HttpListener]::new(); `$Listener.Prefixes.Add('http://+:8080/'); `$Listener.Start(); Write-Host 'Listening...'; `$Context = `$Listener.GetContext(); `$Response = `$Context.Response; `$Response.OutputStream.Write([Text.Encoding]::UTF8.GetBytes('You can close this window now'), 0, 36); `$Response.Close(); `$Listener.Stop(); Write-Host 'Code: ' + `$Context.Request.QueryString['code'];`""

# Open the authorization URL in the default web browser
Start-Process "chrome.exe" $authUrl # Use 'chrome.exe' or another browser if preferred