#########################################################################################
# Disclaimer: 
#     I did not write 95%+ of this script, I copied & tweaked SwifOnSecurity's OrgKit:
#     https://github.com/SwiftOnSecurity/OrgKit
#
# Overview: Creates the base of a heavily federated & tiered AD structure 
# 
########################################################################################

<# GENERAL HIERARCHY
\Departments
----\Department A
--------\Users
------------\Employees
----------------\Branch A
----------------\Branch B
----------------\Branch C
------------\Test Users
------------\Privileged Users
------------\Service Accounts
----------------\Tier0
----------------\Tier1
----------------\Tier2
--------\Workstations
------------\Branch A
------------\Branch B
------------\Branch C
------------\Test Workstations
--------\PAW
------------\Tier0
------------\Tier1
------------\Tier2
--------\Servers
------------\Tier0
------------\Tier1
------------\Tier2
--------\Groups
------------\Tier0
------------\Tier1
------------\Tier2
#>
################
# START SCRIPT #
################
Import-Module ActiveDirectory

# Enable AD Recycle Bin
Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target $env:USERDNSDOMAIN -Confirm:$false

# FUNCTIONS AND REFERENCE VARIABLES

# Create OU Function
function OrgKit-CreateOU{
    New-ADOrganizationalUnit -Name $OUName -Path $OUPath -Description $OUDescription
}

# Reference Variables for OU path
$CurrentDomain = Get-ADDomain
$RootDN = $CurrentDomain.DistinguishedName

# Reference variables for Departments, Branches and Tiers
$departments = "Department A", "Department B", "Department C"
$branches = "Human Resources", "Accounting", "Marketing", "Information Technology"
$tiers = "Tier0", "Tier1", "Tier2"

#########################
# START CREATION OF OUs #
#########################
# create Top level Departments OU: DOMAIN\Departments
$OUName = "Departments"
$OUPath = $RootDN
$OUDescription = ""
OrgKit-CreateOU

# Create OU structure for each department
foreach ($department in $departments){
    # Department: DOMAIN\Departments\Department <X>
    $DepartmentPath = "OU=$($Department),OU=Departments," + $RootDN

    $OUName = $department
    $OUPath = "OU=Departments," + $RootDN
    $OUDescription = ""
    OrgKit-CreateOU

    
    # Users: DOMAIN\Departments\Department <X>\Users
    $OUName = "Users"
    $OUPath = $DepartmentPath
    $OUDescription = ""
    OrgKit-CreateOU
        # Employees: DOMAIN\Departments\Department <X>\Users\Employees
        $OUName = "Employees"
        $OUPath = "OU=Users," + $DepartmentPath
        $OUDescription = ""
        OrgKit-CreateOU
            # Branches: DOMAIN\Departments\Department <X>\Users\Employees\<Branch>
            Foreach($branch in $branches){
                $OUName = $branch
                $OUPath = "OU=Employees,OU=Users," + $DepartmentPath
                $OUDescription = ""
                OrgKit-CreateOU
            }

        # Test Users: DOMAIN\Departments\Department <X>\Users\Test Users
        $OUName = "Test Users"
        $OUPath = "OU=Users," + $DepartmentPath
        $OUDescription = ""
        OrgKit-CreateOU

        # Privileged Users: DOMAIN\Departments\Department <X>\Users\Privileged Users
        $OUName = "Privileged Users"
        $OUPath = "OU=Users," + $DepartmentPath
        $OUDescription = ""
        OrgKit-CreateOU

        # Service Accounts: DOMAIN\Departments\Department <X>\Users\Service Accounts
        $OUName = "Service Accounts"
        $OUPath = "OU=Users," + $DepartmentPath
        $OUDescription = ""
        OrgKit-CreateOU
            # Tiers: DOMAIN\Departments\Department <X>\Users\Service Accounts\Tier<x> 
            Foreach($tier in $tiers){
                $OUName = $tier
                $OUPath = "OU=Service Accounts,OU=Users," + $DepartmentPath
                $OUDescription = ""
                OrgKit-CreateOU
            }

    # Workstations: DOMAIN\Departments\Department <X>\Workstations
    $OUName = "Workstations"
    $OUPath = $DepartmentPath
    $OUDescription = ""
    OrgKit-CreateOU

        # Branches: DOMAIN\Departments\Department <X>\Workstations\<Branch>
        Foreach($branch in $branches){
                $OUName = $branch
                $OUPath = "OU=Workstations," + $DepartmentPath
                $OUDescription = ""
                OrgKit-CreateOU
            }
        # Test Workstations: DOMAIN\Departments\Department <X>\Workstations\Test Workstations
        $OUName = "Test Workstations"
        $OUPath = "OU=Workstations," + $DepartmentPath
        $OUDescription = ""
        OrgKit-CreateOU
    

    # PAW: DOMAIN\Departments\Department <X>\PAW
    $OUName = "PAW"
    $OUPath = $DepartmentPath
    $OUDescription = ""
    OrgKit-CreateOU
        # Tiers: DOMAIN\Departments\Department <X>\PAW\Tier<X>
        Foreach($tier in $tiers){
                $OUName = $tier
                $OUPath = "OU=PAW," + $DepartmentPath
                $OUDescription = ""
                OrgKit-CreateOU
            }

    # Servers: DOMAIN\Departments\Department <X>\Servers
    $OUName = "Servers"
    $OUPath = $DepartmentPath
    $OUDescription = ""
    OrgKit-CreateOU
        # Tiers: DOMAIN\Departments\Department <X>\Servers\Tier<X>
        Foreach($tier in $tiers){
                $OUName = $tier
                $OUPath = "OU=Servers," + $DepartmentPath
                $OUDescription = ""
                OrgKit-CreateOU
            }

    # Groups: DOMAIN\Departments\Department <X>\Servers
    $OUName = "Groups"
    $OUPath = $DepartmentPath
    $OUDescription = ""
    OrgKit-CreateOU
        # Tiers: DOMAIN\Departments\Department <X>\Groups\Tier<X>
        Foreach($tier in $tiers){
                $OUName = $tier
                $OUPath = "OU=Groups," + $DepartmentPath
                $OUDescription = ""
                OrgKit-CreateOU
            }
}
