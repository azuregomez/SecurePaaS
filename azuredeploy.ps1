Param(
    [string] [parameter(Mandatory=$true)] $ResourceGroupLocation,     
    [string] $ParameterFile = 'azuredeploy.parameters.json'
)
$params = get-content $templateparamfile | ConvertFrom-Json
$prefix = $params.parameters.resourcenameprefix.value
$rgname = $prefix + "-rg"
# Create the resource group only when it doesn't already exist
if ($null -eq (Get-AzResourceGroup -Name $rgname -Location $location -Verbose -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $rgname -Location $location -Verbose -Force -ErrorAction Stop
}
$ErrorActionPreference = 'Stop'
$templateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, 'azuredeploy.json'))
$templateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $ParameterFile))
New-AzResourceGroupDeployment -ResourceGroupName $rgname -TemplateFile $templateFile -TemplateParameterFile $templateParametersFile 
write-host "ARM Deployment Complete"