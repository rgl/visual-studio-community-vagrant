This is a [Vagrant](https://www.vagrantup.com/) Environment for [Visual Studio Community 2015](https://www.visualstudio.com/vs/community/).

This also installs the following:

* [Classic Shell (Windows Start Menu replacement)](http://www.classicshell.net/)
* [Dependency Walker (troubleshoot system errors related to loading and executing modules or applications)](http://www.dependencywalker.com/)
* [dnSpy (.NET assembly editor, decompiler, and debugger)](https://github.com/0xd4d/dnSpy)
* [de4dot (.NET deobfuscator and unpacker)](https://github.com/0xd4d/de4dot)
* [Fiddler (web debugging proxy)](http://www.telerik.com/fiddler)
* [Git](https://git-for-windows.github.io/)
* [Git Extensions](https://gitextensions.github.io/)
* [Meld (visual diff and merge tool)](http://meldmerge.org/)
* [MSYS2](http://msys2.github.io/)
* [Process Explorer](https://technet.microsoft.com/en-us/sysinternals/processexplorer.aspx)
* [Process Monitor](https://technet.microsoft.com/en-us/sysinternals/processmonitor.aspx)
* [Google Chrome](https://www.google.com/chrome/)
* [ReSharper](https://www.jetbrains.com/resharper/)


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
