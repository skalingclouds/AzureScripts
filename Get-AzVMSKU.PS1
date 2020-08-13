Param(
        [Parameter(Mandatory=$true)]
        [string] $SQLServerName,
        [Parameter(Mandatory=$true)]
        [string] $VMName
        )
(Get-AzVM -ResourceGroupName $Resourcegroup -VMName $SQLServerName).HardwareProfile