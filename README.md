This ARM template deploys:
<ul>
<li>VNet with WAF Subnet and App Service delegated subnet and Service Endpoint to SQL DB, AKV
<li>App Service Plan (Standard, not isolated SKU)
<li>Web App with the new VNet Integration: https://blogs.msdn.microsoft.com/appserviceteam/2018/10/17/new-app-service-vnet-integration-feature/
<li>Code for the Web App. https://github.com/azuregomez/PersonDemo
<li>SQL Azure DB with firewall configuration to allow App Service delegated Subnet. (Allow All Azure IPs is setup temporarily so the sample DB can be deployed)
<li>App Gateway with Web Application Firewall in front of the Web Application
<li>Web App IP restrictions to allow trafffic from App Gateway only
<li>Managed Service Identity for Web Application
<li>Azure Key Vault with SQL DB Connection string as secret
<li>Allow access to KV secrets from Web App with MSI
<li>Web App Portal configuration for Connection String using Key Vault Reference in the format: @Microsoft.KeyVault(SecretUri=https://{resourceprefix}-keyvault.vault.azure.net/secrets/dbcnstr). 
</ul>
Release Notes:
<ul>
<li>The template as well as the powershell script follow an easy convention where all resources have the same prefix. The prefix is specified in the template parameters and all other parameters have a default derived from resourceprefix.  The powershell script assumes this convention is followed.
<li>The script azuredeploy.ps1 includes 3 additional steps: <br>a) Remove a temporary SQL firewall rule  <br>b) Allow the Web App MSI to Get KV secrets.<br> c) Add the secret version in CnString AKV Reference. AKV references will not require version when the feature is released as Generally Available.
<li>For the most restrictive security, Azure Key Vault could have VNet restrictions enabled and allow only requests from the Web App delegated Subnet.  However, Key Vault References do not work with the new VNet Integration - the Key Vault would get the request from one of the default Outbound public IPs of App Service.  
</ul>
Deployment Instructions:
<ol>
<li>Clone this repo
<li>Update the parameter file with your Resource Prefix and your AAD Object ID.  This is required so the template can add you as a Key Vault authorized principal. You can get your AAD Object id with the Powershell cmdlet Get-AzureRmADUser
<li>Run azuredeploy.ps1
<li>Browse to the AppGateway IP or DNS name. The Web App will not respond on azurewebsites.net because the WAF is in front.
</ol>
Application Architecture:
<br/><br/>
<img src="https://storagegomez.blob.core.windows.net/public/images/vnetint2.png">
