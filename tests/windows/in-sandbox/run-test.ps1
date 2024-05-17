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
    [Parameter(Mandatory = $true)]
    [ValidateSet('standalone')]
    [string]$method
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

& ".\in-sandbox\methods\${method}.ps1"

& '..\..\static\install-opentofu.ps1' -installMethod "${method}"

tofu --version
