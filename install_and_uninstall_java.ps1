#---------------------Uninstall Java----------------------------------------------
function GetUninstallString ($productName) {

  #PowerShell script to uninstall Java SE (JRE) version on computer
  $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
  ($x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
       | ForEach-Object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
       | Where-Object { $_.DisplayName -and $_.DisplayName -eq $productName } `
       | Select-Object UninstallString).UninstallString
}
function UninstallJava ($name) {
  $java8 = (GetUninstallString 'Java SE Development Kit 8 Update 221')
  $uninstallCommand = (GetUninstallString $name)
  if ($uninstallCommand) {
    Write-Host "Uninstalling $name"

    $uninstallCommand = $uninstallCommand.Replace('MsiExec.exe /I{','/x{').Replace('MsiExec.exe /X{','/x{')
    cmd /c start /wait msiexec.exe $uninstallCommand /quiet

    Write-Host "Uninstalled $name"
  }
}


#---------------------Installing Java jdk 8------------------------------------

function InstallJava ($javaVersion,$jdkVersion,$url,$fileName,$jdkPath,$jrePath) {

  Write-Host "Installing $javaVersion..."

  #download
  Write-Verbose "Downloading installer"
  $exePath = "$env:USERPROFILE\$fileName"
  $logPath = "$env:USERPROFILE\$fileName-install.log"
  [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
  $client = New-Object Net.WebClient
  $client.Headers.Add('Cookie','gpw_e24=http://www.oracle.com; oraclelicense=accept-securebackup-cookie')
  $client.DownloadFile($url,$exePath)

  #Silent install Java
  $arguments = "/c start /wait $exePath /s ADDLOCAL=`"ToolsFeature,PublicjreFeature`" INSTALLDIR=`"$jdkPath`" /INSTALLDIRPUBJRE=`"$jrePath`""
  Start-Process cmd.exe -WindowStyle Hidden -ArgumentList $arguments

  #installation paths
  Write-Host "Installing JDK to $jdkPath"
  Write-Host "Installing JRE to $jrePath"

  #waiting time for complete installation
  Start-Sleep -s 20

  Write-Verbose "$javaVersion installed"
}

$path = "C:\Users\user\OneDrive\Documents\Tomcat_dependencies\dependencies.properties"
$output = Get-Content $path | ConvertFrom-StringData

#variables
$javaVersion = $output.javaVersion
$jdkVersion = $output.jdkVersion
$fileName = $output.fileName
$jdk = $output.jdk
$jre = $output.jre
$java_logs = $output.java_logs

$VerbosePreference = "continue"

#starting Transcripts for logs..
Start-Transcript -Path $java_logs

#Calling Java uninstall functions
UninstallJava 'Java SE Development Kit 8 Update 221'
UninstallJava 'Java SE Development Kit 8 Update 221 (64-bit)'
UninstallJava 'Java 8 Update 221'
UninstallJava 'Java 8 Update 221 (64-bit)'

#Calling Java install functions
InstallJava $javaVersion $jdkVersion "https://storage.googleapis.com/appveyor-download-cache/jdk/$fileName" $fileName "$env:ProgramFiles\Java\$jdk" "$env:ProgramFiles\Java\$jre"

# Set Java home
[Environment]::SetEnvironmentVariable("JAVA_HOME","C:\Progra~1\Java\$jdk","machine")
$env:JAVA_HOME = "C:\Progra~1\Java\$jdk"



Stop-Transcript
