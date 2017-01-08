This is a [Vagrant](https://www.vagrantup.com/) Environment for [Visual Studio Community 2015](https://www.visualstudio.com/vs/community/).


# Usage

Build the base image with:

```bash
git clone https://github.com/joefitzgerald/packer-windows
cd packer-windows
# this will take ages so leave it running over night...
packer build windows_2012_r2.json
vagrant box add windows_2012_r2 windows_2012_r2_virtualbox.box
cd ..
```

Install the needed plugins:

```bash
vagrant plugin install vagrant-reload # https://github.com/aidanns/vagrant-reload 
```

Then start this environment:

```bash
vagrant up
``` 


# Installed Software

This environment also contains:

* [7-Zip](http://www.7-zip.org/)
* [BareTail](https://www.baremetalsoft.com/baretail/)
* [Chocolatey](https://chocolatey.org/)
* [Classic Shell (Windows Start Menu replacement)](http://www.classicshell.net/)
* [ConEmu (terminal)](https://conemu.github.io/)
* [de4dot (.NET deobfuscator and unpacker)](https://github.com/0xd4d/de4dot)
* [Dependency Walker (troubleshoot system errors related to loading and executing modules or applications)](http://www.dependencywalker.com/)
* [dnSpy (.NET assembly editor, decompiler, and debugger)](https://github.com/0xd4d/dnSpy)
* [Fiddler (web debugging proxy)](http://www.telerik.com/fiddler)
* [Git Extensions](https://gitextensions.github.io/)
* [Git](https://git-for-windows.github.io/)
* [Google Chrome](https://www.google.com/chrome/)
* [Meld (visual diff and merge tool)](http://meldmerge.org/)
* [MSYS2 (shell environment; cygwin based)](http://msys2.github.io/)
* [Notepad2 (notepad replacement)](http://www.flos-freeware.ch/notepad2.html)
* [Process Explorer](https://technet.microsoft.com/en-us/sysinternals/processexplorer.aspx)
* [Process Hacker](https://github.com/processhacker2/processhacker2)
* [Process Monitor](https://technet.microsoft.com/en-us/sysinternals/processmonitor.aspx)
* [ReSharper](https://www.jetbrains.com/resharper/)
* [Visual Studio Code](https://code.visualstudio.com/)
* [VSColorOutput (colors the Visual Studio Output pane text)](https://www.visualstudiogallery.msdn.microsoft.com/f4d9c2b5-d6d7-4543-a7a5-2d7ebabc2496)
