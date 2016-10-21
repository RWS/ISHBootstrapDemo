  # Very simplified demo sample for ISHBootstrap

This is a small demostrantion on how to execute [ISHBootstrap](https://github.com/Sarafian/ISHBootstrap) on a clean windows server using the embeded example structure. 
Please read [How to use the repository (Examples)](https://github.com/Sarafian/ISHBootstrap/blob/master/Topics/How%20to%20use%20the%20repository%20(Examples).md) 

The instructions are tested against a Windows Server 2016 Evaluation. 
This repository showcases:
- How an obfuscated JSON file looks like. 
- What is the correct sequence.

## Acknowledgements

**Before you start:** 
- A web server certificate must be available on the server. To issue and push a certificate from the domain controller please consult [Bootstrap VM with certificates issued by your active directory certificate authority](https://sarafian.github.io/post/powershell/active-directory-issue-certificate-for-vm/).
- PowerShell v5 is required.
- The contents of this directory need to be present on the server. 
  - To help develop this repository, a section is contained demonstrating how to copy the above from my client operating operating system. 

**Remarks to consider:** 
- [ISHBootstrap.ps1](ISHBootstrap.ps1) executes locally and requires administrator priviledges. 
  - The [ISHBootstrap.json](ISHBootstrap.json) has stripped out all properties relative to remoting.
  - The [ISHBootstrap.json](ISHBootstrap.json) is obfuscated to share this repository.
  - You need to define your own file and place it next to `ISHBootstrap.ps1` on the target host.
- A restart is advised at the end but depending on the operating system it might not be necessary.
  - Will not do Oracle to avoid the necessary restart.
- [ISHBootstrap.ps1](ISHBootstrap.ps1) will pause only two times to ask for the credential of the `osuser` and ftp. 
It will then store the value in the global variable collection. 
The `OSUserCredentialExpression` and `FTP.CredentialExpression` in [ISHBootstrap.json](ISHBootstrap.json) will leverage them with the correct expression. 
This is done to smoothen the experience. 
If you chose to implement an other mechanism then please change the values in the [ISHBootstrap.json](ISHBootstrap.json) and consider the `-NoCredentialPrompt` parameter for the [ISHBootstrap.ps1](ISHBootstrap.ps1).

## Copy the required files to the server

Make sure the following files are all placed under the same folder 

- `ISHBootstrap.ps1`
- `ISHBootstrap.json`

## (internal) Copy the required files to the server

Execute [Copy-ToRemote.ps1](Copy-ToRemote.ps1). PowerShell v5 is required. 
Powershell remoting is required on the target server.

## Execute

On the target server:

1. Launch a console with administrator priviledges
1. Execute one of the following 

```
# target master branch
powershell -File ISHBootstrap.ps1

# target develop branch
powershell -File ISHBootstrap.ps1 -Branch develop  

# target v0.2 tag
powershell -File ISHBootstrap.ps1 -Tag "v0.2"  
```