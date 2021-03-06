#Symantic Alert
#Email interactions based on: http://www.garrettpatterson.com/2014/04/18/checkread-messages-exchangeoffice365-inbox-with-powershell/
#Powershell to Teams WebHook based on: https://blogs.technet.microsoft.com/privatecloud/2016/11/02/post-notifications-to-microsoft-teams-using-powershell/
#Logging, infrastructure,design and development by Teagan Wilson

$logging = true;
$timer = (Get-Date -Format yyy-mm-dd-hhmm)
$Logfile = "C:\Scripts\Logs\" + $timer + ".log"
$uri = "#Office 356 WEBHOOK URL Goes HERE#"

Function LogWrite
{
if ($logging)
  {
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
  }
}


#Connect to the Inbox
[Reflection.Assembly]::LoadFile("C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll")
$s = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2007_SP1)
$s.Credentials = New-Object Net.NetworkCredential('#PUT O365 EMAIL LOGON HERE#', '#PUT PASSWORD HERE#', '#TENENT DOMAIN GOES HERE (yourtennerntdomain.com)#')
LogWrite $s.Credentials 
$s.Url = new-object Uri("https://outlook.office365.com/EWS/Exchange.asmx");
$inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($s,[Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox)
LogWrite "Retrived Inbox:"
$write = "Var:" +$inbox
LogWrite $write

#Find Folder for Completed Requests
$fv = new-object Microsoft.Exchange.WebServices.Data.FolderView(20)
$fv.Traversal = "Deep"
 
$ffname = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+ContainsSubstring([Microsoft.Exchange.WebServices.Data.FolderSchema]::DisplayName,"Complete")
 
$folders = $s.findFolders([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot,$ffname, $fv)
$completedfolder = $folders.Folders[0]
LogWrite "Retrived CompleteFolder Hook"


#Search Inbox for Un-read request Messages
$iv = new-object Microsoft.Exchange.WebServices.Data.ItemView(50)
$inboxfilter = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+SearchFilterCollection([Microsoft.Exchange.WebServices.Data.LogicalOperator]::And)
$ifisread = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::IsRead,$false)

#You can use the next two lines to get just meesages with a specific subject
#$ifsub = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+ContainsSubstring([Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::Subject,"User Profile Sync")
#$inboxfilter.add($ifsub)

$inboxfilter.add($ifisread)
$msgs = $s.FindItems($inbox.Id, $inboxfilter, $iv)
LogWrite "Got filtered messages:" 
$write = "Var:" +$msgs
LogWrite $write

#Read and process emails
$psPropertySet = new-object Microsoft.Exchange.WebServices.Data.PropertySet([Microsoft.Exchange.WebServices.Data.BasePropertySet]::FirstClassProperties)
$psPropertySet.RequestedBodyType = [Microsoft.Exchange.WebServices.Data.BodyType]::Text;
 
$s.LoadPropertiesForItems($msgs,$psPropertySet)
 
function getEmailField($msg, $field){
    $value = ""
    $pattern = "(?<=" + $field + ":s)[^s]+"
    return ([regex]::matches($msg, $pattern) | %{$_.value})
}

foreach ($msg in $msgs.Items)
{
		
		LogWrite "Message is:"
		$write = "Var:" + $msg
		LogWrite $write
		

		$body = ConvertTo-JSON @{
		    text = $msg.Subject + $msg.Body.Text
		}
		LogWrite "Email Body Converted to JSON"
		$write = $body
		LogWrite $write

		$status = Invoke-RestMethod -uri $uri -Method Post -body $body -ContentType 'application/json'
		LogWrite "WebHook Called:"
		$write = "Var:" + $status
		LogWrite $write
		
        # move message to previously located destination folder, then mark as read.
        $msg.Move($completedfolder.Id)
        $msg.IsRead = $true
        LogWrite "Message is read equals " + $msg.IsRead
		
}
 

		
