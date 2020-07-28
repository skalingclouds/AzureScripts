$SQLServerName = ""
$rg = ""
(Get-AzVM -ResourceGroupName $rg -VMName $SQLServerName).HardwareProfile