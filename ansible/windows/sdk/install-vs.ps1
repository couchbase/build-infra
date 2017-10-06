# Adapted from script by Jason Huggins (git @sonjz)
# https://github.com/ansible/ansible-modules-extras/issues/275
# Install Visual Studio but with a scheduled job.
# In your ansible task, add the following:
#    # NOTE: Can't install VS 2015 via WinRM, so win_chocolatey fails
#    - name: "Install Visual Studio 2015 Professional"
#      script: install-vs.ps1
param (
   [string]$chocopackage = "UNKNOWN"
)

function Invoke-InstallVS() {

  $invokeScript = {
    param (
      [string]$chocopackage
    )
    $baseFile = "C:\Invoke-InstallVS";

    if (Test-Path("$baseFile.DONE")) {
      Move-Item "$baseFile.DONE" "$baseFile.$((Get-Date -Format O) -replace ':','').BAK" ;
    }
    #choco.exe install "$chocopackage" --installargs "/AdminFile C:\vs-unattended.xml" -y | Out-File "$baseFile.PROCESSING" ;
    choco.exe install "$chocopackage" -y | Out-File "$baseFile.PROCESSING" ;
    Move-Item "$baseFile.PROCESSING" "$baseFile.DONE" ;
  } ;

  # remove the job (if exists), create a new one.
  # NOTE: this will clobber any previous job
  $jobName = "Invoke-InstallVS" ;
  $result = Get-ScheduledJob | Where { $_.Name -eq "$jobName" } ;
  if ($result) {
    Unregister-ScheduledJob -Name "$jobName" ;
  }
  Register-ScheduledJob -Name "$jobName" -RunNow -ScriptBlock $invokeScript -ArgumentList $chocopackage ;
  $invokeScript | Out-File C:\script.txt
}

Invoke-InstallVS ;


# monitor for DONE file and report
$doneFile =  "C:\Invoke-InstallVS.DONE" ;
Start-Sleep -s 5 ;
while(!(Test-Path $doneFile)) {
  Start-Sleep -s 5 ;
}
Get-Content $doneFile ;

