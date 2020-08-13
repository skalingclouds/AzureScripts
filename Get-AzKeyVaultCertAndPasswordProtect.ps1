
    Param(
        [Parameter(Mandatory=$true)]
        [string] $CertPassword,
        [Parameter(Mandatory=$true)]
        [ArgumentCompleter({(Get-AzKeyVault).VaultName})]
        [string] $KeyVaultName,
        [Parameter(Mandatory=$true)]
        [string] $CertName,
        [Parameter(Mandatory=$true)]
        [string] $CertStoragePath
        )
$cert = Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $CertName
$secret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $cert.Name

$secretByte = [Convert]::FromBase64String($secret.SecretValueText)
$x509Cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2
$x509Cert.Import($secretByte, "", "Exportable,PersistKeySet")
$type = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx
$pfxFileByte = $x509Cert.Export($type, $CertPassword)

# Write to a file
[System.IO.File]::WriteAllBytes("$CertStoragePath", $pfxFileByte)
