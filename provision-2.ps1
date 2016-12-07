choco install -y resharper

# import the Chocolatey cmdlets.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1

# install VSColorOutput 2.4.
Install-ChocolateyVsixPackage `
    VSColorOutput `
    https://www.visualstudiogallery.msdn.microsoft.com/f4d9c2b5-d6d7-4543-a7a5-2d7ebabc2496/file/63103/18/VSColorOutput.vsix `
    -checksum 8417934805ab74a8b28b543f66a4a256990452c112d83cf60113096138391bec `
    -checksumType sha256
