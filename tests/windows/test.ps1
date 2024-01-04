<#
.SYNOPSIS
Test the OpenTofu Installer.
.DESCRIPTION
Run a single test on the OpenTofu installer.
.PARAMETER method
The installation method to test.
.PARAMETER sandbox
Use the Windows Sandbox to run this test
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('standalone')]
    [string]$method
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

try {
    & ".\in-sandbox\run-test.ps1" -method $method
} finally {
    try
    {
        Remove-Item -force $wsbFile
    } catch {}
}
