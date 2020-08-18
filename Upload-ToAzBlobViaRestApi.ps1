#Our source File:
$sastoken =  "YOURSASTOKENHERE"

$file = "D:\datacollector01.zip"

#Get the File-Name without path
$name = (Get-Item $file).Name

#The target URL wit SAS Token
$uri = "https://skalingcloudssecurestore.blob.core.windows.net/logs/$($name)$sastoken"

#Define required Headers
$headers = @{
    'x-ms-blob-type' = 'BlockBlob'
}

#Upload File...
Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -InFile $file 
