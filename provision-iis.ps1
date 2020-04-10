# NB use Get-WindowsFeature | Format-Table -AutoSize | Out-String -Width 1024 to list all the available features.
Write-Host 'Installing IIS and its management tools...'
Install-WindowsFeature `
    Web-Default-Doc,
    Web-Http-Errors,
    Web-Http-Logging,
    Web-Http-Tracing,
    Web-Static-Content,
    Web-Asp-Net45 `
    -IncludeManagementTools

Write-Host 'Configuring IIS logging...'
# NB this modifies %windir%\system32\inetsrv\config\applicationHost.config
# NB you can see the IIS schema at %windir%\system32\inetsrv\config\schema\IIS_schema.xml
# NB you can get the current configuration with, e.g.:
#       Get-WebConfiguration -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter 'system.applicationHost/sites/siteDefaults/logFile'
#       Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter 'system.applicationHost/sites/siteDefaults/logFile' -Name 'logExtFileFlags'
Set-WebConfigurationProperty `
    -PSPath 'MACHINE/WEBROOT/APPHOST' `
    -Filter 'system.applicationHost/sites/siteDefaults/logFile' `
    -Name 'logExtFileFlags' `
    -Value 'Date,Time,ClientIP,UserName,SiteName,ComputerName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ServerPort,UserAgent,Cookie,Referer,ProtocolVersion,Host,HttpSubStatus'
