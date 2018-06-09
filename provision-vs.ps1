function Install-ModifiedChocolateyPackage($name, $version, $checksum, [scriptblock]$modifier) {
    $archiveUrl = "https://packages.chocolatey.org/$name.$version.nupkg"
    $archiveHash = $checksum
    $archiveName = Split-Path $archiveUrl -Leaf
    $archivePath = "$env:TEMP\$archiveName.zip"
    Write-Host "Downloading the $name package..."
    (New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
    $archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
    if ($archiveHash -ne $archiveActualHash) {
        throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
    }
    Expand-Archive $archivePath "$archivePath.tmp"
    Push-Location "$archivePath.tmp"
    Remove-Item -Recurse _rels,package,*.xml
    &$modifier
    choco pack
    choco install -y $name -Source $PWD
    Pop-Location
}

# add support for building applications that target the .net 4.7.2 framework.
# NB we have to install netfx-4.7.2-devpack manually, because for some odd reason,
#    the setup is returning the -1073741819 (0xc0000005 STATUS_ACCESS_VIOLATION)
#    exit code even thou it installs successfully.
Install-ModifiedChocolateyPackage netfx-4.7.2-devpack 4.7.2.0 f55b99592230c1a5617d4be099789841aa209e9e05fc7eef9e2c750f5d9fe6a0 {
    Set-Content -Encoding Ascii `
        tools/ChocolateyInstall.ps1 `
        ((Get-Content tools/ChocolateyInstall.ps1) -replace '0, # success','0,-1073741819, # success')
}

# add support for building applications that target the .net 4.7.1 framework.
# NB we have to install netfx-4.7.1-devpack manually, because for some odd reason,
#    the setup is returning the -1073741819 (0xc0000005 STATUS_ACCESS_VIOLATION)
#    exit code even thou it installs successfully.
#    see https://github.com/jberezanski/ChocolateyPackages/issues/22
Install-ModifiedChocolateyPackage netfx-4.7.1-devpack 4.7.2558.0 e293769f03da7a42ed72d37a92304854c4a61db279987fc459d3ec7aaffecf93 {
    Set-Content -Encoding Ascii `
        tools/ChocolateyInstall.ps1 `
        ((Get-Content tools/ChocolateyInstall.ps1) -replace '0, # success','0,-1073741819, # success')
    # do not depend on dotnet, as we already installed a recent version of dotnet from another package.
    Set-Content -Encoding Ascii `
        netfx-4.7.1-devpack.nuspec `
        ((Get-Content netfx-4.7.1-devpack.nuspec) -replace '.+dotnet4.7.1.+','')
}

# add support for building applications that target the .net 4.6.2 framework.
choco install -y netfx-4.6.2-devpack

# see https://www.visualstudio.com/vs/
# see https://www.visualstudio.com/en-us/news/releasenotes/vs2017-relnotes
# see https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio
# see https://docs.microsoft.com/en-us/visualstudio/install/command-line-parameter-examples
# see https://docs.microsoft.com/en-us/visualstudio/install/workload-and-component-ids
$archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/12390459/045b56eb413191d03850ecc425172a7d/vs_Community.exe'
$archiveHash = '5764159258ba5f95063c7a5007b3aeac688f57b3234ed86256d550cfea32497f'
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName"
Write-Host 'Downloading the Visual Studio Setup Bootstrapper...'
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Host 'Installing Visual Studio...'
for ($try = 1; ; ++$try) {
    &$archivePath `
        --installPath C:\VisualStudio2017Community `
        --add Microsoft.VisualStudio.Workload.CoreEditor `
        --add Microsoft.VisualStudio.Workload.NetCoreTools `
        --add Microsoft.VisualStudio.Workload.NetWeb `
        --add Microsoft.VisualStudio.Workload.ManagedDesktop `
        --add Microsoft.VisualStudio.Workload.NativeDesktop `
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        --add Microsoft.VisualStudio.Component.Windows10SDK.15063.Desktop `
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
