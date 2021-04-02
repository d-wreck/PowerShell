#############################################################################################
# Overview: 
#         This script will rename & join a computer to a specified Active Directory domain
# Instructions: 
#           Customize the domain + ou section the script, then execute it on a computer. 
#           Respond to the prompts to enter credentials and computer name.
#############################################################################################

###START DO NOT MODIFY#####
# FORCE SELF-ELEVATION TO RUN AS ADMINISTRATOR
param([switch]$Elevated)
function Check-Admin {
$currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
if ((Check-Admin) -eq $false) {
    if ($elevated){
        # could not elevate, quit
    }
    else {
        # Elevate and launch script with executionpolicy set to bypass
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-executionpolicy bypass -noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}
#####END DO NOT MODIFY######

#########################
# Set Domain/OU Variables
#########################
$domain = "domain.local"
$ou = "OU=Workstations,DC=domain,DC=local"

# Define local user creds for elevation (assumes blank password)
$lcreds = Get-Credential -Message "Please enter Local Credentials that have admin rights to the current computer"

# Prompt for domain credentials
$dcreds = Get-Credential -Message "Please enter your domain credentials that have permissions to join computers to the domain"

# Prompt for the new computer name and force uppercase
$name = (Read-Host "Please enter the desired computer name").ToUpper()

# Add the computer to the domian, rename the computer, and force a restart
Add-Computer -NewName $name -DomainName $domain -OUPath $ou -Credential $dcreds -LocalCredential $lcreds -Restart
