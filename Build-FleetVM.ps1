

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
#[string] $vnet,
#[string] $subnet
)
$vnet = "$basecomputername-vnet-wus2-01"
$subnet = 'serversubnet'
$sigGalleryName ='scsig01'
$sigResourceGroup = 'sc-coreinfra-01'


$vmImageid = (Get-AzGalleryImageDefinition -ResourceGroupName $sigResourceGroup -GalleryName $sigGalleryName).id
$username = (Get-AzKeyVaultSecret -vaultName $keyvaultname -name "VMUserName").SecretValueText
$password = (Get-AzKeyVaultSecret -vaultName $keyvaultname -name "VMPassword").SecretValueText
$VMLocalAdminUser = $username
$VMLocalAdminSecurePassword = ConvertTo-SecureString $password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

New-AzResourceGroup -Name $resourceGroup -location $region

$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnet -AddressPrefix 192.168.42.0/24

$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -location $region -Name $subnet `
 -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig

while ($count -le $numberofvms) {
    
    $count = $count + 1
    $vmname = "$basecomputername$count"
    $nsgname = "nsg$vmname"
    $nicname = "nic$vmname"
    $pipname = "pip$vmname"
    $nsgrulename = "nsgrule$vmname"

    $pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -location $region -Name $pipname -AllocationMethod Static -IdleTimeoutInMinutes 4
    
    $nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name $nsgrulename -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow
    
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -location $region `
    -Name $nsgname -SecurityRules $nsgRuleRDP

    $nic = New-AzNetworkInterface -Name $nicname -ResourceGroupName $resourceGroup -location $region `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
    
    # Create a virtual machine configuration using $imageVersion.Id to specify the shared image
    $vmConfig = New-AzVMConfig -VMName $vmname -VMSize Standard_DS4_v2 | `
    Set-AzVMOperatingSystem -Windows -ComputerName $vmname -Credential $Credential | `
    Set-AzVMSourceImage -Id $vmImageid | `
    Add-AzVMNetworkInterface -Id $nic.Id
    
    # Create a virtual machine
    New-AzVM -ResourceGroupName $resourceGroup -location $region -VM $vmConfig -AsJob
   
}

Write-host "You now have $numberofvms built, enjoy your fleet" 
