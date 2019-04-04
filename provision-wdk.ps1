# install the Windows Driver Kit (WDK) for Windows 10, version 1809.
# NB the WDK must be compatible with the Windows 10 SDK 17763 that we install in provision-vs.ps1.
$archiveUrl = 'http://download.microsoft.com/download/1/4/0/140EBDB7-F631-4191-9DC0-31C8ECB8A11F/wdk/wdksetup.exe'
$archiveHash = 'e6e5a57bf0a58242363cd6ca4762f44739f19351efc06cad382cca944b097235'
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
Write-Host "Downloading $archiveName..."
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Host "Installing $archiveName..."
# NB see the available features with &$archivePath /list
&$archivePath /features + /quiet /norestart | Out-String -Stream
if ($LASTEXITCODE) {
    throw "Failed to install dotnetcore-sdk with Exit Code $LASTEXITCODE"
}
Remove-Item $archivePath
