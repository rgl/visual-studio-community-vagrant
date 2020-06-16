# see https://wiki.ubuntu.com/WSL
# see https://docs.microsoft.com/en-us/windows/wsl

$distroUser = $env:USERNAME.ToLowerInvariant()
$distroName = 'Ubuntu-20.04'
$distroPath = "C:\Wsl\$distroName"
$archiveUrl = 'https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-wsl.rootfs.tar.gz'
$archivePath = "$env:TEMP\$(Split-Path -Leaf $archiveUrl)"

Write-Host "Downloading $distroName..."
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)

Write-Host "Installing Ubuntu to $distroPath..."
mkdir -Force (Split-Path -Parent $distroPath) | Out-Null
wsl.exe --import $distroName $distroPath $archivePath
Remove-Item $archivePath

Write-Host 'Configuring Ubuntu...'
$provisionWslScript = 'C:\Windows\Temp\provision-wsl-ubuntu.sh'
Copy-Item provision-wsl-ubuntu.sh $provisionWslScript
wsl.exe --distribution $distroName -- /mnt/c/Windows/Temp/provision-wsl-ubuntu.sh $distroUser
wsl.exe --distribution $distroName --shutdown
Remove-Item $provisionWslScript

# add the Ubuntu 20.04 shortcut to the Start Menu.
Copy-Item ubuntu.ico $distroPath # see https://findicons.com/icon/88935/ubuntu
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Install-ChocolateyShortcut `
    -ShortcutFilePath "C:\Users\All Users\Microsoft\Windows\Start Menu\Programs\Ubuntu 20.04.lnk" `
    -TargetPath ((Get-Command wsl.exe).Source) `
    -Arguments "--distribution $distroName" `
    -IconLocation C:\Wsl\Ubuntu-20.04\ubuntu.ico `
    -WorkingDirectory '%USERPROFILE%'

Write-Host @"

You can remove Ubuntu with:

    wsl.exe --unregister $distroName
    Remove-Item -Recurse $distroPath

For more information see https://docs.microsoft.com/en-us/windows/wsl/wsl-config

"@

Write-Title 'Installed WSL distributions'
wsl.exe --list --verbose
