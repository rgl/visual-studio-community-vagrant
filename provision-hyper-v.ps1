if (Get-Command -ErrorAction SilentlyContinue Install-WindowsFeature) {
    Install-WindowsFeature Microsoft-Hyper-V-All
} else {
    Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName Microsoft-Hyper-V-All
}
