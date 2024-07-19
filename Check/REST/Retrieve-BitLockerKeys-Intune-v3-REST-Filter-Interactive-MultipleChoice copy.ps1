# Read configuration from the JSON file
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Assign values from JSON to variables
$LoggingDeploymentName = $config.LoggingDeploymentName
    
function Initialize-ScriptAndLogging {
    $ErrorActionPreference = 'SilentlyContinue'
    $deploymentName = "$LoggingDeploymentName" # Replace this with your actual deployment name
    $scriptPath = "C:\code\$deploymentName"
    # $hadError = $false
    
    try {
        if (-not (Test-Path -Path $scriptPath)) {
            New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
            Write-Host "Created directory: $scriptPath"
        }
    
        $computerName = $env:COMPUTERNAME
        $Filename = "$LoggingDeploymentName"
        $logDir = Join-Path -Path $scriptPath -ChildPath "exports\Logs\$computerName"
        $logPath = Join-Path -Path $logDir -ChildPath "$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
            
        if (!(Test-Path $logPath)) {
            Write-Host "Did not find log file at $logPath" -ForegroundColor Yellow
            Write-Host "Creating log file at $logPath" -ForegroundColor Yellow
            $createdLogDir = New-Item -ItemType Directory -Path $logPath -Force -ErrorAction Stop
            Write-Host "Created log file at $logPath" -ForegroundColor Green
        }
            
        $logFile = Join-Path -Path $logPath -ChildPath "$Filename-Transcript.log"
        Start-Transcript -Path $logFile -ErrorAction Stop | Out-Null
    
        $CSVDir = Join-Path -Path $scriptPath -ChildPath "exports\CSV"
        $CSVFilePath = Join-Path -Path $CSVDir -ChildPath "$computerName"
            
        if (!(Test-Path $CSVFilePath)) {
            Write-Host "Did not find CSV file at $CSVFilePath" -ForegroundColor Yellow
            Write-Host "Creating CSV file at $CSVFilePath" -ForegroundColor Yellow
            $createdCSVDir = New-Item -ItemType Directory -Path $CSVFilePath -Force -ErrorAction Stop
            Write-Host "Created CSV file at $CSVFilePath" -ForegroundColor Green
        }
    
        return @{
            ScriptPath  = $scriptPath
            Filename    = $Filename
            LogPath     = $logPath
            LogFile     = $logFile
            CSVFilePath = $CSVFilePath
        }
    
    }
    catch {
        Write-Error "An error occurred while initializing script and logging: $_"
    }
}
$initializationInfoLogging = Initialize-ScriptAndLogging
$initializationInfoLogging
    
    
# Script Execution and Variable Assignment
# After the function Initialize-ScriptAndLogging is called, its return values (in the form of a hashtable) are stored in the variable $initializationInfo.
    
# Then, individual elements of this hashtable are extracted into separate variables for ease of use:
    
# $ScriptPath: The path of the script's main directory.
# $Filename: The base name used for log files.
# $logPath: The full path of the directory where logs are stored.
# $logFile: The full path of the transcript log file.
# $CSVFilePath: The path of the directory where CSV files are stored.
# This structure allows the script to have a clear organization regarding where logs and other files are stored, making it easier to manage and maintain, especially for logging purposes. It also encapsulates the setup logic in a function, making the main script cleaner and more focused on its primary tasks.
    
    
$ScriptPath = $initializationInfoLogging['ScriptPath']
$Filename = $initializationInfoLogging['Filename']
$logPath = $initializationInfoLogging['LogPath']
$logFile = $initializationInfoLogging['LogFile']
$CSVFilePath = $initializationInfoLogging['CSVFilePath']
    
    
    
    
function AppendCSVLog {
    param (
        [string]$Message,
        [string]$CSVFilePath
           
    )
    
    $csvData = [PSCustomObject]@{
        TimeStamp    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        ComputerName = $env:COMPUTERNAME
        Message      = $Message
    }
    
    $csvData | Export-Csv -Path $CSVFilePath -Append -NoTypeInformation -Force
}
    
    
    
