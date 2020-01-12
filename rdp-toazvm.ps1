$keyvaultname = ""
$vms = (get-azvm).Name 
$username = (Get-AzKeyVaultSecret -vaultName $keyvaultname -name "VMUserName").SecretValueText
$username
$password = (Get-AzKeyVaultSecret -vaultName $keyvaultname -name "VMPassword").SecretValueText
$password
Function Show-Menu {
    Param(
        [String[]]$vms
    )
    do { 
        Write-Host "Please make a selection"
        $index = 1
        foreach ($vm in $vms) {
            Write-Host "[$index] $vm"
            $index++
        }
        $Selection = Read-Host 
    } until ($vms[$selection-1])
    
    $selectedvm = $($vms[$selection-1])
    
    Write-Verbose "You selected $selectedvm" -Verbose
    
    $vmrg = (get-azvm -Name $selectedvm).ResourceGroupName
    $nicname =  (get-azvm -Name $selectedvm).NetworkProfile.NetworkInterfaces.Id.Split('/')[-1]
    $nicobject = (Get-AzNetworkInterface -name $nicname)
    $privateipaddress = $nicobject.IpConfigurations.PrivateIpAddress
    $publiciptest = (Get-azNetworkInterface -ResourceGroupName $vmrg -Name $nicname).IpConfigurations.PublicIpAddress.Id
    If ($publicIpTest){
        $publicIpName =  (Get-azNetworkInterface -ResourceGroupName $vmrg -Name $nicname).IpConfigurations.PublicIpAddress.Id.Split('/')  | Select-Object -Last 1
        $publicIpAddress = (Get-AzureRmPublicIpAddress -ResourceGroupName $vmrg -Name $publicIpName).IpAddress
        Write-Host "Public IP Exists, Connecting to $vmName via $publicIpAddress"
        cmdkey.exe /generic:$publicIpAddress /user:$username /pass:$password
        mstsc.exe /v $publicIpAddress /f
    } Else {
        cmdkey.exe /generic:$privateIpAddress /user:$username /pass:$password
        Write-Host "No Public IP, Connecting over Private IP"
        mstsc.exe /v $privateipaddress /f 
    }
}
$Selection = Show-Menu -vms $vms

