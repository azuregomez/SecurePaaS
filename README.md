<h2>Secure PaaS in Azure</h2>
This ARM template deploys:
<ul>
<li>VNet with 2 subnets
<ol>
    <li>WAF Subnet 
    <li>App Service Delegated Subnet with Service Endpoint to SQL DB, AKV
</ol>
<li>App Service Plan (Standard, not isolated SKU)
<li>Web App with Regional VNet Integration: https://docs.microsoft.com/en-us/azure/app-service/web-sites-integrate-with-vnet
<li>Code for the Web App. https://github.com/azuregomez/PersonDemo
<li>SQL Azure DB with firewall configuration to allow App Service delegated Subnet. (Allow All Azure IPs is setup temporarily so the sample DB can be deployed)
<li>App Gateway with Web Application Firewall and Service Endpoints to Microsoft.Web. The Web Application in the Backend Pool.
<li>Web App IP restrictions to allow trafffic from App Gateway only (from the App Gateway Subnet exclusively)
<li>Managed Service Identity for Web Application
<li>Azure Key Vault with SQL DB Connection string as secret
<li>Allow access to KV secrets from Web App with MSI
<li>Web App Portal configuration for Connection String using Key Vault Reference in the format: @Microsoft.KeyVault(SecretUri=https://{resourceprefix}-keyvault.vault.azure.net/secrets/dbcnstr). 
https://docs.microsoft.com/en-us/azure/app-service/app-service-key-vault-references
</ul>
Release Notes:
<ul>
<li>Pre-req: Azure Subscription with Contributor role, Powershell 5.1 and Az Cmdlets. Install-Module -Name Az -AllowClobber -Scope AllUsers
<li>App Gateway is deployed with a Public IP. This means the App Service is accessible from the internet through App Gateway.
<li>The template as well as the powershell script follow an easy convention where all resources have the same prefix. The prefix is specified in the template parameters and all other parameters have a default derived from resourceprefix.  The powershell script assumes this convention is followed.
<li>The script azuredeploy.ps1 includes 3 additional steps: <br>a) Remove a temporary SQL firewall rule  <br>b) Allow the Web App MSI to Get KV secrets.<br> c) Add the secret version in CnString AKV Reference. AKV references require secret version.
<li>For the most restrictive security, Azure Key Vault could have VNet restrictions enabled and allow only requests from the Web App delegated Subnet.  However, Key Vault References do not work with the new VNet Integration - the Key Vault would get the request from one of the default Outbound public IPs of App Service.  
<li>This architecture virtually injects an App Service into a VNet by allowing trafffic exclusively from App Gateway and using a delegated subnet for Outbound access to SQL Azure DB, Storage and potentially to on-prem locations. 
<li>This solution does NOT provide a dedicated outbound address to the internet. It still uses 4 defined and shared IPs.
<li>Application Deployment is not restricted. The SCM side of app service does not have IP Restrictions in the template. Since you can restrict traffic to the app separately from the scm site, you can take advantage of that and set service endpoints from another subnet with a jump box or separate App Gateway. (Driving traffic and publishing through the same App Gateway endpoint may be a security flaw)
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
<img src="https://storagegomez.blob.core.windows.net/public/images/securepaas-rvi.png">
<br>
<h3>What if I want the application to be ONLY available from my corporate Network?</h3>
The following changes would be required:
<ol>
<li>App Gateway needs to be deployed with an internal IP, not external
<li>Hybrid connectivity: VPN or VNet Gateway (ExpressRoute)
</ol>
App Service would have the following architecture:
<img src="https://storagegomez.blob.core.windows.net/public/images/injectapp.png">