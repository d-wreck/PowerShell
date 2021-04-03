##############################################################################################
# Overview: This script is used for sending basic/test emails through an internal SMTP server 
#############################################################################################

# Set the connections security level (may or may not be required, depends on the environment)
[System.Net.ServicePointManager]::SecurityProtocol = 'Tls,TLS11,TLS12'

# Enter AD credentials that have access to the SMTP Server
$credentials = Get-Credential

# Configure message settings
$params = @{
    From = "no-reply@domain.com" # You can usually put whatever address you want
    To = "recipient@domain.com"
    #ReplyTo = "different_from@domain.com" # Optional, but Requires PowerShell 7
    Subject = "TEST SMTP Message"
    Body = "TESTING SMTP MESSAGE"
    SmtpServer = "smtpserver.domain.com" # Or IP Address!
    UseSsl = $true # Establish a secure connection (may or may not be required, depends on the environment)
    Credential = $credentials
}

# Send the message
Send-MailMessage @params
