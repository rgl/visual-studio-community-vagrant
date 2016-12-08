
# install the huge KB2919355 (needed by Visual Studio).
# NB will return 3010 as a flag to let us known to reboot the machine.
Start-Choco install,-y,kb2919355 -SuccessExitCodes 0,3010
