# add support for building applications that target the .net 4.7.2 framework.
choco install -y netfx-4.7.2-devpack

# add support for building applications that target the .net 4.7.1 framework.
choco install -y netfx-4.7.1-devpack

# add support for building applications that target the .net 4.6.2 framework.
choco install -y netfx-4.6.2-devpack

# install Visual Studio Community 2019 16.5.3.
# see https://www.visualstudio.com/vs/
# see https://visualstudio.microsoft.com/downloads/
# see https://docs.microsoft.com/en-us/visualstudio/releases/2019/release-notes
# see https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio
# see https://docs.microsoft.com/en-us/visualstudio/install/command-line-parameter-examples
# see https://docs.microsoft.com/en-us/visualstudio/install/workload-and-component-ids
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/ac28b571-7709-4635-83d0-6277d6102ecb/893084d903e5d490b248099fdbb341b684fe026435ff2824f6e66f98fb0d1070/vs_Community.exe'
$archiveHash = '893084d903e5d490b248099fdbb341b684fe026435ff2824f6e66f98fb0d1070'
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName"
Write-Host 'Downloading the Visual Studio Setup Bootstrapper...'
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Host 'Installing Visual Studio...'
$vsHome = 'C:\VisualStudio2019Community'
# NB the Windows 10 SDK 17763 must be compatible with the Windows 10 WDK that we install in provision-wdk.ps1.
for ($try = 1; ; ++$try) {
    &$archivePath `
        --installPath $vsHome `
        --add Microsoft.VisualStudio.Workload.CoreEditor `
        --add Microsoft.VisualStudio.Workload.NetCoreTools `
        --add Microsoft.VisualStudio.Workload.NetWeb `
        --add Microsoft.VisualStudio.Workload.ManagedDesktop `
        --add Microsoft.VisualStudio.Workload.NativeDesktop `
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        --add Microsoft.VisualStudio.Component.Windows10SDK.17763 `
        --norestart `
        --quiet `
        --wait `
        | Out-String -Stream
    if ($LASTEXITCODE) {
        if ($try -le 5) {
            Write-Host "Failed to install Visual Studio with Exit Code $LASTEXITCODE. Trying again (hopefully the error was transient)..."
            Start-Sleep -Seconds 10
            continue
        }
        throw "Failed to install Visual Studio with Exit Code $LASTEXITCODE"
    }
    break
}

# add MSBuild to the machine PATH.
[Environment]::SetEnvironmentVariable(
    'PATH',
    "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$vsHome\MSBuild\Current\Bin",
    'Machine')
