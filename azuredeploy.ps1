# .\azuredeploy.ps1 -Location "East US" -Parameterfile azuredeploy.parameters.local.json    
Param(
    [string] [parameter(Mandatory=$true)] $Location,     
    [string] $TemplateFile = 'azuredeploy.json',
    [string] $ParameterFile = 'azuredeploy.parameters.json'
)
$templateFilePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
$templateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $ParameterFile))
$params = get-content $templateParametersFile | ConvertFrom-Json
$prefix = $params.parameters.projectname.value
$rgname = $prefix + "-rg"
# Create the resource group only when it doesn't already exist
if ($null -eq (Get-AzResourceGroup -Name $rgname -Location $Location -Verbose -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $rgname -Location $Location -Verbose -Force -ErrorAction Stop
}
$ErrorActionPreference = 'Stop'
New-AzResourceGroupDeployment -ResourceGroupName $rgname -TemplateFile $templateFilePath -TemplateParameterFile $templateParametersFile 
write-host "ARM Deployment Complete"