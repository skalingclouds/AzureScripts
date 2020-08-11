$kvname = "skalingcloudsdgkv01"
$certname = "wildcard-skalingclouds-io"

$pfxcontent = Get-Content 'C:\Users\joyw\Desktop\arsmpvm.pfx' -Encoding Byte
$base64Stringpfxcontent = [System.Convert]::ToBase64String($pfxcontent)

$json_new = @{
  value= $base64Stringpfxcontent
  pwd= "P@ssw0rd1234"
  policy= @{
    secret_props= @{
      contentType= "application/x-pkcs12"
    }
  }
}

$json = $json_new | ConvertTo-Json

$header = @{Authorization = "Bearer " + $token.access_token}
Invoke-RestMethod -Method Post -Uri "https://$kvname.vault.azure.net/certificates/$certname/import?api-version=7.0" -Body $json -Headers $header -ContentType "application/json"