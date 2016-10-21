# Very simplified demo sample for ISHBootstrap

This is a small demostrantion on how to execute [ISHBootstrap](https://github.com/Sarafian/ISHBootstrap) on a clean windows server using the embeded example structure. 
Please read [How to use the repository (Examples)](https://github.com/Sarafian/ISHBootstrap/blob/master/Topics/How%20to%20use%20the%20repository%20(Examples).md) 

The instructions are tested against a Windows Server 2016 Evaluation. 

This repository showcases:
- How an obfuscated JSON file looks like. 
- What is the correct sequence.

## Acknowledgements

**Before you start:** 

- A web server certificate must be available on the target host. To issue and push a certificate from the domain controller please consult [Bootstrap VM with certificates issued by your active directory certificate authority](https://sarafian.github.io/post/powershell/active-directory-issue-certificate-for-vm/).
- PowerShell v5 is required on the target host.

**Remarks to consider:** 

- The [ISHBootstrap.json](ISHBootstrap.json) has stripped out all properties relative to remoting.
- The [ISHBootstrap.json](ISHBootstrap.json) is obfuscated to share this repository.
- [ISHBootstrap.ps1](ISHBootstrap.ps1) has three execution modes
  - **Prompt for credentials** to ask for the credential of the `osuser` and ftp. Don't modify the `OSUserCredentialExpression` and `FTP.CredentialExpression` in [ISHBootstrap.json](ISHBootstrap.json).
  - **No credentials** and the `OSUserCredentialExpression` and `FTP.CredentialExpression` in [ISHBootstrap.json](ISHBootstrap.json) must implement this aspect.
  - **Credentials as parameters**. Don't modify the `OSUserCredentialExpression` and `FTP.CredentialExpression` in [ISHBootstrap.json](ISHBootstrap.json).
- [ISHBootstrap.ps1](ISHBootstrap.ps1) will access your adjusted `ISHBootstrap.json` from the following possible locations:
  - Next to the script itself.
  - From a file path.
  - From an http url. In this case, ISHDeploy configuration scripts must be limited to the ones in [ISHBootstrap](https://github.com/Sarafian/ISHBootstrap) repository.
- A restart is advised at the end but depending on the operating system it might not be necessary.
  - Will not do Oracle to avoid the necessary restart.

## Execute the demo

On the target server:
1. In the same folder
  1. Place [ISHBootstrap.ps1](ISHBootstrap.ps1) on a the server.
  1. Place an `ISHBootstrap.json` next to the script.
1. Launch a console with administrator priviledges.
1. Change directory into the folder.
1. Execute one of the following.

```
# target master branch
powershell -File ISHBootstrap.ps1

# target develop branch
powershell -File ISHBootstrap.ps1 -Branch develop  

# target v0.2 tag
powershell -File ISHBootstrap.ps1 -Tag "v0.3"  
```

## What is Copy-ToRemote.ps1?

Its a script to help copy [ISHBootstrap.ps1](ISHBootstrap.ps1) on the remote host for debugging purposes. 