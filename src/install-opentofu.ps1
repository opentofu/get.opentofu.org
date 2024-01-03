<#
.SYNOPSIS
Install OpenTofu.
.DESCRIPTION
This script installs OpenTofu via any of the supported methods. Please run it with the -h or -help parameter
to get a detailed help description.
.LINK
https://opentofu.org
.LINK
https://opentofu.org/docs/intro/install/
.PARAMETER help
Show a more detailed help.
.PARAMETER installMethod
The installation method to use. Must be one of:
- winget
- portable
.PARAMETER installPath
Installs OpenTofu to the specified path. (Portable installation only.)
.PARAMETER opentofuVersion
Installs the specified OpenTofu version. (Portable installation only.)
.PARAMETER cosignPath
Path to cosign. (Portable installation only.)
.PARAMETER cosignOidcIssuer
OIDC issuer for cosign signatures. (Portable installation only.)
.PARAMETER cosignIdentity
Identity for the cosign signature. (Portable installation only.)
.PARAMETER skipVerify
Skip cosign integrity verification. (Portable installation only; not recommended.)
.Parameter skipChangePath
Skip changing the user/system PATH variable to include OpenTofu.
.Parameter allUsers
Install for all users with elevated privileges.
.Parameter internalContinue
Internal parameter to use for continuing with elevated privileges. Do not use.
.Parameter internalZipFile
Internal parameter to use for continuing with elevated privileges. Do not use.
.EXAMPLE
PS> .\install-opentofu.ps1 -installMethod portable
#>
param(
    [Parameter(Mandatory = $false)]
    [switch]$help = $false,
    [Parameter(Mandatory = $false)]
    [string]$installPath = "",
    [Parameter(Mandatory = $false)]
    [string]$opentofuVersion = "latest",
    [Parameter(Mandatory = $false)]
    [string]$installMethod,
    [Parameter(Mandatory = $false)]
    [string]$cosignPath = "cosign.exe",
    [Parameter(Mandatory = $false)]
    [string]$cosignOidcIssuer = "https://token.actions.githubusercontent.com",
    [Parameter(Mandatory = $false)]
    [string]$cosignIdentity = "autodetect",
    [Parameter(Mandatory = $false)]
    [switch]$skipVerify = $false,
    [Parameter(Mandatory = $false)]
    [string]$wingetPath = "winget.exe",
    [Parameter(Mandatory = $false)]
    [switch]$skipChangePath = $false,
    [Parameter(Mandatory = $false)]
    [switch]$allUsers = $false,
    [Parameter(Mandatory = $false)]
    [switch]$internalContinue = $false,
    [Parameter(Mandatory = $false)]
    [string]$internalZipFile = ""
)

$scriptCommand = $MyInvocation.MyCommand.Source
$scriptName = $myInvocation.InvocationName
$ErrorActionPreference = 'silentlyContinue'
$ProgressPreference = 'silentlyContinue'

$esc = [char]27
$bold = "$esc[1m"
$orange = "$esc[33m"
$red = "$esc[31m"
$blue = "$esc[34m"
$normal = "$esc[0m"
$magenta = "$esc[35m"

$defaultOpenTofuVersion = "latest"
if ($allUsers) {
    $defaultInstallPath = Join-Path $Env:Programfiles "OpenTofu"
} else {
    $defaultInstallPath = Join-Path (Join-Path $Env:LOCALAPPDATA "Programs") "OpenTofu"
}
$defaultCosignPath = "cosign.exe"
$defaultCosignOidcIssuer = "https://token.actions.githubusercontent.com"
$defaultCosignIdentity = "autodetect"

$defaultWingetPath = "winget.exe"

if (!$opentofuVersion) {
    $opentofuVersion = "latest"
}
if (!$installPath) {
    $installPath = $defaultInstallPath
}
if (!$cosignPath) {
    $cosignPath = $defaultCosignPath
}
if (!$cosignOidcIssuer) {
    $cosignOidcIssuer = $defaultCosignOidcIssuer
}
if (!$cosignIdentity) {
    $cosignIdentity = $defaultCosignIdentity
}

$exitCodeOK = 0
$exitCodeInstallMethodNotSupported = 1
$exitCodeInstallFailed = 3
$exitCodeInvalidArgument = 4

class ExitCodeException : System.Exception {
    [int]  $ExitCode
    [bool] $PrintUsage
    ExitCodeException([string] $message, [int] $exitCode) : base($message) {
        $this.ExitCode = $exitCode
        $this.PrintUsage = $false
    }
    ExitCodeException([string] $message, [int] $exitCode, [bool] $printUsage) : base($message) {
        $this.ExitCode = $exitCode
        $this.PrintUsage = $printUsage
    }
}

