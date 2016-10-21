#Requires -RunAsAdministrator
#Requires -Version 5

<#
.Synopsis
    Downloads ISHBootstrap from github and executes the sequence from the Examples
.DESCRIPTION
    Downloads ISHBootstrap from github and executes the sequence from the Examples
.PARAMETER Branch
    The branch to download from ISHBootstrap repository
.PARAMETER JSONPath
    The path for a JSON to drive the automation. Can be http uri or file path
.PARAMETER NoCredential
    Script will not do anything for credentials. 
.PARAMETER PromptCredential
    Script will prompt for credentials. 
.PARAMETER FTPCredential
    Credential for FTP. 
.PARAMETER OSUserCredential
    Credential for OSUSer. 
.EXAMPLE
    $ftpCredential=Get-Credential -Message "FTP"
    $osUserCredential=Get-Credential -Message "OSUser"
    ISHBootstrap.ps1 -JSONPath $JSONPath -FTPCredential $ftpCredential -OSUserCredential $osUserCredential
.EXAMPLE
    ISHBootstrap.ps1 -Branch develop -JSONPath $JSONPath -PromptCredential
.EXAMPLE
    ISHBootstrap.ps1 -Tag "v0.3" -JSONPath $JSONPath -NoCredential
.Link
    https://github.com/Sarafian/ISHBootstrap
#>
param(
    [Parameter(Mandatory=$false,ParameterSetName="Branch prompt credential")]
    [Parameter(Mandatory=$false,ParameterSetName="Branch with credential")]
    [Parameter(Mandatory=$false,ParameterSetName="Branch without credential")]
    [string]$Branch="master",
    [Parameter(Mandatory=$true,ParameterSetName="Tag prompt credential")]
    [Parameter(Mandatory=$true,ParameterSetName="Tag with credential")]
    [Parameter(Mandatory=$true,ParameterSetName="Tag without credential")]
    [string]$Tag,
    [Parameter(Mandatory=$false,ParameterSetName="Tag prompt credential")]
    [Parameter(Mandatory=$false,ParameterSetName="Tag with credential")]
    [Parameter(Mandatory=$false,ParameterSetName="Tag without credential")]
    [Parameter(Mandatory=$false,ParameterSetName="Branch prompt credential")]
    [Parameter(Mandatory=$false,ParameterSetName="Branch with credential")]
    [Parameter(Mandatory=$false,ParameterSetName="Branch without credential")]
    [ValidateScript({
        switch ($_)
        {
            {$_ -like 'http*'} {
                try
                {
                    $request = Invoke-WebRequest -Uri $_ -MaximumRedirection 0 -UseBasicParsing
                }
                catch
                {
                    Throw [System.Management.Automation.ItemNotFoundException] "${_}"
                }
                $true
            }
            {$_ -like 'ftp'} {
                Throw [System.Management.Automation.ItemNotFoundException] "${_} ftp is not supported."
            }
            Default {
                if(-not (Test-Path $_ -PathType Leaf))
                {
                    Throw [System.Management.Automation.ItemNotFoundException] "${_} is not valid."
                }
                $true
            }
        }
    })]
    [string]$JSONPath="ISHBootstrap.json",
    [Parameter(Mandatory=$false,ParameterSetName="Tag without credential")]
    [Parameter(Mandatory=$false,ParameterSetName="Branch without credential")]
    [switch]$NoCredential=$false,
    [Parameter(Mandatory=$false,ParameterSetName="Tag prompt credential")]
    [Parameter(Mandatory=$false,ParameterSetName="Branch prompt credential")]
    [switch]$PromptCredential=$false,
    [Parameter(Mandatory=$true,ParameterSetName="Tag with credential")]
    [Parameter(Mandatory=$true,ParameterSetName="Branch with credential")]
    [pscredential]$FTPCredential,
    [Parameter(Mandatory=$true,ParameterSetName="Tag with credential")]
    [Parameter(Mandatory=$true,ParameterSetName="Branch with credential")]
    [pscredential]$OSUSerCredential
)

#region credential
switch ($PSCmdlet.ParameterSetName)
{
    {$_ -like '*prompt credential'} {
        $credentialActivity="Acquiring credentials"
        Write-Progress -Activity $credentialActivity -Status "Ask for FTP creential"
        $FTPCredential=Get-Credential -Message "Credential for FTP"
        if(-not $FTPCredential)
        {
            Write-Warning "Cancelled"
            return
        }
        Write-Progress -Activity $credentialActivity -Status "Ask for OSUser credential"
        $OSUSerCredential=Get-Credential -Message "Credential for OSUser"
        if(-not $OSUSerCredential)
        {
            Write-Warning "Cancelled"
            return
        }
        Set-Variable "ISHBootstrap.FTP" -Value $FTPCredential -Scope Global -Force
        Set-Variable "ISHBootstrap.OSUser" -Value $OSUSerCredential -Scope Global -Force
        break
    }
    {$_ -like '*with credential'} {
        Set-Variable "ISHBootstrap.FTP" -Value $FTPCredential -Scope Global -Force
        Set-Variable "ISHBootstrap.OSUser" -Value $OSUSerCredential -Scope Global -Force
        break
    }
    {$_ -like '*without credential'} {
        break
    }
}
#endregion

#region Initialize url to download ISHBootstrap from github
$gitHubHost="github.com"
$gitHubUser="Sarafian"

switch ($PSCmdlet.ParameterSetName)
{
    {$_ -like 'Tag*'} {
        $ishBootstrapReleaseUri="https://$gitHubHost/$gitHubUser/ISHBootstrap/archive/$Tag.zip"
        $downloadFileName="InfoShare-$Tag.zip"
    }
    {$_ -like 'Branch*'} {
        $ishBootstrapReleaseUri="https://$gitHubHost/$gitHubUser/ISHBootstrap/archive/$Branch.zip"
        $downloadFileName="InfoShare-$Branch.zip"
    }
}
#endregion

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

$executionActivity="ISHBootstrap execution"
#region Invoke ISHBootstrap

switch ($JSONPath)
{
    {$_ -like 'http*'} {
        $json=(Invoke-WebRequest -Uri $JSONPath -UseBasicParsing).Content
        Write-Progress -Activity $executionActivity -Status "Loading JSON from http url."
        & "$ishBootstrapPath\Examples\Load-ISHBootstrapperContext.ps1" -JSON $json -FolderPath $PSScriptRoot
    }
    Default {
        Write-Progress -Activity $executionActivity -Status "Loading JSON from file."
        & "$ishBootstrapPath\Examples\Load-ISHBootstrapperContext.ps1" -JSONPath $JSONPath
    }
}

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

Write-Information "Available urls"
Get-ISHDeployment |Select-Object Name,@{Name="ISHCM";Expression={"https://$($_.AccessHostName)/$($_.WebAppNameCM)/"}},@{Name="ISHWS";Expression={"https://$($_.AccessHostName)/$($_.WebAppNameWS)/"}}