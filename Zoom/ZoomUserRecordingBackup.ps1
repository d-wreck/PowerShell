<# Overview: 
    This script is used to do a bulk download of Zoom Meeting recordings for a specific user over a specified time range.
    - Supports Zoom Commercial or Zoom for Government.
    - Works on Windows & MacOS.
______________
Pre-Requisites:
    1. Zoom Administrator Account
    2. Create & Activate a Zoom "Server-to-Server OAuth" App via the Zoom App Marketplace
            - COMMERCIAL URL: https://marketplace.zoom.us/
            - GOV: https://marketplace.zoomgov.com
        Required App Scopes:
            - View all user recordings (/recording:read:admin)
            - View and manage all user recordings (/recording:write:admin)
            - View all user information (/user:read:admin)
    
    DISCLAIMER: Exercise extreme caution with the generated App Credentials, these permissions are VERY SENSITIVE.
         Anyone with the credentials has the ability to access/download/manage ALL meeting recordings in your tenant
_____________
Instructions: 
    Execute the script and enter the information you're prompted for:
        - User Email Address - Self explanatory
        - Base Output directory - Where you want to store the downloaded recordings
            - Supports Windows or MacOS(i.e. C:\Users\User\ZoomRecordings or /Users/User/ZoomRecordings)
        - Start Date & End Date - The date range to download recordings for
        - Your Zoom Account ID, Application Client ID & Client Secret
            - All 3 are available on "App Credentials" page in the App Marketplace
___________
References:
https://developers.zoom.us/docs/internal-apps/create/
https://developers.zoom.us/docs/api/rest/reference/zoom-api/methods/#operation/recordingsList
https://developers.zoom.us/docs/api/rest/pagination/
#>