function CreateEventSourceAndLog {
    param (
        [string]$LogName,
        [string]$EventSource
    )
    
    
    # Validate parameters
    if (-not $LogName) {
        Write-Warning "LogName is required."
        return
    }
    if (-not $EventSource) {
        Write-Warning "Source is required."
        return
    }
    
    # Function to create event log and source
    function CreateEventLogSource($logName, $EventSource) {
        try {
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                New-EventLog -LogName $logName -Source $EventSource
            }
            else {
                [System.Diagnostics.EventLog]::CreateEventSource($EventSource, $logName)
            }
            Write-Host "Event source '$EventSource' created in log '$logName'" -ForegroundColor Green
        }
        catch {
            Write-Warning "Error creating the event log. Make sure you run PowerShell as an Administrator."
        }
    }
    
    # Check if the event log exists
    if (-not (Get-WinEvent -ListLog $LogName -ErrorAction SilentlyContinue)) {
        # CreateEventLogSource $LogName $EventSource
    }
    # Check if the event source exists
    elseif (-not ([System.Diagnostics.EventLog]::SourceExists($EventSource))) {
        # Unregister the source if it's registered with a different log
        $existingLogName = (Get-WinEvent -ListLog * | Where-Object { $_.LogName -contains $EventSource }).LogName
        if ($existingLogName -ne $LogName) {
            Remove-EventLog -Source $EventSource -ErrorAction SilentlyContinue
        }
        # CreateEventLogSource $LogName $EventSource
    }
    else {
        Write-Host "Event source '$EventSource' already exists in log '$LogName'" -ForegroundColor Yellow
    }
}
    
$LogName = (Get-Date -Format "HHmmss") + "_$LoggingDeploymentName"
$EventSource = (Get-Date -Format "HHmmss") + "_$LoggingDeploymentName"
    
# Call the Create-EventSourceAndLog function
CreateEventSourceAndLog -LogName $LogName -EventSource $EventSource
    
# Call the Write-CustomEventLog function with custom parameters and level
# Write-CustomEventLog -LogName $LogName -EventSource $EventSource -EventMessage "Outlook Signature Restore completed with warnings." -EventID 1001 -Level 'WARNING'
    
    
    
    
function Write-EventLogMessage {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
    
        [string]$LogName = "$LoggingDeploymentName",
        [string]$EventSource,
    
        [int]$EventID = 1000  # Default event ID
    )
    
    $ErrorActionPreference = 'SilentlyContinue'
    $hadError = $false
    
    try {
        if (-not $EventSource) {
            throw "EventSource is required."
        }
    
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            # PowerShell version is less than 6, use Write-EventLog
            Write-EventLog -LogName $logName -Source $EventSource -EntryType Information -EventId $EventID -Message $Message
        }
        else {
            # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
            $eventLog = New-Object System.Diagnostics.EventLog($logName)
            $eventLog.Source = $EventSource
            $eventLog.WriteEntry($Message, [System.Diagnostics.EventLogEntryType]::Information, $EventID)
        }
    
        # Write-host "Event log entry created: $Message" 
    }
    catch {
        Write-host "Error creating event log entry: $_" 
        $hadError = $true
    }
    
    if (-not $hadError) {
        # Write-host "Event log message writing completed successfully."
    }
}
    
    
    
    
function Write-EnhancedLog {
    param (
        [string]$Message,
        [string]$Level = 'INFO',
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
        [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
        [switch]$UseModule = $false,
        [string]$Caller = (Get-PSCallStack)[0].Command
    )
    
    # Add timestamp, computer name, and log level to the message
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Level] [$Caller] $Message"
    
    # Set foreground color based on log level
    switch ($Level) {
        'INFO' { $ForegroundColor = [ConsoleColor]::Green }
        'WARNING' { $ForegroundColor = [ConsoleColor]::Yellow }
        'ERROR' { $ForegroundColor = [ConsoleColor]::Red }
    }
    
    # Write the message with the specified colors
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    # Write-output $formattedMessage
    Write-host $formattedMessage
    $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
    
    # Append to CSV file
    AppendCSVLog -Message $formattedMessage -CSVFilePath $CSVFilePath
    AppendCSVLog -Message $formattedMessage -CSVFilePath $CentralCSVFilePath
    
    # Write to event log (optional)
    # Write-CustomEventLog -EventMessage $formattedMessage -Level $Level

    
    # Adjust this line in your script where you call the function
    # Write-EventLogMessage -LogName $LogName -EventSource $EventSource -Message $formattedMessage -EventID 1001
    
}
    
function Export-EventLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogName,
        [Parameter(Mandatory = $true)]
        [string]$ExportPath
    )
    
    try {
        wevtutil epl $LogName $ExportPath
    
        if (Test-Path $ExportPath) {
            Write-EnhancedLog -Message "Event log '$LogName' exported to '$ExportPath'" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
        else {
            Write-EnhancedLog -Message "Event log '$LogName' not exported: File does not exist at '$ExportPath'" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
        }
    }
    catch {
        Write-EnhancedLog -Message "Error exporting event log '$LogName': $($_.Exception.Message)" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
    }
}
    
# # Example usage
# $LogName = '$LoggingDeploymentNameLog'
# # $ExportPath = 'Path\to\your\exported\eventlog.evtx'
# $ExportPath = "C:\code\$LoggingDeploymentName\exports\Logs\$logname.evtx"
# Export-EventLog -LogName $LogName -ExportPath $ExportPath
    
    
    
    
    
    
#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################
    
    
    
