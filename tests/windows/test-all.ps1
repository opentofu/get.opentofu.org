<#
.SYNOPSIS
Test the OpenTofu Installer.
.DESCRIPTION
Run all tests for the OpenTofu installer.
.PARAMETER sandbox
Use the Windows Sandbox to run this tests.
#>
param(
    [Parameter(Mandatory = $false)]
    [bool]$sandbox = $true
)

$methods = @["auto", "winget", "portable"]

for ($i = 0; $i -lt $methods.Length; $i++) {
    $method = $methods[$i]
    .\test.ps1 -method "${method}"
}