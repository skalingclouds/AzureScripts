$resourceProvider = "Microsoft.Storage"
Get-AzLog -StartTime (Get-Date).AddDays(-1d) -ResourceProvider $resourceProvider `
| ForEach-Object{
Write-Host -ForegroundColor White "--------------"
Write-Host -ForegroundColor Green "ResourceId:" $_.ResourceId.Split('/')[8]
Write-Host -ForegroundColor Blue "ResourceGroupName": $_.ResourceGroupName
Write-Host -ForegroundColor Yellow "Action:" $_.Authorization.Action
write-host -ForegroundColor Red "By User:" $_.Caller
Write-Host -ForegroundColor White "--------------"
write-host
}