# Function to prompt for the backup directory to store recordings 
function New-UserBackupDirectory {
    param (
        [string]$userId
    )

    # Determine the correct path separator based on the operating system
    $pathSeparator = if ($PSVersionTable.OS -match "Windows") { '\' } else { '/' }

    # Prompt the user to enter the output directory
    $baseDirectory = Read-Host -Prompt "Enter the output directory for the downloaded recordings"

    # Ensure the base directory ends with the correct separator
    if (-not $baseDirectory.EndsWith($pathSeparator)) {
        $baseDirectory = "$baseDirectory$pathSeparator"
    }

    # Construct the user backup directory path
    $userBackupDirectory = "$baseDirectory$($userId.Split('@')[0])"

    # Check if the directory exists; if not, create it
    if (-Not (Test-Path -Path $userBackupDirectory)) {
        New-Item -ItemType Directory -Path $userBackupDirectory -Force | Out-Null
    }

    Write-Host "Backup directory is set to: $userBackupDirectory"
    return $userBackupDirectory
}

# Function to prompt for date range
function Get-ValidDate($prompt) {
    do {
        $dateInput = Read-Host $prompt

        # Try to parse the input as a DateTime in the specified format
        try {
            $date = [datetime]::ParseExact($dateInput, 'yyyy-MM-dd', $null)
            $validDate = $true
        }
        catch {
            Write-Host "Invalid date format. Please enter the date in YYYY-MM-DD format."
            $validDate = $false
        }
    } while (-not $validDate)

    return $date
}

# Function to prompt user to select the Zoom Environment
function Get-ZoomEnvironment {
    do {
        Write-Host "Please select your Zoom Environment:"
        Write-Host "1. COMMERCIAL"
        Write-Host "2. GOVERNMENT"
        
        $selection = Read-Host "Enter the number of your choice (1 or 2)"

        # Check if the input is either '1' or '2'
        switch ($selection) {
            1 {
                $choice = "COMMERCIAL"
                $validSelection = $true
                $zoomHost = "zoom.us"
                $zoomOauthUrl = "https://zoom.us/oauth/token"
                $zoomApiUrl = "https://api.zoom.us/v2"
            }
            2 {
                $choice = "GOVERNMENT"
                $validSelection = $true
                $zoomHost = "zoomgov.com"
                $zoomOauthUrl = "https://zoomgov.com/oauth/token"
                $zoomApiUrl = "https://api.zoomgov.com/v2"
            }
            default {
                Write-Host "Invalid input. Please enter 1 for 'COMMERCIAL' or 2 for 'GOVERNMENT'."
                $validSelection = $false
            }
        }
    } while (-not $validSelection)

    Write-Host "You selected: $choice"
    return $zoomHost,$zoomOauthUrl,$zoomApiUrl
}

# Function to obtain an OAuth 2.0 access token
function Get-ZoomAccessToken {
    param (
        [string]$accountId,
        [string]$clientId,
        [string]$clientSecret,
        [string]$zoomHost,
        [string]$zoomOauthUrl
    )

    $authHeader = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$clientId`:$clientSecret"))
    $headers = @{
        "Authorization" = "Basic $authHeader"
        "Host" = "$zoomHost"
        "Content-Type"  = "application/x-www-form-urlencoded"
    }
    $body =  @{ grant_type='account_credentials'; account_id="$accountId" }

    $response = Invoke-RestMethod -Uri "$zoomOauthUrl" -Method Post -Headers $headers -Body $body
    return @{
        AccessToken = $response.access_token
        ExpiresAt = (Get-Date).AddSeconds($response.expires_in)
    }
}

# Function to ensure the access token is valid
function Ensure-ZoomAccessToken {
    param (
        [hashtable]$zoomAccessToken
    )

    if ((Get-Date) -ge $zoomAccessToken.ExpiresAt) {
        Write-Output "Access token expired, refreshing..."
        $zoomAccessToken = Get-ZoomAccessToken -accountId $accountId -clientId $clientId -clientSecret $clientSecret -zoomHost $zoomHost -zoomOauthUrl $zoomOauthUrl
    }
    return $zoomAccessToken
}

# Function to fetch recordings for a user
function Get-ZoomRecordings {
    param (
        [string]$userId,
        [string]$zoomApiUrl,
        [string]$accessToken,
        [string]$fromDate,
        [string]$toDate,
        [string]$pageToken = $null
    )

    $headers = @{
        "Authorization" = "Bearer $accessToken"
    }

    $url = "$zoomApiUrl/users/$userId/recordings?from=$fromDate&to=$toDate"
    if ($pageToken) {
        $url += "&next_page_token=$pageToken"
    }

    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

    return $response
}

# Function to download a specific Zoom recording file
function Download-ZoomRecordingFile {
    param (
        [string]$url,
        [string]$downloadPath,
        [string]$accessToken,
        [string]$fileName
    )

    if (-Not (Test-Path -Path $downloadPath)) {
        $headers = @{
            "Authorization" = "Bearer $accessToken"
        }
    
        try {
            Write-Output "Downloading $fileName..."
            $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -OutFile $downloadPath
            Write-Output "Downloaded $fileName to $downloadPath"
        } catch {
            Write-Error "Failed to download file from $url`: $_"
        }
    }
    else{
        Write-Host "Recording download already exists for: $downloadPath"
    }
    
}

<# START THE SCRIPT #>

# Prompt for email address of user to backup
$userId = Read-Host -Prompt "Enter the email address of the user to backup"

# Prompt to create a directory to backup recordings for the user
$userBackupDirectory = New-UserBackupDirectory -userId $userId

# Prompt for the start date
$currentStartDate = Get-ValidDate "Please enter the start date (YYYY-MM-DD):"
# Prompt for the end date
$endDate = Get-ValidDate "Please enter the end date (YYYY-MM-DD):"

# Call the function and store the returned value
$zoomHost,$zoomOauthUrl,$zoomApiUrl = Get-ZoomEnvironment

# Prompt for Zoom Account ID
$accountId = Read-Host -Prompt "Enter your Zoom Account ID"

