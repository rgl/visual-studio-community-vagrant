# see https://ubuntu.com/blog/ubuntu-on-wsl-2-is-generally-available
# see https://aka.ms/wsl2kernel

Write-Host 'Downloading the WSL2 kernel...'
$archiveUrl = 'https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi'
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
(New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)

Write-Host 'Installing the WSL2 kernel...'
msiexec /i $archivePath `
    /qn `
    /L*v "$archivePath.log" `
    | Out-String -Stream
if ($LASTEXITCODE) {
    throw "$archiveName installation failed with exit code $LASTEXITCODE. See $archivePath.log."
}
Remove-Item $archivePath

Write-Host 'Setting default WSL version to 2...'
wsl.exe --set-default-version 2
