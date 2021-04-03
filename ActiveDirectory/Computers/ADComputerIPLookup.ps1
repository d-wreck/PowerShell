###################################################################################################################################
# Overview: I used to throw these functions in my PowerShell profile because I would frequently look up the hostname from an 
#           IP address, and our environment didn't allow reverse lookups, so I found my own workaround.
###################################################################################################################################

# Use this function to look up the hostname for a specific IP address 
function ADComputerIPLookup ($IP_Address){ 
    try{
        Get-ADComputer -properties canonicalname,ipv4address -filter {ipv4address -eq $IP_Address} | Select name, ipv4address, canonicalname
    }
    catch{
        Write-Host "ERROR: No host found matching IP address: $IP_Address" -foregroundcolor red
    }
}

# Use this function to look up the IP addresses for all AD computers with a searchable/sortable popup 
function ADComputerIPGridView{ 
    get-adcomputer -filter * -properties canonicalname,ipv4address | Select name, ipv4address, canonicalname | Out-GridView 
} 
