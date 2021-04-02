# Clear the specified event logs 
Clear-EventLog -LogName 'Windows PowerShell'
Clear-EventLog -LogName 'System'
(New-Object System.Diagnostics.Eventing.Reader.EventLogSession).ClearLog("Microsoft-Windows-PowerShell/Operational")
(New-Object System.Diagnostics.Eventing.Reader.EventLogSession).ClearLog("Microsoft-Windows-Sysmon/Operational")