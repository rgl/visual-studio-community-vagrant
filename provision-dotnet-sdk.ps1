# see https://dotnet.microsoft.com/download/dotnet/6.0
# see https://github.com/dotnet/core/blob/main/release-notes/6.0/6.0.3/6.0.3.md

# opt-out from dotnet telemetry.
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

# install the dotnet sdk.
# NB keep this in sync with provision-iis-dotnet-hosting.ps1
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/1eb43f77-61af-40b0-8a5a-6165724dca60/f12aac6d4a907b4d54f5d41317aae0f7/dotnet-sdk-6.0.201-win-x64.exe'
$archiveHash = '7fcd52d520a82c8b2dedc6e3074e2201643ea4d8897b521bfa9e5e9af39a2eadcae9836cc5e4f6707e1077bbeab67159735b67fedd87bd8de3953b94e81ba1a2'
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

# install the sourcelink dotnet global tool.
dotnet tool install --global sourcelink
