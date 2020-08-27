if (Get-Command -ErrorAction SilentlyContinue Install-WindowsFeature) {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
} else {
    Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName Microsoft-Hyper-V -All
}
