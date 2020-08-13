Param(
        [Parameter(Mandatory=$true)]
        [string] $VMName,
        [Parameter(Mandatory=$true)]
        [string] $ResourceGroup
        )
$vm= get-azvm -Name $VMName -ResourceGroupName "$ResourceGroup"
$osdisk = get-azdisk -name $vm.storageprofile.osdisk.name
write-host "OS Disk Name:" $osdisk.name "OS Disk Size in GB:" $osdisk.disksizegb "OS Disk SKU:" $osdisk.sku.name
$datadisks = $vm.StorageProfile.DataDisks
foreach ($disk in $datadisks) {
    $xdisk = get-azdisk -DiskName $disk.Name
    write-host "Data Disk Name:" $xdisk.name "Data Disk Size in GB:" $xdisk.disksizegb "Data Disk SKU" $xdisk.sku.name
}