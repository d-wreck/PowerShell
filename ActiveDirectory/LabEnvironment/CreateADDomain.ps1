#########################################################################################
# Overview: Simple script to quickly create a basic Windows2012R2 Active Driectory Domain 
#########################################################################################

###########################
# CUSTOMIZE THIS SECTION
$DomainName = "mylab.local" # Set the domain name
$AD_Database_Path = "C:" # Set the drive for the location of the Active Directory Database
# END CUSTOMIZATION SECTION
############################

# Installs Pre-req Features (Active Directory Domain Services & DNS)
Import-Module ServerManager
Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
Install-WindowsFeature DNS -IncludeAllSubFeature -IncludeManagementTools

# Create the Domain 
Import-Module ADDSDeployment
Import-Module DnsServer
Install-ADDSForest -DomainName $DomainName -InstallDns -DomainMode Win2012R2 -ForestMode Win2012R2 -DatabasePath $AD_Database_Path\Windows\NTDS -SysvolPath $AD_Database_Path\Windows\SYSVOL -LogPath $AD_Database_Path\Windows\Logs -Force
