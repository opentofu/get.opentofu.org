<#
Copyright (c) The OpenTofu Authors
SPDX-License-Identifier: Apache-2.0
License: https://github.com/opentofu/get.opentofu.org/blob/main/LICENSE

.SYNOPSIS
Install OpenTofu.

.DESCRIPTION
This script installs OpenTofu via any of the supported methods. Please run it with the -h or -help parameter
to get a detailed help description.

.LINK
https://opentofu.org

.LINK
https://opentofu.org/docs/intro/install/

.LINK
https://github.com/opentofu/get.opentofu.org/blob/main/LICENSE

.PARAMETER help
Show a more detailed help.

.PARAMETER installMethod
The installation method to use. Must be one of:
- standalone

.PARAMETER installPath
Installs OpenTofu to the specified path. (Standalone installation only.)

.PARAMETER opentofuVersion
Installs the specified OpenTofu version. (Standalone installation only.)

.PARAMETER cosignPath
Path to cosign. (Standalone installation only.)

.PARAMETER cosignOidcIssuer
OIDC issuer for cosign signatures. (Standalone installation only.)

.PARAMETER cosignIdentity
Identity for the cosign signature. (Standalone installation only.)

.PARAMETER gpgPath
Path for the GPG installation. (Standalone installation only.)

.PARAMETER gpgURL
URL to download the GPG key from. (Standalone installation only.)

.PARAMETER gpgKeyID
GPG key ID / fingerprint to expect. (Standalone installation only.)

.PARAMETER skipVerify
Skip cosign/GPG integrity verification. (Standalone installation only; not recommended.)

.PARAMETER skipChangePath
Skip changing the user/system PATH variable to include OpenTofu.

.PARAMETER allUsers
Install for all users with elevated privileges.

.PARAMETER internalContinue
Internal parameter to use for continuing with elevated privileges. Do not use.

.PARAMETER internalZipFile
Internal parameter to use for continuing with elevated privileges. Do not use.

.EXAMPLE
PS> .\install-opentofu.ps1 -installMethod standalone

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
    [string]$gpgPath = "gpg.exe",

    [Parameter(Mandatory = $false)]
    [string]$gpgURL = "https://get.opentofu.org/opentofu.asc",

    [Parameter(Mandatory = $false)]
    [string]$gpgKeyID = "E3E6E43D84CB852EADB0051D0C0AF313E5FD9F80",

    [Parameter(Mandatory = $false)]
    [switch]$skipVerify = $false,

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
$InformationPreference = 'continue'
$WarningPreference = 'continue'
$ErrorActionPreference = 'continue'
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
$defaultGPGPath = "gpg.exe"
$defaultGPGURL = "https://get.opentofu.org/opentofu.asc"
$defaultGPGKeyID = "E3E6E43D84CB852EADB0051D0C0AF313E5FD9F80"

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
if (!$gpgPath) {
    $gpgPath = $defaultGPGPath
}
if (!$gpgURL) {
    $gpgURL = $defaultGPGURL
}
if (!$gpgKeyID) {
    $gpgKeyID = $defaultGPGKeyID
}

$exitCodeOK = 0
$exitCodeInstallRequirementNotMet = 1
$exitCodeInstallFailed = 2
$exitCodeInvalidArgument = 3

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

