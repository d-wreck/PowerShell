#-------------------------------------------------------------------------------------------------
# Overview: This script creates a nested scheduled task meme for the blue team
# Future Improvements: Move away from XML dependency, find fun payloads, and turn into a one-liner
#-------------------------------------------------------------------------------------------------

$Song = "\Never\Gonna\Give\You\Up\Never\Gonna\Let\You\Down\Never\Gonna\Run\Around\And\Desert\You\Never\Gonna\Make\You\Cry\Never\Gonna\Say\Goodbye\Never\Gonna\TellALieAndHurtYou"

# Create a nested folder and scheduled task for each lyric
for($i=1; $i -lt 30; $i++ ){
    $currentpath = ($song.split("\")[0..$i]) -join "\"
    $name = $currentpath.Split("\")[-1] 
    Register-ScheduledTask -Xml (get-content '.\rickastley.xml' | out-string) -TaskName "$name" -TaskPath "$currentpath"
}

######################
# Cleanup During testing
######################
<#
for($i=1; $i -lt 30; $i++ ){
    $currentpath = ($song.split("\")[0..$i]) -join "\"
    $name =$currentpath.Split("\")[-1] 
    Unregister-ScheduledTask -TaskName "$name" -TaskPath "$currentpath\" -Confirm:$false
}

# Apparently Unregister-ScheduledTask doesn't delete it, so it needs to be forcefully removed :(
# Needs PSExec because the registry path & folders are owned by SYSTEM
.\PSTools\PsExec64.exe -i -s powershell.exe -executionpolicy bypass -Command "Remove-item -path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Never\' -Force -Recurse"
.\PSTools\PsExec64.exe -i -s powershell.exe -executionpolicy bypass -Command "Remove-item 'C:\Windows\System32\Tasks\Never' -Force -Recurse"
#>
