# see https://dotnet.microsoft.com/download/dotnet/6.0
# see https://github.com/dotnet/core/blob/main/release-notes/6.0/6.0.3/6.0.3.md

# install the dotnet core hosting bundle/module.
# NB this install the module to "C:\Program Files\IIS\Asp.Net Core Module" and registers it in IIS.
# NB keep this in sync with provision-dotnetcore-sdk.ps1
# see https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/?view=aspnetcore-6.0#install-the-net-core-hosting-bundle
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/41d7c644-140a-40b5-9eb7-071544b79c65/885b7fa698a2d1d3a79ad363613f8ff2/dotnet-hosting-6.0.3-win.exe'
$archiveHash = '1c52efadd3792f2d8a595400add3ad7744e9b6ab94d40df0844841a90b8175ea4eb7b54c24c5d700e537533870e1cb0f7277bc4649cc707d236c0af0d4638aca'
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
# see https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/modules?view=aspnetcore-6.0#minimum-module-configuration
Write-Host 'Enabling the UriCacheModule module...'
# NB this modifies %windir%\system32\inetsrv\config\applicationHost.config
# NB you can see the IIS schema at %windir%\system32\inetsrv\config\schema\IIS_schema.xml
# NB you can get the current configuration with, e.g.:
#       Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter 'system.webServer/modules' -Name 'Collection'
Enable-WebGlobalModule -Name UriCacheModule

Write-Host 'Restarting IIS (and dependent services)...'
Restart-Service w3svc -Force
