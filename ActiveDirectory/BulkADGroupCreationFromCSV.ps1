#############################################################
#
# Purpose: Bulk Import & Create AD groups from a CSV
#     
# Pre-Requisite: 
#    Create a CSV of Group Names with the following headers: 
#        DisplayName, Description, GroupOUPath, GroupScope, GroupCategory
#     
#############################################################

# Import the CSV of departments & desination OU paths
$groups = Import-Csv "C:\Path\To\ADGroups.csv"

Foreach ($group in $groups){
    # Set the parameters for the New-ADGroup CMDLET
    $params = @{
        Name = "$($group.DisplayName)"
        DisplayName = "$($group.DisplayName)"
        Description = "$($group.Description)"
        Path = "$($group.GroupOUPath)" # i.e. ou=CorpGroups,dc=corp,dc=local
        GroupScope = "$($group.GroupScope)" # i.e. Universal
        GroupCategory = "$($group.GroupCategory)" #i.e. Security
    }

    # Create the AD Group with the Splatted parameters
    New-ADGroup @params
}
