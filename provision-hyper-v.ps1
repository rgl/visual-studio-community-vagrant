while ($true) {
    try {
        if (Get-Command -ErrorAction SilentlyContinue Install-WindowsFeature) {
            Install-WindowsFeature Hyper-V -IncludeManagementTools
        } else {
            Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName Microsoft-Hyper-V-All
        }
        break
    } catch {
        Write-Host "WARN: Failed to install Hyper-V: $_"
        Start-Sleep -Seconds 15
        Write-Host "Retrying installation..."
    }
}
