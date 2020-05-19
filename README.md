<h2>Secure PaaS in Azure</h2>
With the General Availability of Private Link, the template will be updated to leverage Private Link for App Service, SQL Azure DB and Azure Key Vault. But that will happen when Private Link is GA for App Service.
<h3>Business Case</h3>
Azure PaaS Services like App Service, SQL Database and Storage Accounts expose a public endpoint that may be perceived as a security risk.
We want to "lock down" PaaS Services with network security so that the services are only available within private IP spaces.<br>
Application secrets such as database and storage credentials should not be in app configuration files where they can end up in source control and are visible in plain text.  
<h3>Solution</h3>
For App Service, the most secure option is the Isolated SKU, AKA App Service Environment. An App Service Environment injects all the App Service infrastructure in your VNet:<br/>
https://docs.microsoft.com/en-us/azure/app-service/environment/intro<br/>
However, the ASE comes with a considerable cost and should be considered only in cases where there is a requirement for outbound traffic inspection and the ASE is reused to deploy multiple applications as an Enterprise Architecture strategy.<br/>
It is possible to replicate most of the ASE behavior and isolate App Service endpoints:
<ul>
<li>Inbound: Place App Service behind a Web Application Firewall so that the application will not take any trafffic that does not come from the WAF.  This is accomplished by:
    <ul> 
    <li>Service Endpoint to App Service in the WAF Subnet.  Service Endpoints operate as a routing shortcut to the Service that is enabled for. But not to a specific instance of the service. In this case, The WAF Subnet has Service Endpoint to App Service so it will have a shortcut to the service.<br>https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview
    <li>App Service Access Restrictions.  The App Service instance is configured to allow inbound traffic exclusively from the private IP space of the WAF.<br>
    https://docs.microsoft.com/en-us/azure/app-service/app-service-ip-restrictions
    </ul>
<li>Outbound: Leverage Regional VNet Integration. This way the Application will use an IP from a private subnet to reach out to other PaaS Services such as SQL Database, Key Vault and Storage.  This private IP will also be used for traffic going from the App Service instance to other infrastructure in the VNet, peered VNets and on-premise.  Regional VNet integration requires a dedicated, delegated subnet that will be used exclusively by App Service.<br>
https://docs.microsoft.com/en-us/azure/app-service/web-sites-integrate-with-vnet
</ul>
For other PaaS Services, the most secure solution is Private Link:<br/>
https://docs.microsoft.com/en-us/azure/private-link/private-link-overview<br>
However, Private Link is still in preview (as of November 2019) so we have to consider other options.
It is possible to lock down inbound traffic to a PaaS Service and isolate the endpoints by:
<ul>
<li>Creating a Service Endpoint to the PaaS Service from the subnet that will access the service.  In this case, it will be the Delegated Subnet that has App Service Regional VNet Integration.
<li>Leverage network restrictions (firewall rules) in the service. Storage, Key Vault and SQL DB support this functionality and combined with Service endpoints will allow traffic exclusively from a cinfigured subnet - in this case, the App Service delegated subnet.
</ul>
For application secrets the solution leverages Azure Key Vault and Managed Service Identity for App Service.<br/>
https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview<br>
This way AKV only allows access to secrets from the identity that is system assigned to the application.<br>
The solution also leverages AKV references to avoid code changes to access secrets:<br>
https://docs.microsoft.com/en-us/azure/app-service/app-service-key-vault-references
<h4>Solution Architecture:</h4>
<br/><br/>
<img src="https://storagegomez.blob.core.windows.net/public/images/securepaas-rvi.png">
<br>
<h4>Solution Limitations</h4>
<ul>
<li>The App Service delegated subnet cannot have a Route Table. No UDR means no outbound traffic inspection through a firewall. 
<li>Regional VNet integration leverages the delegated subnet for outbound to the VNet, peered VNets, on-prem and other PaaS Services. It does not use the delegated subnet for outbound traffic to the internet.
<li>
</ul>
<h4>This solution deploys:</h4>
<ul>
<li>VNet with 2 subnets
<ol>
    <li>WAF Subnet 
    <li>App Service Delegated Subnet with Service Endpoint to SQL DB, AKV
