Param (
[Parameter(Mandatory=$true)]
[string] $SpDisplayName,
[Parameter(Mandatory=$false)]
[string] $KeyVaultName
)
function New-ScriptSP  {
    $global:sp = New-AzADServicePrincipal -DisplayName $SpDisplayName
    $global:BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sp.Secret)
    $global:UnsecureSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $global:SpAppId = $sp.ApplicationId
}
function Remove-ScriptSp {
    if (Get-AzADServicePrincipal -DisplayName $SpDisplayName) {
        write-host "Found SP, Removing..."
        Remove-AzAdServicePrincipal -DisplayName $SpDisplayName
    }
    else {
        write-host "Could not find SP to delete"
    }
}
try {
    $storekv = Read-host "Would you like to put these in KeyVault? Y/n"
    if ($storekv = "y" -and ($KeyVaultName)) {
        New-ScriptSP
        write-host "Storing in KV"
        Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SpDisplayName -SecretValue $sp.Secret
        write-host "The SP ID is $SpAppId"
        write-host "The Password Is $UnsecureSecret"
        }
    elseif ($storekv = "n"){
        write-host "Will not store in keyVault..."
        New-ScriptSP
        write-host "The SP ID is $SpAppId"
        write-host "The Password Is $UnsecureSecret"
        }
    elseif (!$KeyVaultName) {
            write-host "You didn't specify a KeyVault Name, please re-run the command with the ""-KeyVaultName"" argument"
        }
}
Catch {
    #add more logic here
    Write-Host "An error occurred:"
    Write-Host $_
    Write-Host "Removing SP if created"
    Remove-ScriptSp
}