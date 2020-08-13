<#
    .SYNOPSIS
        This script is used to enable storage analytics logging on all storage accounts in all subscriptions.
    .DESCRIPTION
        The script supports enable storage analytics logging on all storage accounts in all subscriptions.
        To understand why Storage Analytics log is important, read this article https://azsec.azurewebsites.net/2019/12/09/security-monitoring-and-detection-tips-for-your-storage-account-part-1/

    .NOTES
        This script is written with Azure PowerShell Az module.
        File Name     : Set-AzStorageAnalyticsLog.ps1
        Version       : 1.0.0.0
        Author        : AzSec (https://azsec.azurewebsites.net/)
        Prerequisite  : Az
        Reference     : https://azsec.azurewebsites.net/2019/12/15/audit-azure-security-center-in-your-tenant/
    .EXAMPLE
        Set-AzureSecurityCenterInfo.ps1 -LogRetention 30 `
                                        -Version 2.0 `
#>

Param(
    [Parameter(Mandatory = $true,
        HelpMessage = "Log Retention of Storage Analytics in Day",
        Position = 0)]
    [ValidateRange(7, 365)]
    [Int]
    $LogRetention,

    [Parameter(Mandatory = $true,
        HelpMessage = "Logging version",
        Position = 1)]
    [ValidateSet("1.0", "2.0")]
    [string]
    $Version
)

$subscriptions = Get-AzSubscription
foreach ($subscription in $subscriptions) {
    Set-AzContext -SubscriptionId $subscription.id
    Write-Host -ForegroundColor Green "[-] Start checking subscription:" $subscription.Name
    $storageAccounts = Get-AzStorageAccount | Where-Object { $_.Sku.Tier -eq "Standard" }
    foreach ($storageAccount in $storageAccounts) {
        Write-Host -ForegroundColor Yellow "`t [-] Found a storage account named: " $storageAccount.StorageAccountName
        $key = Get-AzStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName `
            -AccountName $storageAccount.StorageAccountName `
        | Where-Object { $_.KeyName -eq "key1" }
        $ctx = New-AzStorageContext -StorageAccountName $storageAccount.StorageAccountName `
            -StorageAccountKey $key.Value
        $ctx | Set-AzStorageServiceLoggingProperty -ServiceType Blob -LoggingOperations All `
            -RetentionDays $LogRetention
        $logging = $ctx | Get-AzStorageServiceLoggingProperty -ServiceType Blob
        if ($logging.LoggingOperations -ne "None") {
            Write-Host -ForegroundColor Green "`t [-] Storage Analytics is enabled succesfully in storage account: "$storageAccount.StorageAccountName
        }
        elseif ($logging.LoggingOperations -eq "None") {
            Write-Host -ForegroundColor Red "[!] Storage Analytics is NOT enabled succesfully in storage account: "$storageAccount.StorageAccountName
        }
    }
}