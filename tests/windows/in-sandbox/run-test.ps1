<#
.SYNOPSIS
Run a single test on the OpenTofu installer
.DESCRIPTION
.PARAMETER method
The installation method to test.
.PARAMETER setup
Perform setup for the installation method.
#>
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('auto','winget','portable')]
    [string]$method = "auto",
    [Parameter(Mandatory = $false)]
    [bool]$setup = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

if ($setup) {
    & ". .\methods\${method}.ps1"
}

..\..\src\install-opentofu.ps1 -installMethod "${method}"

tofu --version
