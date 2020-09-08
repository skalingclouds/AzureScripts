
$vhdfullpath = ""
$vhdfullpathconverted = ""
$region = "westus2"
$rg = ""
$diskname = ""
$imagename = ""

#$vhdSizeBytes = (Get-vhd $vhdfullpath).Size
#$vhdSizeBytesrounded = [math]::Ceiling($vhdSizeBytes / 1MB)

Convert-VHD -Path $vhdfullpath -DestinationPath $vhdfullpathconverted -VHDType Fixed

start-sleep 3

$vhdSizeBytes = (Get-Item $vhdfullpathconverted).length
#$Resize-VHD -Path $vhdfullpathconverted -SizeBytes $vhdSizeBytesrounded

$diskconfig = New-AzDiskConfig -SkuName 'Standard_LRS' -OsType 'Windows' -UploadSizeInBytes $vhdSizeBytes -Location $region -CreateOption 'Upload' -HyperVGeneration "V1"

New-AzDisk -ResourceGroupName $rg -DiskName $diskname -Disk $diskconfig

$diskSas = Grant-AzDiskAccess -ResourceGroupName $rg -DiskName $diskname -DurationInSecond 86400 -Access 'Write'

$disk = Get-AzDisk -ResourceGroupName $rg -DiskName $diskname

AzCopy.exe copy $vhdfullpathconverted $diskSas.AccessSAS --blob-type PageBlob

Revoke-AzDiskAccess -ResourceGroupName $rg -DiskName $diskname

$diskID = $disk.Id
$imageConfig = New-AzImageConfig -Location $region
$imageConfig = Set-AzImageOsDisk -Image $imageConfig -OsState Generalized -OsType Windows -ManagedDiskId $diskID
New-AzImage -ImageName $imageName -ResourceGroupName $rg -Image $imageConfig