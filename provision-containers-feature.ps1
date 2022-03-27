if (Get-Command -ErrorAction SilentlyContinue Install-WindowsFeature) {
    Install-WindowsFeature Containers | Out-Null
} else {
    Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName Containers | Out-Null
}
