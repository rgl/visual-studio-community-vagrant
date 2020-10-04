if (Get-Command -ErrorAction SilentlyContinue Install-WindowsFeature) {
    Install-WindowsFeature Hyper-V -IncludeManagementTools
} else {
    Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName Microsoft-Hyper-V-All
}
