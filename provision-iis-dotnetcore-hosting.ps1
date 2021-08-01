# see https://dotnet.microsoft.com/download/dotnet-core/3.1
# see https://github.com/dotnet/core/blob/main/release-notes/3.1/3.1.17/3.1.411-download.md

# install the dotnet core hosting bundle/module.
# NB this install the module to "C:\Program Files\IIS\Asp.Net Core Module" and registers it in IIS.
# NB keep this in sync with provision-dotnetcore-sdk.ps1
# see https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/?view=aspnetcore-3.1#install-the-net-core-hosting-bundle
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/db4f9e1d-7ef3-4409-8c37-1c57a66c1232/97f890c7af1f3e2049992299f2c7a54c/dotnet-hosting-3.1.17-win.exe'
$archiveHash = '680ecfe0f3f920deb2f5514c56ae84a715f8c54852a682e5bfea0047355b933fe41cb6395761c5de79bd86d9abd071b77c3b5d65fa10655ec1d76600935ecc64'
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
