Get-AzureAzProviderOperation microsoft.storage/* `
| Where-Object {$_.IsDataAction -eq $false} `
| Select-Object Operation
