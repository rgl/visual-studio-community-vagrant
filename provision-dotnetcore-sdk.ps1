# see https://dotnet.microsoft.com/download/dotnet-core/3.1
# see https://github.com/dotnet/core/blob/main/release-notes/3.1/3.1.13/3.1.407-download.md

# opt-out from dotnet telemetry.
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

# install the dotnet sdk.
# NB keep this in sync with provision-iis-dotnetcore-hosting.ps1
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/a45c8c1c-6466-4afc-a266-bd540069a4a6/97293f1080615bba5572ad1ef3be254c/dotnet-sdk-3.1.407-win-x64.exe'
$archiveHash = 'd80d05c292361ac464d2d231c649e18db7f30abddd9257087b47908ceb123cd9f702e65ca875ecdc359333f9ed2bdd5275a2f3431786b00c47afaef4579e1355'
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
    throw "Failed to install dotnetcore-sdk with Exit Code $LASTEXITCODE"
}
Remove-Item $archivePath

# reload PATH.
$env:PATH = "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$([Environment]::GetEnvironmentVariable('PATH', 'User'))"

# show information about dotnet.
dotnet --info

# install the sourcelink dotnet global tool.
dotnet tool install --global sourcelink
