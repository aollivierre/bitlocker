# Connect-MgGraph -Scopes "BitLockerKey.ReadBasic.All"


# $clientId = "xxxxxxxxxxxxxxxx84e936411eb7"
# $clientSecret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# # $tenantName = "xxxxxxxxxxxxxxxxxxc15d21a89f13"
# $tenantName = "xxxxxxxxxxxxxxxxxxxx.onmicrosoft.com"

# function Get-MicrosoftGraphAccessToken {
#     $tokenBody = @{
#         Grant_Type    = 'client_credentials'  
#         Scope         = 'https://graph.microsoft.com/.default'  
#         Client_Id     = $clientId  
#         Client_Secret = $clientSecret
#     }  

#     $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $tokenBody -ErrorAction Stop

#     return $tokenResponse.access_token
# }







$clientId = "b075578c-6300-4bae-8458-84e936411eb7"
# $clientSecret = "xxxxxxxxxxxxxxxxxxxxxxxx"
# $tenantName = "xxxxxxxxxxxxxxxxxxxx.onmicrosoft.com"
$tenantID = "xxxxxxxxxxxxxxxxx-c15d21a89f13"

# $RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"


$refreshToken ='0.AXxxxxxxxxxxxxxxxxxxx'


# Define your tenant ID, client ID, and refresh token
# $tenantId = "your-tenant-id"  # Replace with your actual tenant ID
# $clientId = "your-client-id"  # Replace with your actual client ID
# $refreshToken = $refreshToken # Replace with your actual refresh token
# If your application is a confidential client, uncomment the next line and specify your client secret
#$clientSecret = "your-client-secret"  # Replace with your actual client secret if needed

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
    # Write-Host "New Refresh Token: $($response.refresh_token)" uncomment for debugging
}




# $accessTokenString = 'ey*******************'



$accessTokenString = $response.access_token




# Assuming your access token is stored in a variable named $accessTokenString
# $accessTokenString = "eyJ0eXAiOiJKV1QiLCJub25jZSI6Ijk3ZmE1U..."

# Convert the plain string token to a SecureString
$secureAccessToken = $accessTokenString | ConvertTo-SecureString -AsPlainText -Force

# Use the SecureString access token to connect
Connect-MgGraph -AccessToken $secureAccessToken


# Connect-MgGraph -AccessToken $AccessToken

# Get an access token for the Microsoft Graph API
# $accessToken = Get-MicrosoftGraphAccessToken
    
# # Set up headers for API requests
# $headers = @{
#     "Authorization" = "Bearer $($accessToken)"
#     "Content-Type"  = "application/json"
# }





function AOGetBitlockerRecoveryKeys {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DeviceId
    )

    # Ensure the Microsoft Graph module is loaded
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Write-Error "Microsoft Graph PowerShell SDK is not installed. Please install it using 'Install-Module Microsoft.Graph'."
        return
    }

    # Import Microsoft Graph module
    Import-Module Microsoft.Graph.Identity.SignIns

    # Attempt to list Bitlocker Recovery Keys for the specified Device ID
    try {
        $recoveryKeys = Get-MgInformationProtectionBitlockerRecoveryKey -Filter "deviceId eq '$DeviceId'"

        if ($null -eq $recoveryKeys) {
            Write-Host "No Bitlocker recovery keys found for Device ID: $DeviceId"
        } else {
            Write-Host "Bitlocker recovery keys retrieved successfully for Device ID: $DeviceId"
            return $recoveryKeys
        }
    } catch {
        Write-Error "An error occurred while retrieving Bitlocker recovery keys: $_"
    }
}



# Run dsregcmd /status and capture the output
$dsregcmdOutput = & dsregcmd /status

# Convert the output to a string to ensure consistent handling
$dsregcmdOutputString = $dsregcmdOutput -join "`n"

# Use a regular expression to find the DeviceId more reliably
if ($dsregcmdOutputString -match "DeviceId\s*:\s*([-\w]+)") {
    $DeviceId = $matches[1]
} else {
    Write-Host "Device ID not found. Ensure the device is Azure AD joined."
    # exit 1
}

if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    Write-Host "Device ID: $DeviceId"

    $DeviceId = '6d298358-fa28-438c-9139-e4b75ccac34c'

    # Continue with your script...
} else {
    Write-Host "Device ID not found. Ensure the device is Azure AD joined."
    # exit 1
}


if (-not $DeviceId) {
    Write-Host "Device ID not found. Ensure the device is Azure AD joined."
    # exit 1
} else {
    Write-Host "Device ID: $DeviceId"

    # # Assuming previous setup for Azure AD authentication and Microsoft Graph API access...
    # $GraphUri = "https://graph.microsoft.com/v1.0/devices/$DeviceId/bitlocker/recoveryKeys"
    # $Headers = @{
    #     Authorization = "Bearer $AccessToken"
    # }

    # try {
    #     $BitlockerKeysResponse = Invoke-RestMethod -Uri $GraphUri -Headers $Headers -Method Get

    #     if ($null -ne $BitlockerKeysResponse.value -and $BitlockerKeysResponse.value.Count -gt 0) {
    #         Write-Host "Bitlocker key(s) found escrowed in Azure AD."
    #         exit 0
    #     } else {
    #         # Write-Host "No Bitlocker keys found escrowed in Azure AD."
    #         exit 1
    #     }
    # } catch {
    #     # Write-Error "Failed to query Bitlocker keys from Azure AD: $_"
    #     exit 1
    # }
}


# $recoveryKeys = AO-GetBitlockerRecoveryKeys -DeviceId "your-device-id-here"
$recoveryKeys = AOGetBitlockerRecoveryKeys -DeviceId $DeviceId

$recoveryKeys