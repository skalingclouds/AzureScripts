Param (
[string] $resourceGroup,
[string] $basecomputername,
[string] $keyvaultname,
[int32] $numberofvms
)

$count = 1
$username = (Get-AzKeyVaultSecret -vaultName $keyvaultname -name "VMUserName").SecretValueText
$username
$password = (Get-AzKeyVaultSecret -vaultName $keyvaultname -name "VMPassword").SecretValueText
$password
$VMLocalAdminUser = $username
$VMLocalAdminSecurePassword = ConvertTo-SecureString $password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
# Start of the loop.
while ($count -le $numberofvms){

New-AzVm `
    -ResourceGroupName $resourceGroup `
    -Name "fleetvm$count" `
    -Location "West US 2" `
    -VirtualNetworkName "FleetVnet" `
    -SubnetName "FleetSubnet" `
    -SecurityGroupName $basecomputername"sg"$count `
    -PublicIpAddressName $basecomputername"ip"$count `
    -OpenPorts 80,3389 `
    -credential $Credential
    
    # Increase the value of $count by 1.
    # This is equivalent to $count = $count + 1
    $count++

}
Write-host "You now have $numberofvms built, enjoy your fleet" 
# End of the loop. 
# The loop will continue while $count is less than or equal to the $iterations variable set above.