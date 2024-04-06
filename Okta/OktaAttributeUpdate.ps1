# Description: This script is used to do a bulk update of a singular Okta profile attribute (i.e. Department) 

# Import CSV; required headers "Username","Department"
$csvData = Import-Csv "C:\Path\to\your\file.csv" # UPDATE ME!
# Okta Admin URL
$Oktadomain = "<yourdomain>-admin.okta.com" # UPDATE ME!

# Start Script Section


# Prompt for Okta API key at runtime
$credential = Get-Credential -Message "Enter Okta API key" -UserName "Okta"

# Format Okta Request Authorization Headers
$headers = @{
    "Authorization" = "SSWS $($credential.GetNetworkCredential().Password)"
    "Content-Type" = "application/json"
}

foreach ($row in $csvData) {
    # Define the user's username and department from the CSV
    $username = $row.Username
    $department = $row.department

    # Construct the URL for the user profile endpoint
    $url = "https://$OktaDomain/api/v1/users?search=profile.login eq ""$username"""
    
    # Retrieve user data from Okta
    $userResponse = Invoke-RestMethod -Uri $url -Method Get -Headers $headers

    if ($userResponse.Count -eq 1 -and $userResponse.profile.department -ne $department) {
        # Extract user ID
        $userId = $userResponse[0].id
        
        # Construct the URL for updating the user profile
        $updateUrl = "https://$OktaDomain/api/v1/users/$userId"

        # Construct the payload with the updated department
        $payload = @{
            "profile" = @{
                "department" = $department
            }
        } | ConvertTo-Json

        # Update user profile in Okta
        try{
            $results = Invoke-RestMethod -Uri $updateUrl -Method POST -Headers $headers -Body $payload # POST needed for partial updates; PUT clears any unspecified attributes
            Write-Host "Updated department for user $username"
        }
        catch{
            Write-Host "Error updating department for $username"
        }
        
    }
    elseif ($userResponse.Count -eq 1 -and $userResponse.profile.department -eq $department) {
        Write-Host "User $username already has the correct department"
    }
    else {
        Write-Host "User $username not found in Okta"
    }
}