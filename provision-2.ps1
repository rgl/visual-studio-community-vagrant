
# install Visual Studio Community.
# NB create the AdminFile with vs_community.exe /CreateAdminFile C:\vagrant\VisualStudioAdminDeploymentCustomizations.xml
# NB will return -1 or 3010 as a flag to let us known to reboot the machine.
Start-Choco `
    install, -y,
    visualstudio2015community,
    -packageParameters, '--AdminFile C:\vagrant\VisualStudioAdminDeploymentCustomizations.xml' `
    -SuccessExitCodes 0,-1,3010