class InstallRequirementNotMetException : ExitCodeException {
    InstallRequirementNotMetException([string] $message) : base($message, $exitCodeInstallRequirementNotMet, $false) {

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
    Write-Information "${blue}${message}${normal}"
}

function logWarning() {
    param(
        $message
    )
    Write-Warning "${orange}${message}${normal}"
}

function logError() {
    param(
        $message
    )
    try
    {
        [Console]::Error.WriteLine("${red}${message}${normal}")
    } catch {}
}

function tempdir() {
    $tempPath = [System.IO.Path]::GetTempPath()
    $randomName = [System.IO.Path]::GetRandomFileName()
    $path = Join-Path $tempPath $randomName
    New-Item -Path $path -ItemType directory
}

function unpackStandalone() {
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

    if ($skipChangePath) {
        return
    }
    try {
        if ($allUsers) {
            logInfo "Updating system PATH variable..."
            $target = [EnvironmentVariableTarget]::Machine
        } else {
            logInfo "Updating user PATH variable..."
            $target = [EnvironmentVariableTarget]::User
        }
        $currentPath = [Environment]::GetEnvironmentVariable("Path", $target)
        if (!($currentPath.Contains($installPath))) {
            [Environment]::SetEnvironmentVariable("Path", $currentPath + ";${installPath}", $target)
        }
    }
    catch
    {
        $msg = $_.ToString()
        throw [InstallFailedException]::new("Failed to set path. (${msg})")
    }
}

function installStandalone() {
    if ($internalContinue) {
        logInfo "Continuing standalone installation..."
        unpackStandalone
        return
    }

    logInfo "Performing standalone installation to ${installPath}..."

    if (!$skipVerify) {
        logInfo("Checking if cosign or GPG is available...")

        $cosignAvailable = $false
        try {
            $ErrorActionPreference = 'stop'
            if(Get-Command $cosignPath){
                $cosignAvailable = $true
            }
        } catch {}
        $ErrorActionPreference = 'continue'

        $gpgAvailable = $false
        try {
            $ErrorActionPreference = 'stop'
            if(Get-Command $gpgPath){
                $gpgAvailable = $true
            }
        } catch {}
        $ErrorActionPreference = 'continue'

        if ($cosignAvailable) {
            $verifyMethod = "cosign"
        } elseif ($gpgAvailable) {
            $verifyMethod = "gpg"
        } else {
            throw [InstallRequirementNotMetException]::new("${bold}Additional tools are needed for the installation. Please read the following text carefully!${normal}`n`nThis installer tries to verify that the OpenTofu version downloaded has been ${bold}signed by OpenTofu and has not been tampered with${normal}. This is only possible if either cosign or GPG is installed on the system, but neither was found. You have the following options:`n`n1. ${bold}Install cosign${normal} and add it to your ${magenta}PATH${normal} or provide the ${magenta}-cosignPath${normal} parameter to your cosign installation.`n2. ${bold}Install GPG${normal} and add it to your ${magenta}PATH${normal} or provide the ${magenta}-gpgPath${normal} parameter to your GPG installation.`n3. ${bold}Disable integrity verification${normal} with ${magenta}-skipVerify${normal} (${red}not recommended${normal}).")
        }
    } else {
        $verifyMethod = "-"
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
            throw [InstallFailedException]::new("Failed to parse release information from GitHub. This may be due to GitHub rate limiting, which you can work around by providing a GITHUB_TOKEN environment variable or by providing a specific OpenTofu version to install using the -opentofuVersion parameter. There seems to be no 'name' field in response, which indicates that GitHub sent us an unexpected response. The full response body was: " + $body)
        }
        $opentofuVersion = $releaseData.name.Substring(1)
        logInfo "Latest OpenTofu version is ${opentofuVersion}."
    }

    logInfo "Downloading OpenTofu version ${opentofuVersion}..."

    $tempPath = tempdir
    if ([Environment]::Is64BitOperatingSystem) {
        $arch = "amd64"
    } else {
        $arch = "386"
    }

    $zipName    = "tofu_${opentofuVersion}_windows_${arch}.zip"
    $zipPath    = Join-Path $tempPath $zipName
    $sigFile    = "tofu_${opentofuVersion}_SHA256SUMS.sig"
    $sigPath    = Join-Path $tempPath $sigFile
    $certFile   = "tofu_${opentofuVersion}_SHA256SUMS.pem"
    $certPath   = Join-Path $tempPath $certFile
    $gpgSigFile = "tofu_${opentofuVersion}_SHA256SUMS.gpgsig"
    $gpgSigPath = Join-Path $tempPath $gpgSigFile
    $sumsFile   = "tofu_${opentofuVersion}_SHA256SUMS"
    $sumsPath   = Join-Path $tempPath $sumsFile
    $gpgKeyPath = Join-Path $tempPath "opentofu.asc"

    $urlPrefix = "https://github.com/opentofu/opentofu/releases/download/v${opentofuVersion}/"