Write-EnhancedLog -Message "Logging works" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    
    
#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################

function Initialize-OAuthToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$RefreshToken,

        [string]$Scope = "https://graph.microsoft.com/.default"
    )

    $TokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

    $Body = @{
        client_id     = $ClientId
        grant_type    = "refresh_token"
        refresh_token = $RefreshToken
        scope         = $Scope
    }

    try {
        $Response = Invoke-RestMethod -Uri $TokenUrl -Method Post -Body $Body -ContentType "application/x-www-form-urlencoded"

        # Assuming Write-EnhancedLog is defined elsewhere
        Write-EnhancedLog -Message "Token refreshed successfully." -Level "INFO" -ForegroundColor ([System.ConsoleColor]::Green)

        # Returning a hashtable of tokens and the headers for subsequent API requests
        return @{
            AccessToken  = $Response.access_token
            RefreshToken = $Response.refresh_token
            Headers = @{
                "Authorization" = "Bearer $($Response.access_token)"
                "Content-Type"  = "application/json"
            }
        }
    }
    catch {
        Write-Error "An error occurred while refreshing the OAuth token: $_"
    }
}


$OAuthParams = @{
    ClientId     = "xxxxxxxxxxxxxxx84e936411eb7"
    TenantId     = "contoso.onmicrosoft.com"
    RefreshToken = "0.Axxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

$TokenInfo = Initialize-OAuthToken @OAuthParams

$AccessToken = $TokenInfo['AccessToken']
$RefreshToken = $TokenInfo['RefreshToken'] # This might be the same as input if not returned by the server
$headers = $TokenInfo['Headers']

# Now you can use $AccessToken and $headers for your API requests




<#
.SYNOPSIS
Prompts the user to decide if they want to filter by a single device ID.

.DESCRIPTION
Asks the user if they want to filter the retrieval of BitLocker keys by a single device ID or get keys for all devices.

.OUTPUTS
String. Returns 'Y' or 'N' based on the user's choice.

.EXAMPLE
$UserChoice = Get-UserChoice
#>
function Get-UserChoice {
    return Read-Host "Do you want to filter by a single device ID? (Y/N)"
}





<#
.SYNOPSIS
Fetches the device ID based on the user's choice.

.DESCRIPTION
If the user opts to use the local device ID, it fetches the device ID using dsregcmd. Otherwise, it prompts for a custom device ID.

.OUTPUTS
String. The device ID.

.EXAMPLE
$DeviceId = Get-DeviceID -UseLocalDeviceId $true
#>
function Get-DeviceID {
    param (
        [bool]$UseLocalDeviceId
    )

    if ($UseLocalDeviceId) {
        $dsregcmdOutput = & dsregcmd /status
        $dsregcmdOutputString = $dsregcmdOutput -join "`n"

        if ($dsregcmdOutputString -match "DeviceId\s*:\s*([-\w]+)") {
            Write-EnhancedLog -Message "Local Device ID found: $($matches[1])" -Level "INFO" -ForegroundColor Green
            return $matches[1]
        } else {
            Write-EnhancedLog -Message "Local Device ID not found. Ensure the device is Azure AD joined." -Level "ERROR" -ForegroundColor Red
            exit 1
        }
    } else {
        $customDeviceId = Read-Host "Enter the custom Device ID"
        Write-EnhancedLog -Message "Using custom Device ID: $customDeviceId" -Level "INFO" -ForegroundColor Green
        return $customDeviceId
    }
}





<#
.SYNOPSIS
Constructs the Graph API URI for fetching BitLocker keys.

.DESCRIPTION
Based on the device ID provided, it constructs the URI for the Graph API to fetch BitLocker keys. If no device ID is provided, it constructs a URI to fetch keys for all devices.

.PARAMETER DeviceId
The device ID to filter the BitLocker keys retrieval. Optional.

.OUTPUTS
String. The constructed Graph API URI.

.EXAMPLE
$GraphUri = Construct-GraphApiUri -DeviceId 'your-device-id'
#>
function Construct-GraphApiUri {
    param (
        [string]$DeviceId
    )

    if ($DeviceId) {
        $FilterQuery = "`$filter=deviceId eq '$DeviceId'"
        $uri = "https://graph.microsoft.com/v1.0/informationProtection/bitlocker/recoveryKeys?$FilterQuery"
        Write-EnhancedLog -Message "Constructed URI with Device ID filter: $uri" -Level "INFO" -ForegroundColor Green
        return $uri
    } else {
        $uri = "https://graph.microsoft.com/v1.0/informationProtection/bitlocker/recoveryKeys"
        Write-EnhancedLog -Message "Retrieving Bitlocker keys for all devices..." -Level "INFO" -ForegroundColor Green
        return $uri
    }
}





<#
.SYNOPSIS
Converts a device ID to a device name using the Microsoft Graph API.

.DESCRIPTION
This function takes a device ID as input and queries the Microsoft Graph API to retrieve the corresponding device name.

.PARAMETER DeviceId
The unique identifier of the device.

.PARAMETER AccessToken
The OAuth2 access token with permissions to access Microsoft Graph API.

.OUTPUTS
String. The name of the device corresponding to the provided ID.

.EXAMPLE
$deviceName = Get-DeviceNameFromId -DeviceId "your-device-id" -AccessToken $accessToken

.NOTES
Requires the 'Device.Read.All' permission (or similar permissions) in Microsoft Graph API.
#>
function Get-DeviceNameFromId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DeviceId,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    # Assuming the Graph API version and base URL might change, it's good to parameterize it
    $GraphApiBaseUrl = "https://graph.microsoft.com/v1.0"
    $uri = "$GraphApiBaseUrl/devices/$DeviceId"

    try {
        # Prepare the headers for the HTTP request
        $headers = @{
            "Authorization" = "Bearer $AccessToken"
            "Content-Type"  = "application/json"
        }

        # Perform the REST method call to get the device information
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

        # Check if the response has the displayName property
        if ($response -and $response.displayName) {
            Write-EnhancedLog -Message "Successfully retrieved device name for ID: $DeviceId $($response.displayName)" -Level "INFO" -ForegroundColor Green
            return $response.displayName
        } else {
            Write-EnhancedLog -Message "The device with ID: $DeviceId does not have a displayName or could not be found." -Level "WARNING" -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        # Log the specific error message
        Write-EnhancedLog -Message "Failed to retrieve device name for ID: $DeviceId - Error: $($_.Exception.Message)" -Level "ERROR" -ForegroundColor Red
        
        # Re-throwing the exception to ensure the calling script is aware that an error occurred
        throw
    }
}





<#
.SYNOPSIS
Retrieves BitLocker keys from Azure AD using the Graph API.

.DESCRIPTION
Makes a GET request to the Graph API to fetch BitLocker keys based on the provided URI. Requires authorization headers to be set externally.

.PARAMETER GraphUri
The Graph API URI to fetch BitLocker keys.

.PARAMETER Headers
Authorization headers required for the Graph API request.

.EXAMPLE
Retrieve-BitLockerKeys -GraphUri $GraphUri -Headers $headers
#>

function Retrieve-BitLockerKeys {
    param (
        [string]$GraphUri,
        [hashtable]$Headers
    )

    try {
        $BitlockerKeysResponse = Invoke-RestMethod -Uri $GraphUri -Headers $Headers -Method Get

        if ($null -ne $BitlockerKeysResponse.value -and $BitlockerKeysResponse.value.Count -gt 0) {
            $accessToken = $Headers["Authorization"].Substring(7) # Assuming the Authorization header is in the format: Bearer <token>
            Write-EnhancedLog -Message "$($BitlockerKeysResponse.value.Count) Bitlocker key(s) found:" -Level "INFO" -ForegroundColor Green
            
            foreach ($key in $BitlockerKeysResponse.value) {
                # Retrieve the device name for the current device ID
                $deviceName = Get-DeviceNameFromId -DeviceId $key.deviceId -AccessToken $accessToken
                
                # Check if a device name was successfully retrieved
                if ($deviceName) {
                    Write-EnhancedLog -Message "Device Name: $deviceName - Key ID: $($key.id) - Created: $($key.createdDateTime) - Volume Type: $($key.volumeType) - Device ID: $($key.deviceId)" -Level "INFO" -ForegroundColor White
                } else {
                    Write-EnhancedLog -Message "Device name could not be retrieved for Device ID: $($key.deviceId)" -Level "WARNING" -ForegroundColor Yellow
                }
            }
        } else {
            Write-EnhancedLog -Message "No Bitlocker keys found for the specified criteria." -Level "WARNING" -ForegroundColor Yellow
        }
    } catch {
        Write-EnhancedLog -Message "Failed to query Bitlocker keys from Azure AD: $_" -Level "ERROR" -ForegroundColor Red
    }
}




# $headers = ... # Your headers setup here
$UserChoice = Get-UserChoice
$DeviceId = $null

if ($UserChoice -eq 'Y') {
    $DeviceChoice = Read-Host "Do you want to use the local device ID? (Y/N)"
    $UseLocalDeviceId = $DeviceChoice -eq 'Y'
    $DeviceId = Get-DeviceID -UseLocalDeviceId $UseLocalDeviceId
}

$GraphUri = Construct-GraphApiUri -DeviceId $DeviceId
Retrieve-BitLockerKeys -GraphUri $GraphUri -Headers $headers