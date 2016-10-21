#Requires -RunAsAdministrator
#Requires -Version 5

<#
.Synopsis
   Downloads ISHBootstrap from github and executes the sequence from the Examples
.DESCRIPTION
   Downloads ISHBootstrap from github and executes the sequence from the Examples
.EXAMPLE
   ISHBootstrap.ps1
.EXAMPLE
   ISHBootstrap.ps1 -Branch develop
.EXAMPLE
   ISHBootstrap.ps1 -Tag "v0.3"
.Link
    https://github.com/Sarafian/ISHBootstrap
#>
param(
    [Parameter(Mandatory=$true,ParameterSetName="Tag")]
    [string]$Tag,
    [Parameter(Mandatory=$false,ParameterSetName="Branch")]
    [string]$Branch="master",
    [Parameter(Mandatory=$false,ParameterSetName="Tag")]
    [Parameter(Mandatory=$false,ParameterSetName="Branch")]
    [switch]$NoCredentialPrompt=$false
)

#region Initialize url to download ISHBootstrap from github
$gitHubHost="github.com"
$gitHubUser="Sarafian"

switch ($PSCmdlet.ParameterSetName)
{
    'Tag' {
        $ishBootstrapReleaseUri="https://$gitHubHost/$gitHubUser/ISHBootstrap/archive/$Tag.zip"
        $downloadFileName="InfoShare-$Tag.zip"
    }
    'Branch' {
        $ishBootstrapReleaseUri="https://$gitHubHost/$gitHubUser/ISHBootstrap/archive/$Branch.zip"
        $downloadFileName="InfoShare-$Branch.zip"
    }
}
#endregion

$jsonPath="$PSScriptRoot\ISHBootstrap.json"

$ErrorActionPreference = "Stop"

$downloadActivity="ISHBootstrap initialization"

#region Download ISHBootstrap from GIT
# Download release artifact to temp folder
Write-Progress -Activity $downloadActivity -Status "Downloading ISHBootstrap ($downloadFileName)"
$ishBootstrapTempPath=Join-Path $env:TEMP $downloadFileName
if(Test-Path $ishBootstrapTempPath)
{
    Write-Warning "$ishBootstrapTempPath already exists. Removing"
    Remove-Item -Path $ishBootstrapTempPath -Force
}
Invoke-WebRequest -Uri $ishBootstrapReleaseUri -UseBasicParsing -OutFile $ishBootstrapTempPath

# Expand downloaded archive
Write-Progress -Activity $downloadActivity -Status "Expanding ISHBootstrap ($downloadFileName)"
$ishBootstrapPath=Join-Path $env:TEMP ISHBootstrap
# Remove the directory if it exists
if(Test-Path $ishBootstrapPath)
{
    Write-Warning "$ishBootstrapPath already exists. Removing"
    Remove-Item -Path $ishBootstrapPath -Recurse -Force
}
Expand-Archive -Path $ishBootstrapTempPath -DestinationPath $ishBootstrapPath
$ishBootstrapPath=Get-ChildItem -Path $ishBootstrapPath |Select-Object -ExpandProperty FullName -First 1
#endregion

#region Credential
if(-not $NoCredentialPrompt)
{
    $credentialActivity="Acquiring credentials"
    Write-Progress -Activity $credentialActivity -Status "Ask for FTP creential"
    $ftpCredential=Get-Credential -Message "Credential for FTP"
    Write-Progress -Activity $credentialActivity -Status "Ask for OSUser credential"
    $osuserCredential=Get-Credential -Message "Credential for OSUser"
    Set-Variable "ISHBootstrap.FTP" -Value $ftpCredential -Scope Global -Force
    Set-Variable "ISHBootstrap.OSUser" -Value $osuserCredential -Scope Global -Force
}
#endregion


$executionActivity="ISHBootstrap execution"
#region Invoke ISHBootstrap

Write-Progress -Activity $executionActivity -Status "Loading JSON"
& "$ishBootstrapPath\Examples\Load-ISHBootstrapperContext.ps1" -JSONPath $jsonPath

Write-Progress -Activity $executionActivity -Status "Initializing PowerShell"
& "$ishBootstrapPath\Examples\Initialize-PowerShellGet.ps1"

Write-Progress -Activity $executionActivity -Status "Installing required PowerShell modules"
& "$ishBootstrapPath\Examples\Install-Module.ps1"

Write-Progress -Activity $executionActivity -Status "Installing ISH prerequisites"
& "$ishBootstrapPath\Examples\Initialize-ISHServer.ps1"

Write-Progress -Activity $executionActivity -Status "Downloading and expanding ISH CD"
& "$ishBootstrapPath\Examples\Copy-ISHCD.Released.ps1"

Write-Progress -Activity $executionActivity -Status "Installing ISH"
& "$ishBootstrapPath\Examples\Install-ISH.ps1"

Write-Progress -Activity $executionActivity -Status "Executing code as configuration"
& "$ishBootstrapPath\Examples\Invoke-ISHDeployScript.ps1" -Configure

#endregion

Write-Progress -Activity $downloadActivity -Completed

Write-Warning "A restart is advised"
