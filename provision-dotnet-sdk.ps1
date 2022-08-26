# see https://dotnet.microsoft.com/en-us/download/dotnet/6.0
# see https://github.com/dotnet/core/blob/main/release-notes/6.0/6.0.8/6.0.400.md

# opt-out from dotnet telemetry.
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

# install the dotnet sdk.
# NB keep this in sync with provision-iis-dotnet-hosting.ps1
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/9a1d2e89-d785-4493-aaf3-73864627a1ea/245bdfaa9c46b87acfb2afbd10ecb0d0/dotnet-sdk-6.0.400-win-x64.exe'
$archiveHash = '2ef178ceb63590e548fb644d265c4e1f8fdc319fa7d9f31442a958ac901198e4d1edc1b6ea213527bd9f5fba7925d7a12ce9a37d0fc791862518df70fa597f61'
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
    throw "Failed to install dotnet-sdk with Exit Code $LASTEXITCODE"
}
Remove-Item $archivePath

# reload PATH.
$env:PATH = "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$([Environment]::GetEnvironmentVariable('PATH', 'User'))"

# show information about dotnet.
dotnet --info

# add the nuget.org source.
# see https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-nuget-add-source
dotnet nuget add source --name nuget.org https://api.nuget.org/v3/index.json
dotnet nuget list source

# install the sourcelink dotnet global tool.
dotnet tool install --global sourcelink
