# see https://dotnet.microsoft.com/download/dotnet-core/3.1
# see https://github.com/dotnet/core/blob/master/release-notes/3.1/3.1.9/3.1.403-download.md

# install the dotnet core hosting bundle/module.
# NB this install the module to "C:\Program Files\IIS\Asp.Net Core Module" and registers it in IIS.
# NB keep this in sync with provision-dotnetcore-sdk.ps1
# see https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/?view=aspnetcore-3.1#install-the-net-core-hosting-bundle
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/beca42b0-54a8-4364-86b8-a3d88003fbb7/592e0eec1e5e53f78d9647f7112cc743/dotnet-hosting-3.1.9-win.exe'
$archiveHash = '674d5f7d12a3fd8070fe5faccda982f5a52a69321cd5018e22d47dfe7cb565667d3402ce1b14b1cf8df1eafcbc9ce56e8c078ed926a273bdc357674e92c221fd'
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
Write-Host "Downloading $archiveName..."
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA512).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Host "Installing $archiveName..."
&$archivePath /install /quiet /norestart | Out-String -Stream
if ($LASTEXITCODE) {
    throw "Failed to install dotnetcore hosting bundle with Exit Code $LASTEXITCODE"
}
Remove-Item $archivePath

# enable the recommended modules.
# see https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/modules?view=aspnetcore-3.1#minimum-module-configuration
Write-Host 'Enabling the UriCacheModule module...'
# NB this modifies %windir%\system32\inetsrv\config\applicationHost.config
# NB you can see the IIS schema at %windir%\system32\inetsrv\config\schema\IIS_schema.xml
# NB you can get the current configuration with, e.g.:
#       Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter 'system.webServer/modules' -Name 'Collection'
Enable-WebGlobalModule -Name UriCacheModule

Write-Host 'Restarting IIS (and dependent services)...'
Restart-Service w3svc -Force
