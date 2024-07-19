Sure, here's a re-written version of the README in a new format:

---

# BitLocker Key Retrieval Tool

This tool is designed to help you retrieve BitLocker keys from Intune using a delegated token. Follow these instructions to set up and use the tool effectively.

## Prerequisites

1. **App Registration in Entra (formerly Azure AD)**: You need to register an application in Entra.
2. **Configuration of `secrets.json` File**: Populate this file with the necessary credentials.

## Setup Instructions

### Step 1: Register an App in Entra

1. **Access the Entra Portal**: Open the Entra portal in your web browser.
2. **Navigate to App Registrations**: Go to **Azure Active Directory** > **App registrations**.
3. **Create a New Registration**:
   - Click on **New registration**.
   - Fill out the registration form:
     - **Name**: Provide a name for your application.
     - **Redirect URI**: Set this to `https://login.microsoftonline.com/common/oauth2/nativeclient`.
   - Click **Register** to complete the registration.
4. **Collect Important Details**:
   - On the app's overview page, note down the **Application (client) ID** and **Directory (tenant) ID**.
5. **Create a Client Secret**:
   - Navigate to **Certificates & secrets**.
   - Generate a new client secret and make sure to save its value.

### Step 2: Configure `secrets.json`

Create a `secrets.json` file in your project’s root directory with the following content:

```json
{
    "ClientId": "your-client-id-here",
    "ClientSecret": "your-client-secret-here",
    "TenantName": "your-tenant-name-here",
    "TenantId": "your-tenant-id-here"
}
```

Replace the placeholder values with your actual app registration details.

## Usage

### Step 1: Acquire Refresh Token Interactively - Part 1

Run the following command in PowerShell:

```powershell
./Acquire-RefreshTokenInteractively-Part1.ps1
```

This script will prompt you to sign in and grant permissions to your app. It securely stores a refresh token.

### Step 2: Acquire Refresh Token Interactively - Part 2

Next, execute:

```powershell
./Acquire-RefreshTokenInteractively-Part2.ps1
```

This script uses the previously obtained refresh token to acquire an access token. The resulting token is a delegated token, allowing non-interactive use with the BitLocker API, which only supports delegated permissions.

### Step 3: Retrieve BitLocker Keys

Finally, run the following script to retrieve the BitLocker keys:

```powershell
./Retrieve-BitLockerKeys-Intune-v3-REST-Filter-Interactive-MultipleChoice.ps1
```

This script uses the access token to interact with the BitLocker API and retrieve the necessary keys based on specified filters.

## Important Notes

- **BitLocker Recovery Key Requirement**: If your drive is BitLocker-encrypted, you'll need the recovery key to boot into Safe Mode.
- **Permissions**: Ensure your app has the required permissions in Entra to access BitLocker keys.
- **PowerShell Environment**: These scripts are designed to be executed in a PowerShell environment.

## Troubleshooting

For any issues, refer to the error messages provided by the scripts or consult the [Microsoft Graph API documentation](https://learn.microsoft.com/en-us/graph/use-the-api) for more information.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

---

Feel free to reach out for any further assistance.
