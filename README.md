# SNO365
Symantec Notifications Office 365 Email to Microsoft Teams Channel Alert

# NOTE:
Turns out it is far easier to just use the graylog SLACK webhook plugin to send alerts to M$ Teams channels. 
Functionality is limited, but it does work.
#

In practice I sugest using PowerGUI to wrap the powershell script into a windows service, allowing for easier uptime monitoring. 

Requires Microsoft Exchange WebServices 2.2.0 installed or atleast the Microsoft.Exchange.WebServices.dll.

