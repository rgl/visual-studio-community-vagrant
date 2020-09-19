# see https://dotnet.microsoft.com/download/dotnet-core/3.1
# see https://github.com/dotnet/core/blob/master/release-notes/3.1/3.1.8/3.1.402-download.md

# opt-out from dotnet telemetry.
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

# install the dotnet sdk.
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/9706378b-f244-48a6-8cec-68a19a8b1678/1f90fd18eb892cbb0bf75d9cff377ccb/dotnet-sdk-3.1.402-win-x64.exe'
$archiveHash = '1c933d0bab8896e41fc92640c859b18ad8debf5a61d17a0b484d24dc1edfb24640393d17435321f983e2cd7d9e2fc4fc9f679bf6821ffc2fc0602803499c6169'
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
