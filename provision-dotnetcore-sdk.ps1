# see https://dotnet.microsoft.com/download/dotnet-core/3.1
# see https://github.com/dotnet/core/blob/master/release-notes/3.1/3.1.9/3.1.403-download.md

# opt-out from dotnet telemetry.
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

# install the dotnet sdk.
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/38136cfe-04d4-4ce8-a8ea-369a800021df/08b29e05cd798d96b5987b417a989b80/dotnet-sdk-3.1.403-win-x64.exe'
$archiveHash = 'c8519eb9dd5c7f54fa517cf6148e177cbf3b061a95b9feee3cb1161a27ca09d5d4b8c09ee15dfbf6a7b324879f961ebeaa50efe74e93699b12ab8fee349b2b7d'
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

# make sure the SYSTEM account PATH environment variable is empty because,
# for some reason, the sdk setup changes it to include private directories
# which cannot be accessed by anyone but the user that installed the sdk.
# see https://github.com/dotnet/core/issues/1942.
# NB the .DEFAULT key is for the local SYSTEM account (S-1-5-18).
New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
New-ItemProperty `
    -Path HKU:\.DEFAULT\Environment `
    -Name Path `
    -Value '' `
    -PropertyType ExpandString `
    -Force `
    | Out-Null
Remove-PSDrive HKU
