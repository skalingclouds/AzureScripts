
    Param(
        [Parameter(Mandatory=$true)] 
        [string] $CertPassword,
        [Parameter(Mandatory=$true)] 
        [ArgumentCompleter({(Get-AzKeyVault).VaultName})]
        [string] $KeyVaultName,
        [Parameter(Mandatory=$true)] 
        [string] $CertName   
        
        )
$cert = Get-AzKeyVaultCertificate -VaultName $KeyVaultName -Name $CertName
$secret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $cert.Name

$secretByte = [Convert]::FromBase64String($secret.SecretValueText)
$x509Cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2
$x509Cert.Import($secretByte, "", "Exportable,PersistKeySet")
$type = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx
$pfxFileByte = $x509Cert.Export($type, $CertPassword)

# Write to a file
[System.IO.File]::WriteAllBytes("D:\sancertdg01.pfx", $pfxFileByte)


#Connect to Az and select subscription 
#Login-AzAccount
#Select-AzSubscription -SubscriptionName "<subscriptionname>" 

#$certString = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $CertName
#Create a PFX from the secret and write to disk 
#$kvSecretBytes = [System.Convert]::FromBase64String($certString.SecretValueText) 
#$certCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection 
#$certCollection.Import($kvSecretBytes,$null,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable) 
#$password = $Password 
#$protectedCertificateBytes = $certCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $password) 
#$pfxPath = $LocalPathForCert
#[System.IO.File]::WriteAllBytes($pfxPath, $protectedCertificateBytes)
