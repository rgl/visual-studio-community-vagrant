# see https://docs.microsoft.com/en-us/windows/wsl

$archiveUrl = 'https://aka.ms/wsl-ubuntu-1804'
$archivePath = "$env:TEMP\wsl-ubuntu-18.04.zip"
$distroPath = "C:\Wsl\Ubuntu-18.04"

Write-Host 'Downloading Ubuntu 18.04...'
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)

Write-Host "Installing Ubuntu to $distroPath..."
Expand-Archive $archivePath $distroPath
Remove-Item $archivePath
$distroExe = (Resolve-Path "$distroPath\*.exe").Path
&$distroExe install --root

Write-Host 'Configuring Ubuntu...'
$provisionWslScript = 'C:\Windows\Temp\provision-wsl-ubuntu.sh'
Copy-Item C:\vagrant\provision-wsl-ubuntu.sh $provisionWslScript
&$distroExe run /mnt/c/Windows/Temp/provision-wsl-ubuntu.sh
&$distroExe config --default-user vagrant
Remove-Item $provisionWslScript

Write-Host 'You can remove Ubuntu and all settings with wsl.exe --list then wsl.exe --unregister Ubuntu-18.04'
Write-Host 'For more information see https://docs.microsoft.com/en-us/windows/wsl/wsl-config'

Write-Title 'Installed WSL distributions'
wsl.exe --list --verbose
