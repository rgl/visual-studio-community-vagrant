# see https://dotnet.microsoft.com/en-us/download/dotnet/6.0
# see https://github.com/dotnet/core/blob/main/release-notes/6.0/6.0.8/6.0.400.md

# install the dotnet core hosting bundle/module.
# NB this install the module to "C:\Program Files\IIS\Asp.Net Core Module" and registers it in IIS.
# NB keep this in sync with provision-dotnetcore-sdk.ps1
# see https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/?view=aspnetcore-6.0#install-the-net-core-hosting-bundle
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/c5e0609f-1db5-4741-add0-a37e8371a714/1ad9c59b8a92aeb5d09782e686264537/dotnet-hosting-6.0.8-win.exe'
$archiveHash = '5835cca327c6c7788e1d87ae5b310300424b866f6618181fe67691b47938732ffdd5444ae2ca425344efdaa6e454299bb2b67af0063e470eaa24a3cafeaea7bf'
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
