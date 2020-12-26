Get-PackageProvider -Name NuGet -Force | Out-Null
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name PowerShellGet -Force
Update-Module -Name PowerShellGet
