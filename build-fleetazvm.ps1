Param (
[Parameter(Mandatory=$true)] 
[string] $resourceGroup,
[Parameter(Mandatory=$true)] 
[string] $basecomputername,
[Parameter(Mandatory=$true)] 
[string] $keyvaultname,
[Parameter(Mandatory=$true)] 
[string] $region,
[Parameter(Mandatory=$true)] 
[int32] $numberofvms
)
#$region = "West US 2"
$count = 0
$vms = Get-AzVm 
foreach ($vm in $vms) {
    $count = $count + 1
    New-Variable -Scope Global -Force -Name $count -Value $vm
    $vmname = $vm.name
    write-host "Select $count for $vmname"
}
$govm = read-host "what is your selection"
if ($govm -eq 1){
    $selectedvmname = $1.Name
    $selectedvmrg = $1.ResourceGroupName
    write-host  "I will connect you to $selectedvmname at resource group $selectedvmrg"
}


$vmImageid = (Get-AzGalleryImageDefinition -ResourceGroupName "sc-coreinfra-01" -GalleryName scsig01).id

$username = (Get-AzKeyVaultSecret -vaultName $keyvaultname -name "VMUserName").SecretValueText
$username
$password = (Get-AzKeyVaultSecret -vaultName $keyvaultname -name "VMPassword").SecretValueText
$password
$VMLocalAdminUser = $username
$VMLocalAdminSecurePassword = ConvertTo-SecureString $password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

New-AzResourceGroup -Name $resourceGroup -location $region

$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name mySubnet -AddressPrefix 192.168.1.0/24

$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -location $region -Name MYvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig

while ($count -le $numberofvms) {
    
    $count = $count + 1
    $govmname = "$basecomputername$count"
    $nsgname = "nsg$govmname"
    $nicname = "nic$govmname"
    $pipname = "pip$govmname"
    $nsgrulename = "nsgrule$govmname"

    $pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -location $region -Name $pipname -AllocationMethod Static -IdleTimeoutInMinutes 4
    
    $nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name $nsgrulename -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow
    
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -location $region `
    -Name $nsgname -SecurityRules $nsgRuleRDP

    $nic = New-AzNetworkInterface -Name $nicname -ResourceGroupName $resourceGroup -location $region `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
    
    # Create a virtual machine configuration using $imageVersion.Id to specify the shared image
    $vmConfig = New-AzVMConfig -VMName $govmname -VMSize Standard_D1_v2 | `
    Set-AzVMOperatingSystem -Windows -ComputerName $govmname -Credential $Credential | `
    Set-AzVMSourceImage -Id $vmImageid | `
    Add-AzVMNetworkInterface -Id $nic.Id
    
    # Create a virtual machine
    New-AzVM -ResourceGroupName $resourceGroup -location $region -VM $vmConfig

    
}

Write-host "You now have $numberofvms built, enjoy your fleet" 
# End of the loop. 
# The loop will continue while $count is less than or equal to the $iterations variable set above.
#Get-AzPublicIpAddress -ResourceGroupName "myResourceGroup" | Select "IpAddress"
#mstsc /v:publicIpAddress