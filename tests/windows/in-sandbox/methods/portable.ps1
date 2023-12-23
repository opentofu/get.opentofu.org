Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

mkdir bin
$headers = @{}
if ($Env:GITHUB_TOKEN) {
    $headers["authorization"] = "token ${Env:GITHUB_TOKEN}"
}
$releaseData = Invoke-WebRequest -uri "https://api.github.com/repos/sigstore/cosign/releases/latest" -headers $headers | ConvertFrom-Json
if (!$releaseData.name)
{
    throw "Failed to download release information from GitHub, no 'name' field in response."
}
$cosignVersion = $releaseData.name.Substring(1)
(New-Object System.Net.WebClient).DownloadFile("https://github.com/sigstore/cosign/releases/download/v${cosignVersion}/cosign-windows-amd64.exe", "bin\cosign.exe")

$Env:PATH = "${Env:PATH};$((Get-Item .).FullName)\bin"
