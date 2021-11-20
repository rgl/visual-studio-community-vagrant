# only install WSL in Windows 2004+ Client/Workstation.
# see https://github.com/microsoft/WSL/issues/6301#issuecomment-858816891
$windowsCurrentVersionKey = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$windowsEdition = $windowsCurrentVersionKey.EditionID
if ($windowsEdition -like 'Server*') {
    Write-Host "WARN: WSL was skipped because it only works in the Client/Workstation Windows edition. The current Windows edition is $windowsEdition."
    Exit 0
}
if (Get-Command -ErrorAction SilentlyContinue Install-WindowsFeature) {
    Install-WindowsFeature Microsoft-Windows-Subsystem-Linux
} else {
    Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName Microsoft-Windows-Subsystem-Linux
}
