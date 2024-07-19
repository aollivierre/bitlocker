Here's a clear and detailed `README.md` for your GitHub repository:

```markdown
# BitLocker Key Retrieval Tool

This tool allows you to retrieve BitLocker keys from Intune using a delegated token. Follow the steps below to set up and use the tool.

## Prerequisites

1. Create an app registration in Entra (formerly Azure AD).
2. Populate the `secrets.json` file with the necessary credentials.

## Setting Up

### Step 1: Create an App Registration in Entra

1. Go to the Entra portal.
2. Navigate to **Azure Active Directory** > **App registrations**.
3. Click on **New registration**.
4. Fill in the registration form:
   - **Name**: Enter a name for your app.
   - **Redirect URI**: Set it to `https://login.microsoftonline.com/common/oauth2/nativeclient`.
5. Click **Register**.
6. After registration, go to the app's overview page and note down the **Application (client) ID** and **Directory (tenant) ID**.
7. Navigate to **Certificates & secrets** and create a new client secret. Note down the client secret value.

### Step 2: Populate the `secrets.json` File

Create a `secrets.json` file in the root directory of your project with the following content:

```json
{
    "ClientId": "your-client-id-here",
    "ClientSecret": "your-client-secret-here",
    "TenantName": "your-tenant-name-here",
    "TenantId": "your-tenant-id-here"
}
```

Replace the placeholder values with the actual values from your app registration.

## Usage

### Step 1: Run `Acquire-RefreshTokenInteractively-Part1`

Open PowerShell and run the following command:

```powershell
./Acquire-RefreshTokenInteractively-Part1.ps1
```

This script will prompt you to sign in and grant permissions to your app. After successful authentication, it will store a refresh token securely.

### Step 2: Run `Acquire-RefreshTokenInteractively-Part2`

Next, run the following command:

```powershell
./Acquire-RefreshTokenInteractively-Part2.ps1
```

This script uses the refresh token obtained in Part 1 to acquire an access token. The resulting token is a delegated token, meaning you can use it non-interactively as the BitLocker API only supports delegated permissions, not app permissions.

### Step 3: Run `Retrieve-BitLockerKeys-Intune-v3-REST-Filter-Interactive-MultipleChoice`

Finally, retrieve the BitLocker keys by running:

```powershell
./Retrieve-BitLockerKeys-Intune-v3-REST-Filter-Interactive-MultipleChoice.ps1
```

This script will use the access token to interact with the BitLocker API and retrieve the keys based on your specified filters.

## Notes

- Ensure you have the necessary permissions assigned to your app in Entra to access BitLocker keys.
- The scripts are designed to run in a PowerShell environment.

## Troubleshooting

If you encounter any issues, please refer to the error messages provided by the scripts or consult the [Microsoft Graph API documentation](https://learn.microsoft.com/en-us/graph/use-the-api) for more details.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

Feel free to reach out for any further assistance.

```

Replace the placeholders with the appropriate values and ensure the script names match the actual script files you have.
