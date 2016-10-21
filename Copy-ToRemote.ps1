#Requires -Version 5

param(
    [Parameter(Mandatory=$true)]
    [string]$ComputerName,
    [Parameter(Mandatory=$true)]
    [pscredential]$Credential
)

try
{
    $session=New-PSSession -ComputerName $ComputerName -Credential $Credential
    $rootFolderName="ISHBootstrap"
    $block={
        if(-not (Test-Path $Using:rootFolderName))
        {
            New-Item $Using:rootFolderName -ItemType Directory|Out-Null
        }
        Get-Item -Path $Using:rootFolderName
    }
    
    $targetAbsolutePath=Invoke-Command -Session $session -ScriptBlock $block|Select-Object -ExpandProperty FullName
    $filePathToCopy=@(
        "$PSScriptRoot\ISHBootstrap.ps1"
    )
    Copy-Item -Path $filePathToCopy -Destination $targetAbsolutePath -ToSession $session
    Write-Host "Files copied to $targetAbsolutePath"
}
finally
{
    if($session)
    {
        $session|Remove-PSSession
    }
}