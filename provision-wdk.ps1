# install the Windows Driver Kit (WDK) for Windows 10, version 2004.
# NB the WDK must be compatible with the Windows 10 SDK 19041 that we install in provision-vs.ps1.
$archiveUrl = 'https://download.microsoft.com/download/c/f/8/cf80b955-d578-4635-825c-2801911f9d79/wdk/wdksetup.exe'
$archiveHash = '5f4ea0c55af099f97cb569a927c3a290c211f17edcfc65009f5b9253b9827925'
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