</ol>
<li>App Service Plan (Standard, not isolated SKU, no ASE)
<li>Web App with Regional VNet Integration.
<li>Sample Code for the Web App. https://github.com/azuregomez/PersonDemo
<li>SQL Azure DB with firewall configuration to allow App Service delegated Subnet. (Allow All Azure IPs is setup temporarily so the sample DB can be deployed)
<li>App Gateway with Web Application Firewall and Service Endpoints to Microsoft.Web. The Web Application in the Backend Pool.
<li>Web App IP restrictions to allow trafffic from App Gateway only (from the App Gateway Subnet exclusively)
<li>Managed Service Identity for Web Application
<li>Azure Key Vault with SQL DB Connection string as secret
<li>Allow access to KV secrets from Web App with MSI
<li>Web App Portal configuration for Connection String using Key Vault Reference in the format: @Microsoft.KeyVault(SecretUri=https://{resourceprefix}-keyvault.vault.azure.net/secrets/dbcnstr). 

</ul>
<h4>Release Notes:</h4>
<ul>
<li>Pre-req: Azure Subscription with Contributor role, Powershell 5.1 and Az Cmdlets. <br>
Install-Module -Name Az -AllowClobber -Scope AllUsers
<li>Regional VNet integration is also in preview, but it is supported for prod deployments<br>
<li>App Gateway is deployed with a Public IP. This means the App Service is accessible from the internet through App Gateway.
<li>The template as well as the powershell script follow an easy convention where all resources have the same prefix. The prefix is specified in the template parameters and all other parameters have a default derived from resourceprefix.  The powershell script assumes this convention is followed.
<li>The script azuredeploy.ps1 includes 3 additional steps: <br>a) Remove a temporary SQL firewall rule  <br>b) Allow the Web App MSI to Get KV secrets.<br> c) Add the secret version in CnString AKV Reference. AKV references require secret version.
<li>For the most restrictive security, Azure Key Vault could have VNet restrictions enabled and allow only requests from the Web App delegated Subnet.  However, Key Vault References do not work with Regional VNet Integration - the Key Vault would get the request from one of the default Outbound public IPs of App Service.  
<li>This architecture virtually injects an App Service into a VNet by allowing trafffic exclusively from App Gateway and using a delegated subnet for Outbound access to SQL Azure DB, Storage and potentially to on-prem locations. 
<li>Application Deployment is not restricted. The SCM side of app service does not have IP Restrictions in the template. Since you can restrict traffic to the app separately from the scm site, you can take advantage of that and set service endpoints from another subnet with a jump box or separate App Gateway. (Driving traffic and publishing through the same App Gateway endpoint may be a security flaw)
<li>The sample app is deployed in the ARM template using the web deploy website extension. This is because App Service does not have the latest version of MSBuild and deployment straight from the repo would not build.
</ul>
<h4>Deployment Instructions:</h4>
<ol>
<li>Clone this repo
<li>Update the parameter file with your Resource Prefix and your AAD Object ID.  This is required so the template can add you as a Key Vault authorized principal. You can get your AAD Object id with the Powershell cmdlet Get-AzureRmADUser
<li>Run azuredeploy.ps1
<li>Browse to the AppGateway IP or DNS name. The Web App will not respond on azurewebsites.net because the WAF is in front.
</ol>
<h3>What if I want the application to be ONLY available from my corporate Network?</h3>
The following changes would be required:
<ol>
<li>App Gateway needs to be deployed with an internal IP, not external
<li>Hybrid connectivity: VPN or VNet Gateway (ExpressRoute)
</ol>
App Service would have the following architecture:
<img src="https://storagegomez.blob.core.windows.net/public/images/injectapp.png">
