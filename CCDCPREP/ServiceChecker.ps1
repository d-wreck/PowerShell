# Basic script to check for the existence of a service and re-create it 

$servicename = "TestService"

If (Get-Service $servicename -ErrorAction SilentlyContinue){
    # Service Exists already, no action needed
}
Else{
    # Service got deleted, re-create it    
    $params = @{
      Name = $servicename
      BinaryPathName = '"C:\Path\To\My\Binaries.exe"'
      DisplayName = "Test Service"
      StartupType = "Automatic"
      Description = "Some Service Description"
    }

    # Create a new service with the splatted params and start it
    New-Service @params
    Start-Service $servcicename
}
