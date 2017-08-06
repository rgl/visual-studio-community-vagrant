# see https://github.com/dotnet/cli/releases/tag/v2.0.0-preview2
# see https://github.com/dotnet/core/blob/master/release-notes/download-archives/2.0.0-preview2-download.md

# opt-out from dotnet telemetry.
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

# install the dotnet sdk.
# see https://github.com/dotnet/cli/releases/tag/v1.0.1
$archiveUrl = 'https://download.microsoft.com/download/6/1/B/61B3E81F-5509-48D2-BB4F-5189E23CD29A/dotnet-sdk-2.0.0-preview2-006497-win-x64.exe'
$archiveHash = 'ee0a681c375a062dd644b7ec4813f74ce0379a85833d4b2502049292b89816a8'
$archiveName = Split-Path -Leaf $archiveUrl
$archivePath = "$env:TEMP\$archiveName"
Write-Host "Downloading $archiveName..."
Invoke-WebRequest $archiveUrl -UseBasicParsing -OutFile $archivePath
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Host "Installing $archiveName..."
&$archivePath /install /quiet /norestart | Out-String -Stream
if ($LASTEXITCODE) {
    throw "Failed to install dotnetcore-sdk with Exit Code $LASTEXITCODE"
}
Remove-Item $archivePath

# reload PATH.
$env:PATH = "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$([Environment]::GetEnvironmentVariable('PATH', 'User'))"

# show information about dotnet.
dotnet --info
