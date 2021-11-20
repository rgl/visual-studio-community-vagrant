# see https://dotnet.microsoft.com/download/dotnet-core/3.1
# see https://github.com/dotnet/core/blob/main/release-notes/3.1/3.1.17/3.1.411-download.md

# opt-out from dotnet telemetry.
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

# install the dotnet sdk.
# NB keep this in sync with provision-iis-dotnetcore-hosting.ps1
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/17d4e08f-c93a-4e2c-83e6-1e7010b5c7ad/53fc30104eb36c45f6ef5930e4c88c01/dotnet-sdk-3.1.411-win-x64.exe'
$archiveHash = '79b2726f425c2d0bc4dffc05e65ec3f8a70e526b59671ec2bddaaaef598a72b461b0344e736775a3fa2541a4b175adeb7709487828f30b2f9e777e17076f4bf4'
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

# add the nuget.org source.
# see https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-nuget-add-source
dotnet nuget add source --name nuget.org https://api.nuget.org/v3/index.json
dotnet nuget list source

# install the sourcelink dotnet global tool.
dotnet tool install --global sourcelink
