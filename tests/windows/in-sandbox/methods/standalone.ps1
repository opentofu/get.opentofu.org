Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

if (!(Get-Command 'cosign.exe'))
{
    if (!(Test-Path 'bin/cosign.exe'))
    {
        New-Item -Path bin -ItemType directory -Force
        $headers = @{ }
        if ($Env:GITHUB_TOKEN)
        {
            $headers["authorization"] = "token ${Env:GITHUB_TOKEN}"
        }
        $releaseData = Invoke-WebRequest -uri "https://api.github.com/repos/sigstore/cosign/releases/latest" -headers $headers | ConvertFrom-Json
        if (!$releaseData.name)
        {
            throw "Failed to download release information from GitHub, no 'name' field in response."
        }
        $cosignVersion = $releaseData.name.Substring(1)
        Invoke-WebRequest -OutFile "bin\cosign.exe" -uri "https://github.com/sigstore/cosign/releases/download/v${cosignVersion}/cosign-windows-amd64.exe"
    }
    $Env:PATH = "${Env:PATH};$( (Get-Item .).FullName )\bin"
}