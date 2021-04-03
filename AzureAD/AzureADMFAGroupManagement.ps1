#==============================================================================================
# Overview:
#       This script dynamically manages the membership of an AzureAD Group based on MFA 
#       registration status. Azure AD has native dynamic groups, but at the time of writing
#       this script, Microsoft does not provide an MFA attribute to use for this use case.
#
# Comments: 
#      This script was designed to run via a scheduled task. Credentials are ingested from
#      an encrypted text file, and it is highly recommended to secure that file in production.
#
#Requires -Module MSOnline
#Requires -Module AzureAD
#
#=============================================================================================

#========== MODIFY ME ============
#region Variables to Configure

# AzureAD GroupID & GroupName
$MFAUsersGroup_ID = "12345678-abc1-wxyz-12a3-12345678910x" # Object ID of the Group
$MFAUsersGroupName = "MFA Registered Users"

# Account Credentials: Service Account should have access to to manage users/group membership
$AdminEmailAddress = "o365serviceaccount@domain.com"
$PasswordFile = "C:\Path\To\Encrypted\CredentialFile.txt" # Make Sure this is an encrypted & secured password file!

# Log file location
$Log = "C:\Path\To\LogFile.Log"

#endregion Variables to Configure
#====== DO NOT MODIFY BELOW THIS LINE ======

#====== LOGGING SECTION ==================
#region Log Initialization

# Trim the current Log file in half if too large
If (Test-Path $Log) {
    
    $SizeMax = 100 
 
    $Size = (Get-ChildItem $Log | Measure-Object -property length -sum)  
 
    $SizeMb="{0:N2}" -f ($size.sum / 1MB) + "MB" 
 
    if ($sizeMb -ge $sizeMax) { 
 
        Get-Content $Log | Measure-Object | ForEach-Object { $sourcelinecount = $_.Count }
        $half = $sourcelinecount/2 
        (Get-Content $Log) | Select-Object -Skip $half | set-content $Log
    } 
}
# Logging function for adding/removing AzureAD Group Members
function LogGroupMemberChange{
    
    param($log_user, $log_group, $log_action, $log_error)

    $date = get-date -Uformat "%Y-%m-%d %r"

    switch($log_action){
        "ADDED"{Add-Content -Path $Log "$date - $log_action $log_user to $log_group"}
        "REMOVED"{Add-Content -Path $Log "$date - $log_action $log_user from $log_group"}
        "ERROR ADDING"{Add-Content -Path $Log "$date - $log_action $log_user to $log_group with the following error:`r`n $log_error"}
        "ERROR REMOVING"{Add-Content -Path $Log "$date - $log_action $log_user from $log_group with the following error: `r`n $log_error"}
    }
}

# Start logging
$date = get-date -Uformat "%Y-%m-%d %r"
Add-Content -Path $Log "========================================= START =========================================`r`n"
Add-Content -Path $Log "$date - Starting Group Management Script Execution"

#endregion Log Initialization
#====== END LOGGING SECTION ==============

#====== SERVICE CONNECTION SECTION =======
#region Service Connect

# Ingest Credentials 
$Password = Get-Content $passwordFile | ConvertTo-SecureString
$Credential = New-Object -typename System.Management.Automation.PSCredential -ArgumentList $AdminEmailAddress,$Password

# Connect to MSOnline & AzureAD PowerShell
Connect-MsolService -Credential $Credential
Connect-AzureAD -Credential $Credential

#endregion Service Connect
#====== END SERVICE CONNECTION SECTION ======

#====== BUILD GROUP MEMBERSHIP HASH TABLE ======
#region Hash Table

# Get the current group membership and build a lookup hash
[PSObject]$MFAGroupMembers = Get-AzureADGroupMember -ObjectId $MFAUsersGroup_ID -All $True

$MFAUserIndex = $null
$MFAUserIndex = @{}

foreach($u in $MFAGroupMembers){
    $MFAUserIndex.Add($u.ObjectID,$u.UserPrincipalName)
}
#endregion Hash Table
#====== END GROUP MEMBERSHIP HASH TABLE BUILDING ======

#====== START CORE SCRIPT ======
#region User Management

# Get all users (excludes guest objects)
[PSObject]$AllUsers = Get-MsolUser -all | 
    Where-Object {-and $_.UserType -eq "Member"} | 
        Select-Object UserPrincipalName,@{n="ObjectID";e={$_.objectid.guid}},StrongAuthenticationMethods

# Loop through all users to evaluate current MFA Status and modify group membership where applicable
foreach ($user in $AllUsers){

    # Handle users that are NOT registered for MFA 
    if(-not($null -ne $user.strongauthenticationmethods)){
        # Is the current user a member of the MFA Registered Users Group?
        if($MFAUserIndex.ContainsKey($user.ObjectID)){
            # User is a member of the MFA Registered Users Group, remove them from the group because they aren't registered for MFA anymore
            try{
                Remove-AzureADGroupMember -ObjectId $MFAUsersGroup_ID -MemberId $user.ObjectID
                LogGroupMemberChange -log_user $user.UserPrincipalName -log_group $MFAUsersGroupName -log_action "REMOVED"
            }
            catch{
                LogGroupMemberChange -log_user $user.UserPrincipalName -log_group $MFAUsersGroupName -log_action "ERROR REMOVING" -log_error $_                    
            }
        } # End of users that are in the MFA Registered Users Group
    } # End of users that are NOT registered for MFA

    # Handle users that ARE registered for MFA
    elseif($null -ne $user.strongauthenticationmethods){
        # Is the current user a member of the MFA Registered Users Group?
        if($MFAUserIndex.ContainsKey($user.ObjectID) -eq $false){
            # User is not a member of the MFA Registered Users Group, add them to the group
            try{
                Add-AzureADGroupMember -ObjectId $MFAUsersGroup_ID -RefObjectId $user.ObjectID
                LogGroupMemberChange -log_user $user.UserPrincipalName -log_group $MFAUsersGroupName -log_action "ADDED"
            }
            catch{
                LogGroupMemberChange -log_user $user.UserPrincipalName -log_group $MFAUsersGroupName -log_action "ERROR ADDING" -log_error $_
            }   
        } # End of users that are not in the MFA Registered Users Group
    } # End of users that ARE registered for MFA   
}
#endregion User Management
#====== END CORE SCRIPT ======

# Disconnect Azure AD Session, there is no MSOLService Equivalent
Disconnect-AzureAd

# Stop logging
$date = get-date -Uformat "%Y-%m-%d %r"
Add-Content -Path $Log "$date - Group Management Script Execution Complete"
Add-Content -Path $Log "==========================================================================================`r`n"