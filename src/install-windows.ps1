param(
    [Parameter(Mandatory = $false)]
    [switch]$help,
    [Parameter(Mandatory = $false)]
    [string]$installPath,
    [Parameter(Mandatory = $false)]
    [string]$opentofuVersion,
    [Parameter(Mandatory = $false)]
    [string]$installMethod,
    [Parameter(Mandatory = $false)]
    [switch]$skipVerify
)

$scriptName = $myInvocation.InvocationName

$esc = [char]27
$bold = "$esc[1m"
$red = "$esc[31m"
$blue = "$esc[34m"
$normal = "$esc[0m"
$magenta = "$esc[35m"

$defaultOpenTofuVersion = "latest"
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  $defaultInstallPath = Join-Path $Env:Programfiles "OpenTofu"
} else {
  $defaultInstallPath = Join-Path (Join-Path $Env:LOCALAPPDATA "Programs") "OpenTofu"
}
$defaultCosignPath = "cosign.exe"
$defaultCosignOidcIssuer = "https://token.actions.githubusercontent.com"
$defaultCosignIdentity = "autodetect"

if (!$opentofuVersion) {
    $opentofuVersion = "latest"
}
if (!$installPath) {
    $installPath = $defaultInstallPath
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

function installWinget() {
    Write-Debug "Attempting winget installation..."
    throw [InstallMethodNotSupportedException]::new("Winget installation is not available.")
}

function tempdir() {
    $tempPath = [System.IO.Path]::GetTempPath()
    $randomName = [System.IO.Path]::GetRandomFileName()
    $path = Join-Path $tempPath $randomName
    New-Item -Path $path -ItemType directory
}

function installPortable() {
    Write-Debug "Attempting portable installation..."

    if ($opentofuVersion -eq "latest") {
        try
        {
            Write-Debug "Determining latest OpenTofu version..."
            $headers = @{ }
            if ($Env:GITHUB_TOKEN)
            {
                $headers["Authorization"] = "token ${Env:GITHUB_TOKEN}"
            }
            $releaseData = Invoke-WebRequest -uri "https://api.github.com/repos/opentofu/opentofu/releases/latest" -headers $headers | ConvertFrom-Json
            if (!$releaseData.name)
            {
                throw [InstallFailedException]::new("Failed to download release information from GitHub, no 'name' field in response.")
            }
            $opentofuVersion = $releaseData.name.Substring(1)
            Write-Debug "Latest OpenTofu version is ${opentofuVersion}."
        } catch {
            $msg = $_.ToString()
            throw [InstallFailedException]::new("Failed to determine latest OpenTofu version. (${msg})")
        }
    }

    $tempPath = tempdir
    try {
        if ((Get-CimInstance Win32_operatingsystem).OSArchitecture -eq "64-bit") {
            $arch = "amd64"
        } else {
            $arch = "386"
        }
        $zipName = "tofu_${opentofuVersion}_windows_${arch}.zip"
        $target = Join-Path $tempPath $zipName
        try
        {
            $uri = "https://github.com/opentofu/opentofu/releases/download/v${opentofuVersion}/${zipName}"
            Write-Debug "Downloading $uri to ${target} ..."
            Invoke-WebRequest -outfile "${target}" -uri $uri
        } catch {
            $msg = $_.ToString()
            throw [InstallFailedException]::new("Failed to download OpenTofu release ${opentofuVersion}. (${msg})")
        }
        Write-Debug "Download complete."
    } finally {
        try
        {
            Remove-Item -force -recurse $tempPath
        } catch {}
    }
}

function install() {
    $methods = @("installWinget", "installPortable")

    for ($i = 0; $i -lt $methods.Length; $i++) {
        try {
            & $methods[$i]
            return
        } catch [InstallMethodNotSupportedException] {
            $msg = $_.ToString()
            Write-Debug "${msg} Proceeding to next installation method."
        }
    }
    throw [InstallMethodNotSupportedException]::new("No suitable installation method available.")
}

function usage() {
    $usageText = @"
${bold}Usage:${normal} ${scriptName} ${magenta}[OPTIONS]${normal}

${bold}${blue}OPTIONS for all installation methods:${normal}

  ${bold}-help${normal}                         Print this help.
  ${bold}-installMethod ${magenta}METHOD${normal}         The installation method to use. Must be one of:
                                    ${magenta}auto${normal}      Automatically select installation
                                              method (${bold}default${normal})
                                    ${magenta}winget${normal}    Winget installation
                                    ${magenta}portable${normal}  Portable installation
  ${bold}-skipVerify${normal}                   Skip GPG or cosign integrity verification.
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

  ${bold}Note:${normal} If you do not specify the OpenTofu version, the script calls the GitHub API.
  This API is rate-limited. If you encounter problems, please create a GitHub token at
  https://github.com/settings/tokens without any permissions and set the ${bold}GITHUB_TOKEN${normal}
  environment variable. This will increase the rate limit.

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
        "auto" {
            install
        }
        "" {
            install
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
}
