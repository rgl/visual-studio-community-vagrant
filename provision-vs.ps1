# add support for building applications that target the .net 4.8.0 framework.
choco install -y netfx-4.8-devpack

# install Visual Studio Community 2022 17.0.1.
# see https://www.visualstudio.com/vs/
# see https://visualstudio.microsoft.com/downloads/
# see https://docs.microsoft.com/en-us/visualstudio/releases/2022/release-notes
# see https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio
# see https://docs.microsoft.com/en-us/visualstudio/install/command-line-parameter-examples
# see https://docs.microsoft.com/en-us/visualstudio/install/workload-and-component-ids
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/8cea3871-c742-43fb-bf8b-8da0699ab4af/f0640c0be6fb51089f14f5e4476f189dc59b51c2d4106c1630274c2c74f7a17a/vs_Community.exe' # https://aka.ms/vs/17/release/vs_community.exe
$archiveHash = 'f0640c0be6fb51089f14f5e4476f189dc59b51c2d4106c1630274c2c74f7a17a'
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName"
Write-Host 'Downloading the Visual Studio Setup Bootstrapper...'
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Host 'Installing Visual Studio...'
$vsHome = 'C:\VisualStudio2022Community'
# NB the Windows 10 SDK 19041 must be compatible with the Windows 10 WDK that we install in provision-wdk.ps1.
for ($try = 1; ; ++$try) {
    &$archivePath `
        --installPath $vsHome `
        --add Microsoft.VisualStudio.Workload.CoreEditor `
        --add Microsoft.VisualStudio.Workload.NetWeb `
        --add Microsoft.VisualStudio.Workload.ManagedDesktop `
        --add Microsoft.VisualStudio.Workload.NativeDesktop `
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        --add Microsoft.VisualStudio.Component.Windows10SDK.19041 `
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

# configure vs.
# see https://docs.microsoft.com/en-us/visualstudio/ide/reference/resetsettings-devenv-exe?view=vs-2022
# see https://docs.microsoft.com/en-us/visualstudio/ide/how-to-change-fonts-and-colors-in-visual-studio?view=vs-2022
Write-Host 'Configuring Visual Studio...'
$devenv = "$vsHome\Common7\IDE\devenv.com"
$settingsHomePath = "$env:LOCALAPPDATA\Microsoft\VisualStudio"
if (Test-Path $settingsHomePath) {
    Remove-Item -Recurse -Force $settingsHomePath
}
&$devenv /NoSplash /ResetSettings General /Command Exit | Out-String -Stream
$settingsPath = (Get-ChildItem -Recurse "$settingsHomePath\CurrentSettings.vssettings").FullName
$defaultSettingsPath = "$(Split-Path -Parent $settingsPath)\DefaultSettings.vssettings"
Move-Item $settingsPath $defaultSettingsPath
$xsl = New-Object System.Xml.Xsl.XslCompiledTransform
$xsl.Load("$PWD\vs-settings.xsl")
$xsl.Transform($defaultSettingsPath, $settingsPath)
