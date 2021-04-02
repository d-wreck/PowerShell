############################################################
# Purpose: 
#
#   This script looks through all Active Directory Computer
#   objects and disables any that have not logged on in a 
#   specified number of days
#
###########################################################

# Sets the number of days since the last logon
$DaysInactive = 90

# Calculates the inactive cutoff date
$time = (Get-Date).Adddays(-($DaysInactive))

# Finds all Enabled inactive computers based on the calculated the cutoff date; also includes computers that have never been logged in
$computers = Get-ADComputer -Filter * -Properties LastLogonTimeStamp | Where {$_.enabled -eq $True -and ([datetime]::fromfiletime($_.lastlogontimestamp) -lt $time -or $_.lastlogontimestamp -eq $null)} 

# Loops through each inactive computer to disable them
foreach($computer in $computers){
    
    Try{
        Disable-ADAccount -Identity $computer
        Write-Host "$($computer.Name) was disabled" -ForegroundColor Green
        }

    Catch{
        $_
        }
}
