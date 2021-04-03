##########################################################################################################################
#
# Overview: This script will duplicate the User & Group assignments from one Azure AD Enterprise Application to another.
#           
# Use Case : I've had to migrate an AzureAD app to a new one because of major provisioing changes from a vendor. 
#            The application required 'user assignment' and had hundreds of users and groups assigned to it, so there was 
#            no way I was going to move those assignments over manually.
#
#########################################################################################################################

# Requires -modules AzureAD
Connect-AzureAD

# Enter the Display names of the old application and the new application
$app_name = "<OLD AZURE AD APP NAME>"
$new_app_name = "<NEW AZURE AD APP NAME>"
# Enter the name of the assigned role in the new application
$app_role_name = "User" 

# Retrieve the ADserviceprincipal information for the old/new apps
$sp = Get-AzureADServicePrincipal -Filter "DisplayName eq '$app_name'"
$sp_new = Get-AzureADServicePrincipal -Filter "DisplayName eq '$new_app_name'"

# Retreive the App Role that matches your input from before
$appRole = $sp_new.AppRoles | Where-Object { $_.DisplayName -eq $app_role_name }

# Get the current assignments for the old Azure AD Application
$assignments = Get-AzureADServiceAppRoleAssignment -ObjectId $sp.ObjectId -All $true

# Loop through current app assignments and duplicate in the new application (checks to see if it's a user/group and uses the appropriate cmdlet)
foreach ($assignment in $assignments){
    if($assignment.PrincipalType -eq "User"){New-AzureADUserAppRoleAssignment -ObjectId $assignment.PrincipalId -PrincipalId $assignment.PrincipalId -ResourceId $sp_new.ObjectId -Id $appRole.Id}
    if($assignment.PrincipalType -eq "Group"){New-AzureADGroupAppRoleAssignment -ObjectId $assignment.PrincipalId -PrincipalId $assignment.PrincipalId -ResourceId $sp_new.ObjectId -Id $appRole.Id}
}
