# Description: This script forcefully removes users from all EntraID/M365 groups when they are deactivated in Okta 
#   - Triggered via an Azure Function HTTP trigger when an Okta Event Hook fires (https://help.okta.com/en-us/content/topics/automation-hooks/event-hooks-main.htm)
#   - The Okta event hook should be configured to send the event when a user is deactivated or suspended
#   - An Entra ID app registration needs to be configured with these Graph API application permissions:
#       - Group.Read.All
#       - GroupMember.ReadWrite.All
#       - User.Read.All
#   - The Entra ID app registration client secret, client id, and Entra Tenant ID are stored as secrets in an Azure Key Vault.
#   - The Azure Function will need the system managed identity enabled and granted IAM access to read the secret(s) in the Key Vault
#   - Retreive Key Vault values into the Azure Function Application setting as environment variables with this key vault reference format:
#       - @Microsoft.KeyVault(SecretUri=https://<YOUR-VAULT-NAME>.vault.azure.net/secrets/<SECRET-NAME>/<SECRET-VERSION>)   # Copy the full URI from the secret properties in key vault
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

################################
# OKTA GET EVENT VERIFICATION HANDLER
################################
if ($Request.Method -eq "GET"){
    $okta_challenge = $Request.Headers["x-okta-verification-challenge"]
    if ($okta_challenge){
        $body = "{ 'verification' : '$okta_challenge' }"
        # Return body to complete Okta verification of URL ownership
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body = $body
        })
    }
}
###########################
# OKTA POST EVENT HANDLER
###########################
elseif ($Request.Method -eq "POST"){
    
    # Retrieve email address passed by Okta
    $email = $Request.Body.data.events[0].target[0].alternateId

    # Specify Tenant, Application Details, and load App Secret stored in KeyVault
    $tenantId = $env:TenantID
    $clientId = $env:ClientID
    $clientSecret = $env:ClientSecret
    
    # Initialize Entra ID Access Token for Graph API
    $tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    $requestBody = @{
        client_id     = $clientId
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $clientSecret
        grant_type    = "client_credentials"
    }
    # Get the access token using Secret Key
    $accessToken = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $requestBody

    # Build Graph API Header with temporary JSON Web Token
    $accessTokenValue = $accessToken.access_token
    $headers = @{
        'Authorization' = "Bearer $accessTokenValue"
        'Content-Type'  = 'application/json'
    }

    # Query Graph API for user
    $userEndpoint = "https://graph.microsoft.com/v1.0/users/$email"
    try {
        $userResponse = Invoke-RestMethod -Uri $userEndpoint -Method Get -Headers $headers
        Write-Host "User: $email, found in Entra ID, object id: $($userResponse.id)"
    }
    catch {
        Write-Host "User: $email, not found in Entra ID"
    }

    # Query Graph API for user's current group memberships
    if($userResponse){
        $userId = $userResponse.id
        $groupMembershipEndpoint = "https://graph.microsoft.com/v1.0/users/$userId/memberOf"
        try {
            $groupMembershipResponse = Invoke-RestMethod -Uri $groupMembershipEndpoint -Method Get -Headers $headers
             # Format output
            $userGroups = $groupMembershipResponse.value | Select-Object displayName, id
            Write-host "----Start Current Group Memberships----"
            $userGroups | ForEach-Object{ write-host "$($_.displayName) / $($_.id)" } # Display groups to console
            Write-host "----End Current Group Memberships----"
        }
        catch {
            Write-Host "Error doing group membership lookup for user: $email"
        }
    }

    # Lookup details for each group
    if($userGroups){
        foreach($group in $userGroups){
            $groupId = $group.id
            $groupDetailEndpoint = "https://graph.microsoft.com/v1.0/groups/$groupId"
            $groupDetails = "" # reset group details

            try{
                $groupDetails = Invoke-RestMethod -Uri $groupDetailEndpoint -Method Get -Headers $headers
                #Write-Host "$($groupDetails.id) --- $($groupDetails.groupTypes) --- $($groupDetails.displayName)" #testing
            }
            catch{
                Write-Host "Error doing group detail lookup for group: $group"
            }

            # If group does NOT have dynamic membership
            if (-NOT ($groupDetails.groupTypes -eq "DynamicMembership") -and $groupDetails){
                # Remove user from group                    
                # WARNING: If /$ref is not appended to the request and the calling app has permissions to manage the member object type, 
                #          the member object will also be deleted from Microsoft Entra ID (if user write permissions are granted)
                $removeMemberEndpoint = "https://graph.microsoft.com/v1.0/groups/$groupId/members/$userId/`$ref" 
                try{
                    Invoke-RestMethod -Uri $removeMemberEndpoint -Method DELETE -Headers $headers
                    Write-host "REMOVED User Email: $email / User ID: $userId , from Group Name: $($groupDetails.displayName) / Group ID: $($groupDetails.id)"
                }
                catch{
                    Write-host "Error removing User Email: $email / User ID: $userId , from Group Name: $($groupDetails.displayName) / Group ID: $($groupDetails.id)"
                    }
            }
            else {
                Write-host "SKIPPING Group Name: $($groupDetails.displayName) / Group ID: $($groupDetails.id), Reason: Dynamic Group "
            }
        }
    }

    # Push generic success output binding
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body = $null
        })

}