# Prompt for the Zoom Client ID and Client Secret
$zoomCredentials = Get-Credential -Message "Enter your Zoom App Client ID (User) and Client Secret (Password)"
$clientId = $zoomCredentials.UserName
$clientSecret = $zoomCredentials.GetNetworkCredential().Password

# Get the initial access token; lasts 1 hour
$zoomAccessToken = Get-ZoomAccessToken -accountId $accountId -clientId $clientId -clientSecret $clientSecret -zoomHost $zoomHost -zoomOauthUrl $zoomOauthUrl

while ($currentStartDate -le $endDate) {
    $currentEndDate = $currentStartDate.AddDays(29)
    if ($currentEndDate -gt $endDate) {
        $currentEndDate = $endDate
    }

    Write-Output "Fetching recordings from $currentStartDate to $currentEndDate..."
    # Ensure the access token is valid
    $zoomAccessToken = Ensure-ZoomAccessToken -zoomToken $zoomAccessToken
    #Get a list of recordings for the current date range
    $response = Get-ZoomRecordings -userId $userId -zoomApiUrl $zoomApiUrl -accessToken $zoomAccessToken.AccessToken -fromDate $currentStartDate.ToString("yyyy-MM-dd") -toDate $currentEndDate.ToString("yyyy-MM-dd")
    
    # Handle pagination if needed
    do {
        foreach ($meeting in $response.meetings) {
      
            # Create a direcotry for the curent meeting
            # Trim the topic for trailing spaces, and add the UUID to prevent adding multiple reordings for a singular meeting going to a single folder
            $meetingNameFormatted = "$($meeting.start_time.ToString("yyyy-MM-dd_HHmm"))_$($meeting.topic.TrimEnd())_$($meeting.uuid.TrimEnd())"
            
            # Replace invalid characters for SharePoint upload (there's probably a cleaner way to do this)
            $invalidChars = " * : < > ? / \ |"
            foreach ($char in $invalidChars.ToCharArray()) {
                $meetingNameFormatted = $meetingNameFormatted -replace [Regex]::Escape($char), "_"
            }
            # Create the download directory for the current meeting
            $meetingDownloadDirectory = Join-Path -Path $userBackupDirectory -Child $meetingNameFormatted
            if (-Not (Test-Path -Path $meetingDownloadDirectory)) {
                New-Item -ItemType Directory -Path $meetingDownloadDirectory -Force | Out-Null
            }
            # Download each of the recording files for the current meeting
            foreach ($recordingFile in $meeting.recording_files) {
                # Set the download Url, file name and download path
                $downloadUrl = $recordingFile.download_url
                $fileName = "$($recordingFile.id).$($recordingFile.file_type)"
                $downloadPath = Join-Path -Path $meetingDownloadDirectory -ChildPath $fileName

                # Ensure the access token is still valid
                $zoomAccessToken = Ensure-ZoomAccessToken -zoomToken $zoomAccessToken
                # Download the current recording file
                Download-ZoomRecordingFile -url $downloadUrl -downloadPath $downloadPath -accessToken $zoomAccessToken.AccessToken -fileName $fileName
            }
        }
        
        # Check for more pages
        if ($response.next_page_token) {
            # Ensure the access token is still valid
            $zoomAccessToken = Ensure-ZoomAccessToken -zoomToken $zoomAccessToken
            # Get the next page
            $response = Get-ZoomRecordings -userId $userId -zoomApiUrl $zoomApiUrl -accessToken $zoomAccessToken.AccessToken -fromDate $currentStartDate.ToString("yyyy-MM-dd") -toDate $currentEndDate.ToString("yyyy-MM-dd") -PageToken $response.next_page_token
        } else {
            $response = $null
        }
        
    } while ($response)

    # Move to the next 30-day period
    $currentStartDate = $currentStartDate.AddDays(30)
}