param(
    [Parameter(Mandatory = $false)]
    [string]$method = "auto"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

../../src/install-opentofu.ps1 -installMethod "${method}"

tofu --version
