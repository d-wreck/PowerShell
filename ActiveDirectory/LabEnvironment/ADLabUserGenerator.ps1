##########################################################################################
# Overview:
#     Bulk creates users for the lab environment and puts them in their corresponding OU
#     
# WARNING: 
#    The password for ALL users is in plaintext for simplicity of a lab environment
#    This should obviously never be used for a PRODUCTION environment
####################################################################################

$userlist = Import-Csv ".\userlist.csv"

$CurrentDomain = Get-ADDomain
$RootDN = $CurrentDomain.DistinguishedName
$domain = $CurrentDomain.Forest

foreach ($user in $userlist){
    $name = $user.fname.Trim()+" "+$user.lname.Trim()
    $upn = $user.fname.Trim()+"."+$user.lname[0]+"@"+$domain
    $sam = $user.fname.Trim()+"."+$user.lname[0]
    $OU_path = "OU=$($user.office),OU=Employees,OU=Users,OU=$($user.dept),OU=Departments," + $RootDN

    New-ADUser -AccountPassword (ConvertTo-SecureString “Password123!” -AsPlainText -Force) -Department $user.dept -Office $user.office -path $OU_path -DisplayName $name -EmailAddress $upn -Enabled $true -GivenName $user.fname -Name $name -SamAccountName $sam -Surname $user.lname -UserPrincipalName $upn

    Write-Host “Created user : ” $name
}
