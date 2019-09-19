Configuring Windows VMs for Ansible
-----------------------------------

The ConfigureForAnsible.ps1 script must be run on a Windows Server 2012 R2
slave (or probably other Windows versions) to enable WinRM remote control.
This is the only thing necessary to allow Ansible to run. Run with:

    ConfigureForAnsible.ps1 -SkipNetworkProfileCheck -ForceNewSSLCert

This script was originally from

    http://docs.ansible.com/ansible/intro_windows.html#windows-system-prep

I have hacked it to always use the local `New-LegacySelfSignedCert` function
(regardless of the version of PowerShell) and then to set the expiration
date of the new self-signed certificate 10,000 days into the future. This
was necessary because:

1. This script ignores its own `CertValidityDays` argument

2. Windows 2012 R2's version of `New-SelfSignedCertificate` can only create
   a certificate with a 365 day expiration.

Windows 10
----------

In addition to the above, make sure that your network connection is not set
to "Public" before running the ConfigureForAnsible.ps1 script. This can be
done via Settings -> Network & Internet -> Change Connection Properties.
If it's Public, the Enable-PSRemoting step will fail.

WinRM Service
-------------

By default on Windows 10 - unclear about Windows Server - the "Windows
Remote Management" service is set to Automatic (Delayed Start), which means
that WinRM will be unavailable for two minutes after rebooting. If this is
problematic it can be set to simply "Automatic".

prep-for-ansible.sh
-------------------

The script "prep-for-ansible.sh" is a quick shell script that will run this
Powershell script on a Windows VM that is accessible via SSH (as many QE and
build slaves are). It expects a file named "password.txt" containing the
Administrator password in the current working directory.
