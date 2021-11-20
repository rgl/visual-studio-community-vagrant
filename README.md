This is a [Vagrant](https://www.vagrantup.com/) Environment for [Visual Studio Community 2022](https://www.visualstudio.com/vs/community/).


# Usage

Install the [Windows 2022 21H2 or the Windows 10 2004 Base Box](https://github.com/rgl/windows-vagrant).

Set the Base Box in the [Vagrantfile](Vagrantfile) file.

Start this environment:

```bash
make libvirt-up # or virtualbox-up
```

To troubleshoot see the `vagrant.log` file.


# Installed Software

This environment also contains:

* [7-Zip](http://www.7-zip.org/)
* [Autoruns](https://docs.microsoft.com/en-us/sysinternals/downloads/autoruns)
* [BareTail](https://www.baremetalsoft.com/baretail/)
* [Chocolatey](https://chocolatey.org/)
* [de4dot (.NET deobfuscator and unpacker)](https://github.com/0xd4d/de4dot)
* [Dependencies (troubleshoot system errors related to loading and executing modules or applications)](https://github.com/lucasg/Dependencies)
* [Dependency Walker (troubleshoot system errors related to loading and executing modules or applications)](http://www.dependencywalker.com/)
* [dnSpy (.NET assembly editor, decompiler, and debugger)](https://github.com/0xd4d/dnSpy)
* [Docker Engine CE (default) or Docker Engine EE (you need to uncomment it from the `Vagrantfile`) for Windows containers](https://www.docker.com/products/docker-engine)
* [docker-reg](https://github.com/genuinetools/reg)
* [Fiddler (web debugging proxy)](http://www.telerik.com/fiddler)
* [Git Extensions](https://gitextensions.github.io/)
* [Git](https://git-for-windows.github.io/)
* [Google Chrome](https://www.google.com/chrome/)
* [Meld (visual diff and merge tool)](http://meldmerge.org/)
* [MSYS2 (shell environment; cygwin based)](http://msys2.github.io/)
* [Notepad2 (notepad replacement)](http://www.flos-freeware.ch/notepad2.html)
* [Portainer](https://github.com/portainer/portainer)
* [Process Explorer](https://docs.microsoft.com/en-us/sysinternals/downloads/process-explorer)
* [Process Hacker](https://github.com/processhacker2/processhacker2)
* [Process Monitor](https://docs.microsoft.com/en-us/sysinternals/downloads/procmon)
* [Qt Creator](http://doc.qt.io/qtcreator/)
* [SetDefaultBrowser](https://kolbi.cz/blog/2017/11/10/setdefaultbrowser-set-the-default-browser-per-user-on-windows-10-and-server-2016-build-1607/)
* [Ubuntu (Running on the Windows Subsystem for Linux (WSL))](https://docs.microsoft.com/en-us/windows/wsl)
* [Visual Studio Code](https://code.visualstudio.com/)
* [Windows Driver Kit (WDK)](https://docs.microsoft.com/en-us/windows-hardware/drivers/)
* [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/)
* [Windows Subsystem for Linux 2 (WSL2)](https://docs.microsoft.com/en-us/windows/wsl/)
  * Only installed in Windows 10 2004+ Client/Workstation.
  * Only works when running in a VM with nested virtualization enabled (e.g. in kvm).
* [Windows Terminal](https://github.com/microsoft/terminal)
  * Only installed in Windows 10 1903+.
* [WinObj](https://docs.microsoft.com/en-us/sysinternals/downloads/winobj)
