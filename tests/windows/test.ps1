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
    [Parameter(Mandatory = $false)]
    [ValidateSet('auto','winget','portable')]
    [string]$method = "auto",
    [Parameter(Mandatory = $false)]
    [bool]$sandbox = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

try {
    $wsbFile = "$( $env:Temp )\${method}.wsb"

    if ($sandbox) {
        $dir = (Get-Item (Get-Location)).Parent.Parent.FullName
        $wsb = @"
<Configuration>
    <VGpu>Disable</VGpu>
    <AudioInput>Disable</AudioInput>
    <VideoInput>Disable</VideoInput>
    <PrinterRedirection>Disable</PrinterRedirection>
    <ClipboardRedirection>Disable</ClipboardRedirection>
    <MappedFolders>
        <MappedFolder>
            <HostFolder>${dir}</HostFolder>
            <SandboxFolder>C:\opentofu-installer</SandboxFolder>
            <ReadOnly>true</ReadOnly>
        </MappedFolder>
    </MappedFolders>
    <LogonCommand>
        <Command>powershell.exe -ExecutionPolicy Bypass -Command "C:\opentofu-installer\tests\windows\in-sandbox\run-test.ps1 -method ${method} -setup"</Command>
    </LogonCommand>
</Configuration>
"@
        Write-Output $wsb
        $wsb | Out-File $wsbFile -Force:$true
        & "${Env:WinDir}\system32\WindowsSandbox.exe" $wsbFile
    } else {
        .\in-sandbox\run-test.ps1
    }
} finally {
    try
    {
        Remove-Item -force $wsbFile
    } catch {}
}
