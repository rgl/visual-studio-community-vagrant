# add support for building applications that target the .net 4.7 framework.
choco install -y netfx-4.7-devpack

# add support for building applications that target the .net 4.6.2 framework.
choco install -y netfx-4.6.2-devpack

# see https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio
# see https://docs.microsoft.com/en-us/visualstudio/install/command-line-parameter-examples
$archiveUrl = 'https://aka.ms/vs/15/release/vs_Community.exe'
$archiveHash = '72e5b420b6732a6b26ab17daea0de473d9f2a33f239633d6113a2bd6c4e656aa'
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName"
Write-Host 'Downloading the Visual Studio Setup Bootstrapper...'
Invoke-WebRequest $archiveUrl -UseBasicParsing -OutFile $archivePath
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Host 'Installing Visual Studio...'
&$archivePath `
    --installPath C:\VisualStudio2017Community `
    --add Microsoft.VisualStudio.Workload.CoreEditor `
    --add Microsoft.VisualStudio.Workload.NetCoreTools `
    --add Microsoft.VisualStudio.Workload.NetWeb `
    --add Microsoft.VisualStudio.Workload.ManagedDesktop `
    --norestart `
    --quiet `
    --wait `
    | Out-String -Stream
if ($LASTEXITCODE) {
    throw "Failed to install Visual Studio with Exit Code $LASTEXITCODE"
}
