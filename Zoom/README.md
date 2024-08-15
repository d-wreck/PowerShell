# Zoom User Meeting Recordings Bulk Downloader

This PowerShell script is designed to facilitate the bulk downloading of Zoom Meeting recordings for a specific user over a specified time range. The script supports both Zoom Commercial and Zoom for Government environments and is compatible with Windows and macOS.

## Features

- **Platform Support**: Works on both Windows and macOS.
- **Zoom Environments**: Compatible with both Zoom Commercial and Zoom for Government.
- **Custom Date Range**: Download recordings within a specified date range.
- **Secure OAuth Integration**: Utilizes Zoom's Server-to-Server OAuth App for secure access.

## Pre-Requisites

1. **Zoom Administrator Account**
2. **Zoom Server-to-Server OAuth App**:
   - Create and activate the app via the Zoom App Marketplace.
     - **Commercial URL**: [Zoom Marketplace](https://marketplace.zoom.us/)
     - **Government URL**: [ZoomGov Marketplace](https://marketplace.zoomgov.com)
   - **Required App Scopes**:
     - View all user recordings (`/recording:read:admin`)
     - View and manage all user recordings (`/recording:write:admin`)
     - View all user information (`/user:read:admin`)

> **DISCLAIMER**: Handle the generated app credentials with extreme caution. These permissions are very sensitive, and unauthorized access could result in data exposure.

## Usage Instructions

1. **Execute the Script**: Run the script in PowerShell and follow the prompts.
2. **Input the Required Information**:
   - **User Email Address**: The email address of the user whose recordings you wish to download.
   - **Base Output Directory**: The directory where the downloaded recordings will be stored.
     - Example for Windows: `C:\Users\User\ZoomRecordings`
     - Example for macOS: `/Users/User/ZoomRecordings`
   - **Date Range**: The start and end dates for the recordings you wish to download.
   - **Zoom Account ID, Client ID, and Client Secret**: Obtain these from the "App Credentials" page in the Zoom App Marketplace.

## Script Details

The script includes the following key functions:

- **New-UserBackupDirectory**: Prompts the user to select a backup directory for storing the recordings.
- **Get-ValidDate**: Validates and parses the date input provided by the user.
- **Get-ZoomEnvironment**: Prompts the user to select the Zoom environment (Commercial or Government).
- **Get-ZoomAccessToken**: Obtains an OAuth 2.0 access token for authenticating API requests.
- **Ensure-ZoomAccessToken**: Ensures the access token is valid and refreshes it if necessary.
- **Get-ZoomRecordings**: Retrieves the recordings for the specified user within the given date range.
- **Download-ZoomRecordingFile**: Downloads the recording files to the specified directory.

## References

- [Creating a Zoom OAuth App](https://developers.zoom.us/docs/internal-apps/create/)
- [Zoom API - Recordings List](https://developers.zoom.us/docs/api/rest/reference/zoom-api/methods/#operation/recordingsList)
- [Zoom API Pagination](https://developers.zoom.us/docs/api/rest/pagination/)

## License

This script is provided "as-is" without any warranty or support. Please use it at your own risk.

---

For more details, refer to the inline comments within the script.