class InvalidArgumentException : ExitCodeException {
    InvalidArgumentException([string] $message) : base($message, $exitCodeInvalidArgument, $true) {

    }
}

class InstallMethodNotSupportedException : ExitCodeException {
    InstallMethodNotSupportedException([string] $message) : base($message, $exitCodeInvalidArgument, $false) {

    }
}

class InstallFailedException : ExitCodeException {
    InstallFailedException([string] $message) : base($message, $exitCodeInstallFailed, $false) {
    }
}

function logInfo() {
    param(
        $message
    )
    Write-Output "${blue}${message}${normal}"
}

function logWarning() {
    param(
        $message
    )
    Write-Output "${orange}${message}${normal}"
}

function installWinget() {
    logInfo "Attempting winget installation..."

    $wingetError = "Winget is not installed but required for the winget installation. Please install Winget, provide the path to winget.exe in the -wingetPath parameter, or select a different installation method. See https://learn.microsoft.com/en-us/windows/package-manager/winget/ for details about winget."
    try {
        $ErrorActionPreference = 'stop'
        if(!(Get-Command )){
            throw [InstallMethodNotSupportedException]::new($wingetError)
        }
    } catch {
        throw [InstallMethodNotSupportedException]::new($wingetError)
    }
    throw [InstallMethodNotSupportedException]::new("Winget installation is not currently supported.")
}

function tempdir() {
    $tempPath = [System.IO.Path]::GetTempPath()
    $randomName = [System.IO.Path]::GetRandomFileName()
    $path = Join-Path $tempPath $randomName
    New-Item -Path $path -ItemType directory
}

function unpackPortable() {
    logInfo "Unpacking ZIP file to $installPath..."
    try
    {
        New-Item -Path $installPath -ItemType directory -Force
    }
    catch
    {
        $msg = $_.ToString()
        throw [InstallFailedException]::new("Failed to create target directory at ${installPath}. (${msg})")
    }
    $prevProgressPreference = $global:ProgressPreference
    $global:ProgressPreference = 'SilentlyContinue'
    try
    {
        logInfo "Unzipping $internalZipFile to $installPath..."
        Expand-Archive -LiteralPath $internalZipFile -DestinationPath $installPath -Force
    }
    catch
    {
        $msg = $_.ToString()
        throw [InstallFailedException]::new("Failed to unzip to ${installPath}. (${msg})")
    }
    finally
    {
        $global:ProgressPreference = $prevProgressPreference
    }
}

