$subscriptionId = Select-AzSubscription "d7cc508e-d2cc-46d7-8185-5b4cb24827bb"
$resGroupName = "fa-digtalgateway-02" # resource group name
$location = "West US 2"           # Azure region
$appgatewaysubnet = New-AzVirtualNetworkSubnetConfig -Name "apim01" -AddressPrefix "10.0.0.0/24"
$apimsubnet = New-AzVirtualNetworkSubnetConfig -Name "apim02" -AddressPrefix "10.0.1.0/24"
$vnet = New-AzVirtualNetwork -Name "appgwvnet" -ResourceGroupName $resGroupName -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $appgatewaysubnet,$apimsubnet
$appgatewaysubnetdata = $vnet.Subnets[0]
$apimsubnetdata = $vnet.Subnets[1]
$apimVirtualNetwork = New-AzApiManagementVirtualNetwork -SubnetResourceId $apimsubnetdata.Id
$apimServiceName = "SkalingCloudsApi"       # API Management service instance name
$apimOrganization = "SkalingClouds"         # organization name
$apimAdminEmail = "chris.skaling@gmail.com" # administrator's email address
$apimService = New-AzApiManagement -ResourceGroupName $resGroupName -Location $location -Name $apimServiceName -Organization $apimOrganization -AdminEmail $apimAdminEmail -VirtualNetwork $apimVirtualNetwork -VpnType "Internal" -Sku "Premium"

$gatewayHostname = "api.skalingclouds.io"                 # API gateway host
$portalHostname = "portal.skalingclouds.io"               # API developer portal host
$gatewayCertCerPath = "D:\digitalgateway.cer" # full path to api.contoso.net .cer file
$gatewayCertPfxPath = "D:\KeyVault.pfx" # full path to api.contoso.net .pfx file
$portalCertPfxPath = "D:\KeyVault.pfx"   # full path to portal.contoso.net .pfx file
$gatewayCertPfxPassword = "0316C0nn3ct4!!!!!"   # password for api.contoso.net pfx certificate
$portalCertPfxPassword = "0316C0nn3ct4!!!!!"    # password for portal.contoso.net pfx certificate

$proxyHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $gatewayHostname -HostnameType Proxy -PfxPath $gatewayCertPfxPath -PfxPassword $certPwd
$portalHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $portalHostname -HostnameType DeveloperPortal -PfxPath $portalCertPfxPath -PfxPassword $certPortalPwd

$apimService.ProxyCustomHostnameConfiguration = $proxyHostnameConfig
$apimService.PortalCustomHostnameConfiguration = $portalHostnameConfig
Set-AzApiManagement -InputObject $apimService -Error 

$publicip = New-AzPublicIpAddress -ResourceGroupName $resGroupName -name "scagwpublicIP01" -location $location -AllocationMethod Dynamic
$gipconfig = New-AzApplicationGatewayIPConfiguration -Name "gatewayIP01" -Subnet $appgatewaysubnetdata
$fp01 = New-AzApplicationGatewayFrontendPort -Name "port01"  -Port 443
$fipconfig01 = New-AzApplicationGatewayFrontendIPConfig -Name "frontend1" -PublicIPAddress $publicip
$cert = New-AzApplicationGatewaySslCertificate -Name "cert01" -CertificateFile $gatewayCertPfxPath -Password $certPwd
$certPortal = New-AzApplicationGatewaySslCertificate -Name "cert02" -CertificateFile $portalCertPfxPath -Password $certPortalPwd
$listener = New-AzApplicationGatewayHttpListener -Name "listener01" -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $cert -HostName $gatewayHostname -RequireServerNameIndication true
$portalListener = New-AzApplicationGatewayHttpListener -Name "listener02" -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 -SslCertificate $certPortal -HostName $portalHostname -RequireServerNameIndication true
$apimprobe = New-AzApplicationGatewayProbeConfig -Name "apimproxyprobe" -Protocol "Https" -HostName $gatewayHostname -Path "/status-0123456789abcdef" -Interval 30 -Timeout 120 -UnhealthyThreshold 8
$apimPortalProbe = New-AzApplicationGatewayProbeConfig -Name "apimportalprobe" -Protocol "Https" -HostName $portalHostname -Path "/signin" -Interval 60 -Timeout 300 -UnhealthyThreshold 8
$authcert = New-AzApplicationGatewayAuthenticationCertificate -Name "whitelistcert1" -CertificateFile $gatewayCertCerPath
$apimPoolSetting = New-AzApplicationGatewayBackendHttpSettings -Name "apimPoolSetting" -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimprobe -AuthenticationCertificates $authcert -RequestTimeout 180
$apimPoolPortalSetting = New-AzApplicationGatewayBackendHttpSettings -Name "apimPoolPortalSetting" -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimPortalProbe -AuthenticationCertificates $authcert -RequestTimeout 180
$apimProxyBackendPool = New-AzApplicationGatewayBackendAddressPool -Name "apimbackend" -BackendIPAddresses $apimService.PrivateIPAddresses[0]
$rule01 = New-AzApplicationGatewayRequestRoutingRule -Name "rule1" -RuleType Basic -HttpListener $listener -BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolSetting
$rule02 = New-AzApplicationGatewayRequestRoutingRule -Name "rule2" -RuleType Basic -HttpListener $portalListener -BackendAddressPool $apimProxyBackendPool -BackendHttpSettings $apimPoolPortalSetting
$sku = New-AzApplicationGatewaySku -Name "WAF_Medium" -Tier "WAF" -Capacity 2
$config = New-AzApplicationGatewayWebApplicationFirewallConfiguration -Enabled $true -FirewallMode "Detection"
$appgwName = "apim-app-gw"
$appgw = New-AzApplicationGateway -Name $appgwName -ResourceGroupName $resGroupName -Location $location -BackendAddressPools $apimProxyBackendPool -BackendHttpSettingsCollection $apimPoolSetting, $apimPoolPortalSetting  -FrontendIpConfigurations $fipconfig01 -GatewayIpConfigurations $gipconfig -FrontendPorts $fp01 -HttpListeners $listener, $portalListener -RequestRoutingRules $rule01, $rule02 -Sku $sku -WebApplicationFirewallConfig $config -SslCertificates $cert, $certPortal -AuthenticationCertificates $authcert -Probes $apimprobe, $apimPortalProbe
Get-AzPublicIpAddress -ResourceGroupName $resGroupName -Name "publicIP01" > "./publicip.txt"