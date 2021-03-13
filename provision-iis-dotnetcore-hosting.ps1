# see https://dotnet.microsoft.com/download/dotnet-core/3.1
# see https://github.com/dotnet/core/blob/main/release-notes/3.1/3.1.13/3.1.407-download.md

# install the dotnet core hosting bundle/module.
# NB this install the module to "C:\Program Files\IIS\Asp.Net Core Module" and registers it in IIS.
# NB keep this in sync with provision-dotnetcore-sdk.ps1
# see https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/?view=aspnetcore-3.1#install-the-net-core-hosting-bundle
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/0f60f951-edec-48a1-aaa1-2f5b5bcbb704/e205315e03bb9f4ac0a6a7efd5d89178/dotnet-hosting-3.1.13-win.exe'
$archiveHash = '771f64e8028dacff692f226316539bbf8dff0f84d5b41d5ee29d9659f16570b96f4ff45ab17b0521d751f00f43cd2ea27db35f8713bc7b01fc7e15d78a1d779b'
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