function installPortable() {
    if ($internalContinue) {
        logInfo "Continuing portable installation..."
        unpackPortable
        return
    }

    logInfo "Performing portable installation to ${installPath}..."

    if (!$skipVerify) {
        logInfo("Checking if cosign is available...")
        $cosignError = "Cosign is not installed but required for the portable installation. Please install cosign / provide the cosign path with the -cosignPath parameter, disable integrity verification with -skipVerify (not recommended), or select a different installation method."
        try {
            $ErrorActionPreference = 'stop'
            if(!(Get-Command $cosignPath)){
                throw [InstallMethodNotSupportedException]::new($cosignError)
            }
        } catch {
            throw [InstallMethodNotSupportedException]::new($cosignError)
        }
    } else {
        logWarning "Signature verification is disabled. This is not recommended."
    }

    if ($opentofuVersion -eq "latest") {
        $body = ""
        try
        {
            logInfo "Determining latest OpenTofu version..."
            $headers = @{ }
            if ($Env:GITHUB_TOKEN)
            {
                logInfo "Using provided GITHUB_TOKEN to prevent rate limiting..."
                $headers["Authorization"] = "token ${Env:GITHUB_TOKEN}"
            }
            $body = Invoke-WebRequest -uri "https://api.github.com/repos/opentofu/opentofu/releases/latest" -headers $headers
            $releaseData = $body | ConvertFrom-Json
        } catch {
            $msg = $_.ToString()
            throw [InstallFailedException]::new("Failed to download release information from GitHub. This may be due to GitHub rate limiting, which you can work around by providing a GITHUB_TOKEN environment variable or by providing a specific OpenTofu version to install using the -opentofuVersion parameter. (Error: ${msg}; Response body: " + $body + ")")
        }
        if (!$releaseData.name)
        {
            throw [InstallFailedException]::new("Failed to download release information from GitHub. This may be due to GitHub rate limiting, which you can work around by providing a GITHUB_TOKEN environment variable or by providing a specific OpenTofu version to install using the -opentofuVersion parameter. There seems to be no 'name' field in response, which indicates that GitHub sent us an unexpected response. The full response body was: " + $body)
        }
        $opentofuVersion = $releaseData.name.Substring(1)
        logInfo "Latest OpenTofu version is ${opentofuVersion}."
    }

    logInfo "Downloading OpenTofu version ${opentofuVersion}..."

    $tempPath = tempdir
    if ((Get-CimInstance Win32_operatingsystem).OSArchitecture -eq "64-bit") {
        $arch = "amd64"
    } else {
        $arch = "386"
    }

    $zipName = "tofu_${opentofuVersion}_windows_${arch}.zip"
    $sigFile = "tofu_${opentofuVersion}_SHA256SUMS.sig"
    $certFile = "tofu_${opentofuVersion}_SHA256SUMS.pem"
    $sumsFile = "tofu_${opentofuVersion}_SHA256SUMS"

    $urlPrefix = "https://github.com/opentofu/opentofu/releases/download/v${opentofuVersion}/"

    $dlFiles = @()
    $dlFiles += $zipName
    $dlFiles += $sumsFile
    if (!$skipVerify)
    {
        $dlFiles += $sigFile
        $dlFiles += $certFile
    }

    try {
        logInfo "Downloading $($dlFiles.Length) files..."
        for ($i = 0; $i -lt $dlFiles.Length; $i++) {
            try
            {
                $target = Join-Path $tempPath $dlFiles[$i]
                $uri = $urlPrefix + $dlFiles[$i]
                logInfo "Downloading ${uri} to ${target} ..."
                Invoke-WebRequest -outfile "${target}" -uri "${uri}"
            } catch {
                $msg = $_.ToString()
                throw [InstallFailedException]::new("Failed to download OpenTofu release ${opentofuVersion}. (${msg})")
            }
            logInfo "Download of ${target} complete."
        }

        logInfo "Verifying checksum..."
        $expectedHash = $((Get-Content (Join-Path $tempPath $sumsFile) | Select-String -Pattern $zipName) -split '\s+')[0]
        $realHash = $(Get-FileHash -Algorithm SHA256 (Join-Path $tempPath $zipName)).Hash
        if ($realHash -ne $expectedHash) {
            logWarning "Checksums don't match"
            throw [InstallFailedException]::new("Checksum mismatch, expected: ${expectedHash}, got: ${realHash}")
        }
        logInfo "Checksums match."

        if (!$skipVerify)
        {
            try
            {
                logInfo "Verifying signature..."
                & $cosignPath verify-blob --certificate-identity $cosignIdentity --signature "${tempPath}/${sigFile}" --certificate "${tempPath}/${certFile}" --certificate-oidc-issuer $cosignOidcIssuer "${tempPath}/${sumsFile}"
            } catch {
                $msg = $_.ToString()
                throw [InstallFailedException]::new("Failed to verify ${opentofuVersion} with cosign. (${msg})")
            }
        }

        $internalZipFile = Join-Path $tempPath $zipName

        if ($allUsers -and (!
            (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
        )
        {
            logInfo "Unpacking with elevated privileges..."
            $logDir = tempdir
            # TODO logging redirect
            $argList = @("-NonInteractive", "-File", ($scriptCommand | escapePathArgument), "-internalContinue", "-installMethod", "portable", "-installPath", ($installPath | escapePathArgument), "-internalZipFile", ($internalZipFile | escapePathArgument))
            $subprocess = Start-Process `
                -Verb RunAs `
                -WorkingDirectory (Get-Location) `
                -Wait `
                -Passthru `
                -FilePath 'powershell' `
                -ArgumentList $argList
            $subprocess.WaitForExit()
            if ($subprocess.ExitCode -ne 0) {
                throw [InstallFailedException]::new("Unpack failed. (Exit code ${subprocess.ExitCode})")
            }
        }
        else
        {
            logInfo "Unpacking with current privileges..."
            unpackPortable
        }
        logInfo "Unpacking complete"
    } finally {
        for ($i = 0; $i -le $dlFiles.Length; $i++) {
            $target = Join-Path $tempPath $dlFiles[$i]
            try
            {
                Remove-Item -force -recurse $target
            } catch {}
        }
    }
}

function escapePathArgument() {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $path
    )

    if ($path -contains '"') {
        throw [InvalidArgumentException]::new("Invalid path: ${path}")
    }

    return "`"${path}`""
}

function usage() {
    $usageText = @"
${bold}Usage:${normal} ${scriptName} ${magenta}[OPTIONS]${normal}

${bold}${blue}OPTIONS for all installation methods:${normal}

  ${bold}-help${normal}                         Print this help.
  ${bold}-installMethod ${magenta}METHOD${normal}         The installation method to use. (${red}required${normal})
                                Must be one of:
                                    ${magenta}portable${normal}  Portable installation
                                    ${magenta}winget${normal}    Winget installation
  ${bold}-allUsers${normal}                     Install for all users with elevated privileges.
  ${bold}-skipChangePath${normal}               Skip changing the user/system path to include the OpenTofu path.
  ${bold}-skipVerify${normal}                   Skip cosign integrity verification.
                                (${bold}${red}not recommended${normal}).
  ${bold}-debug${normal}                        Enable debug logging.

${bold}${blue}OPTIONS for the portable installation:${normal}

  ${bold}-opentofuVersion ${magenta}VERSION${normal}      Installs the specified OpenTofu version.
                                (${bold}Default:${normal} ${magenta}${defaultOpenTofuVersion}${normal})
  ${bold}-installPath ${magenta}PATH${normal}             Installs OpenTofu to the specified path.
                                (${bold}Default:${normal} ${magenta}${defaultInstallPath}${normal})
  ${bold}-cosignPath ${magenta}PATH${normal}              Path to cosign. (${bold}Default:${normal} ${magenta}${defaultCosignPath}${normal})
  ${bold}-cosignOidcIssuer ${magenta}ISSUER${normal}      OIDC issuer for cosign verification.
                                (${bold}Default:${normal} ${magenta}${defaultCosignOidcIssuer}${normal})
  ${bold}-cosignIdentity ${magenta}IDENTITY${normal}      Cosign certificate identity.
                                (${bold}Default:${normal} ${magenta}${defaultCosignIdentity}${normal})

  ${bold}API rate limits:${normal} If you do not specify the OpenTofu version, the script calls the
  GitHub API. This API is rate-limited. If you encounter problems, please create a GitHub
  token at https://github.com/settings/tokens without any permissions and set the
  ${bold}GITHUB_TOKEN${normal} environment variable to increase the rate limit:

      ${bold}`$Env:GITHUB_TOKEN = "gha_..."${normal}

  ${bold}Signature verification:${normal} This installation method uses cosign to verify the integrity
  of the downloaded binaries by default. Please install cosign or disable signature
  verification by specifying -skipVerify to disable it (not recommended).
  See https://docs.sigstore.dev/system_config/installation/ for details.

${bold}${blue}OPTIONS for the winget installation:${normal}

    ${bold}-wingetPath ${magenta}PATH${normal}              Path to winget. (${bold}Default:${normal} ${magenta}${defaultWingetPath}${normal})

  ${bold}Note:${normal} You must install winget in order to use this installation method.
  See https://learn.microsoft.com/en-us/windows/package-manager/winget/ for details.

  ${bold}Note:${normal} The winget installation method is maintained by the OpenTofu community.
  Bugfixes are provided on a best-effort basis.

${bold}${blue}Exit codes:${normal}

  ${bold}${exitCodeOK}${normal}                             Installation successful.
  ${bold}${exitCodeInstallMethodNotSupported}${normal}                             The selected installation method is not supported
                                on your system. You may be missing the required tools.
  ${bold}${exitCodeInstallFailed}${normal}                             The installation failed.
  ${bold}${exitCodeInvalidArgument}${normal}                             Invalid configuration options.

"@
    Write-Host $usageText
}

Write-Host "${blue}${bold}OpenTofu Installer${normal}"
Write-Host ""
if ($help) {
    usage
    exit $exitCodeOK
}
try
{
    Switch ($installMethod)
    {
        "" {
            throw [InvalidArgumentException]::new("Please select an installation method by specifying the -installMethod parameter.")
        }
        "winget" {
            installWinget
        }
        "portable" {
            installPortable
        }
        default {
            throw [InvalidArgumentException]::new("Invalid value for -installMethod: ${installMethod}")
        }
    }
} catch [ExitCodeException] {
    [Console]::Error.WriteLine($red + $_.ToString() + ${normal})
    if ($_.Exception.PrintUsage) {
        Write-Output ""
        usage
    }
    exit $_.Exception.ExitCode
} catch {
    [Console]::Error.WriteLine($red + $_.ToString() + ${normal})
}
