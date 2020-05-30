if (Get-Command -ErrorAction SilentlyContinue Install-WindowsFeature) {
    Install-WindowsFeature Containers
} else {
    Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName Containers
}