    $dlFiles = @()
    $dlFiles += $zipName
    $dlFiles += $sumsFile
    if (!$skipVerify)
    {
        if ($verifyMethod -eq "cosign")
        {
            $dlFiles += $sigFile
            $dlFiles += $certFile
        } elseif ($verifyMethod -eq "gpg") {
            $dlFiles += $gpgSigFile
        } elseif ($verifyMethod -ne "-") {
            throw [InstallFailedException]::new("Bug: unsupported verification method: ${verifyMethod}.")
        }
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
                throw [InstallFailedException]::new("Failed to download OpenTofu ${opentofuVersion} release file ${dlFiles[i]}. (${msg})")
            }
            logInfo "Download of ${target} complete."
        }

        if ($verifyMethod -eq "gpg")
        {
            logInfo "Fetching OpenTofu GPG key from ${gpgURL}..."
            try
            {
                Invoke-WebRequest -outfile "${gpgKeyPath}" -uri "${gpgURL}"
            }
            catch
            {
                $msg = $_.ToString()
                throw [InstallFailedException]::new("Failed to download OpenTofu GPG key from ${gpgURL}. (${msg})")
            }
            logInfo "GPG key download complete."

            logInfo "Dearmoring GPG key..."
            & $gpgPath --dearmor ${gpgKeyPath}
            if (!$?) {
                throw [InstallFailedException]::new("Failed to dearmor GPG file from ${gpgURL}.")
            }
            $gpgKeyPath = "${gpgKeyPath}.gpg"

            logInfo "Verifying GPG key fingerprint..."
            $gpgOutput = (& $gpgPath "--no-default-keyring" "--with-colons" "--show-keys" "--fingerprint" "${gpgKeyPath}" 2>&1)
            if (!$?) {
                throw [InstallFailedException]::new("Failed to parse GPG file from ${gpgURL}.")
            }
            if (!$gpgOutput.Contains("fpr:::::::::${gpgKeyID}:")) {
                throw [InstallFailedException]::new("The downloaded GPG file from ${gpgURL} does not contain a key with the fingerprint ${gpgKeyID}.")
            }
            logInfo "Verifying GPG key fingerprint verified."
        }

        logInfo "Verifying checksum..."
        $expectedHash = $((Get-Content $sumsPath | Select-String -Pattern $zipName) -split '\s+')[0]
        $realHash = $(Get-FileHash -Algorithm SHA256 $zipPath).Hash
        if ($realHash -ne $expectedHash) {
            logWarning "Checksums don't match."
            throw [InstallFailedException]::new("Checksum mismatch, expected: ${expectedHash}, got: ${realHash}")
        }
        logInfo "Checksums match."

        if ($verifyMethod -eq "cosign")
        {
            if ($cosignIdentity -eq "autodetect")
            {
                if ($opentofuVersion.Contains("-alpha") -or $opentofuVersion.Contains("-beta"))
                {
                    $cosignIdentity = "https://github.com/opentofu/opentofu/.github/workflows/release.yml@refs/heads/main"
                }
                else
                {
                    $ver = [version]($opentofuVersion -replace "-rc.*")
                    $major = $ver.Major
                    $minor = $ver.Minor
                    $cosignIdentity = "https://github.com/opentofu/opentofu/.github/workflows/release.yml@refs/heads/v${major}.${minor}"
                }
            }

            logInfo "Verifying signature against cosign identity ${cosignIdentity}..."
            logInfo "Running $cosignPath verify-blob --certificate-identity $cosignIdentity --signature $sigPath --certificate $certPath --certificate-oidc-issuer $cosignOidcIssuer $sumsPath"
            & $cosignPath verify-blob --certificate-identity $cosignIdentity --signature $sigPath --certificate $certPath --certificate-oidc-issuer $cosignOidcIssuer $sumsPath
            if ($?)
            {
                logInfo "Signature verified."
            }
            else
            {
                throw [InstallFailedException]::new("Failed to verify ${opentofuVersion} with cosign.")
            }
        } elseif ($verifyMethod -eq "gpg") {

            $env:GPGHOME = ${tempPath}

            logInfo "Importing GPG key..."
            $gpgOutput = & $gpgPath --homedir $tempPath --import $gpgKeyPath
            if (!$?) {
                throw [InstallFailedException]::new("Failed to import the GPG key for OpenTofu. (${gpgOutput})")
            }

            logInfo "Trusting GPG key..."
            $gpgOutput = & $gpgPath --homedir $tempPath --tofu-policy good $gpgKeyID
            if (!$?) {
                throw [InstallFailedException]::new("Failed to trust the GPG key for OpenTofu. Possible fingerprint mismatch? (${gpgOutput})")
            }

            logInfo "Verifying GPG signature..."
            $gpgOutput = & $gpgPath --homedir $tempPath --trust-model tofu --verify $gpgSigPath $sumsPath
            if (!$?) {
                throw [InstallFailedException]::new("Failed to verify OpenTofu ${opentofuVersion} with GPG. ($?, $LASTEXITCODE, ${gpgOutput})")
            }

            logInfo "Signature verified."
        } elseif ($verifyMethod -ne "-") {
            throw [InstallFailedException]::new("Bug: unsupported verification method: ${verifyMethod}.")
        }

        $internalZipFile = Join-Path $tempPath $zipName

        if ($allUsers -and (!
            (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
        )
        {
            # Note on this section: we are requesting elevated privileges via UAC. Unfortunately, this is only possible
            # by launching the current script again as Administrator. This can cause some weird parsing bugs in
            # conjunction with Start-Process and the "powershell" command. (The parameter separation disappears.)
            # Also note that when using Start-Process with RunAs, it is not possible to pass environment variables.
            # (The documentation is lying!)
            #
            # TL;DR: Make sure to MANUALLY test privilege elevation if you change this as we can't test UAC in CI! Make
            # sure to test with paths containing spaces too! Did I mention to test this? Test it. I'm serious.

            logInfo "Unpacking with elevated privileges..."
            $logDir = tempdir
            # TODO capture the log output of the shell running as admin and clean up afterwards.
            $argList = @("-NonInteractive", "-File", ($scriptCommand | escapePathArgument), "-internalContinue", "-allUsers", "-installMethod", "standalone", "-installPath", ($installPath | escapePathArgument), "-internalZipFile", ($internalZipFile | escapePathArgument))
            if ($skipChangePath)
            {
                $argList += "-skipChangePath"
            }
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
            unpackStandalone
        }
        logInfo "Unpacking complete."

        $tofuPath = Join-Path $installPath "tofu.exe"
        logInfo "OpenTofu is now available at ${tofuPath}."

        if (!$skipChangePath) {
            $Env:PATH = "${Env:PATH};$installPath"
        }
    } finally {
        for ($i = 0; $i -le ($dlFiles.Length - 1); $i++) {
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
    $scriptName = $scriptCommand.Split("\")[-1].split("/")[-1]
    $usageText = @"
${bold}Usage:${normal} ${scriptName} ${magenta}[OPTIONS]${normal}

${bold}${blue}OPTIONS for all installation methods:${normal}

  ${bold}-help${normal}                         Print this help.
  ${bold}-installMethod ${magenta}METHOD${normal}         The installation method to use. (${red}required${normal})
                                Must be one of:
                                    ${magenta}standalone${normal}  Standalone installation
  ${bold}-allUsers${normal}                     Install for all users with elevated privileges.
  ${bold}-skipChangePath${normal}               Skip changing the user/system path to include the OpenTofu path.
  ${bold}-skipVerify${normal}                   Skip cosign integrity verification.
                                (${bold}${red}not recommended${normal}).
  ${bold}-debug${normal}                        Enable debug logging.

${bold}${blue}OPTIONS for the standalone installation:${normal}

  ${bold}-opentofuVersion ${magenta}VERSION${normal}      Installs the specified OpenTofu version.
                                (${bold}Default:${normal} ${magenta}${defaultOpenTofuVersion}${normal})
  ${bold}-installPath ${magenta}PATH${normal}             Installs OpenTofu to the specified path.
                                (${bold}Default:${normal} ${magenta}${defaultInstallPath}${normal})
  ${bold}-gpgPath ${magenta}PATH${normal}                 Path to GPG. (${bold}Default:${normal} ${magenta}${defaultGPGPath}${normal})
  ${bold}-gpgURL ${magenta}URL${normal}                   URL of the GPG key to use (without ASCII-armor)
                                (${bold}Default:${normal} ${magenta}${defaultGPGURL}${normal})
  ${bold}-gpgKeyID ${magenta}ID${normal}                  GPG key ID to expect the gpgURL.
                                (${bold}Default:${normal} ${magenta}${defaultGPGKeyID}${normal})
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

  ${bold}Signature verification:${normal} This installation method uses cosign or GPG
  to verify the integrity of the downloaded binaries by default. Please install cosign or gpg
  or disable signature verification by specifying ${bold}-skipVerify${normal} to disable it (not recommended).
  See https://docs.sigstore.dev/system_config/installation/ for details.

${bold}${blue}Exit codes:${normal}

  ${bold}${exitCodeOK}${normal}                             Installation successful.
  ${bold}${exitCodeInstallRequirementNotMet}${normal}                             Your system is missing one or more requirements
                                for these selected installation method. Please
                                install the indicated tools to continue.
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
        "standalone" {
            installStandalone
        }
        default {
            throw [InvalidArgumentException]::new("Invalid value for -installMethod: ${installMethod}")
        }
    }
} catch [ExitCodeException] {
    logError($_.ToString())
    if ($_.Exception.PrintUsage) {
        usage
    }
    exit $_.Exception.ExitCode
} catch {
    logError($_.ToString())
    exit $exitCodeInstallFailed
}
