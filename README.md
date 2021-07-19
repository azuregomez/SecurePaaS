# Secure PaaS in Azure
## Why App Service and Azure SQL DB?
* Get out of the business of managing infrastructure. Just manage code and ship new features faster.
* Get built-in Cloud Native features: Monitoring, Autoscaling, High Availability, Disaster Recovery.
* App Service is the only managed app hosting platform for .net. With 2 decades of investment and 25+ years of SQL innovation.
* Proven success: hosting 2M apps and 41B daily requests with 99.95% SLA.
* Free App Service and Database Migration Assistants
* Leverage full network security and integration, with internet traffic blocked, firewalls protecting your deployment and supporting hybrid applications that integrate securely with other services in your network.
* Inject App Service into your Virtual Network without price penalty and with full control of your network security.
## Technical Requirements of the solution presented
Green field or .net application migration with a SQL Server back end the following Security features:
* No public endpoints available for Web Application or SQL Database.
* Web Application Firewall in front of Web Application to protect against the top 10 OWASP threats
* Outbound traffic from the Web App to SQL Database and other in-network resources (including on-premise) routed to a firewall for inspection.
* Secrets like database connection strings not available in code or application configuration.
## Architecture
![Secure PaaS](https://github.com/azuregomez/securepaas/blob/main/arcitecture.png)