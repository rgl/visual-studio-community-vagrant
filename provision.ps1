# define the Install-Application function that downloads and unzips an application.
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Install-Application($name, $url, $expectedHash, $expectedHashAlgorithm = 'SHA256') {
    $localZipPath = "$env:TEMP\$name.zip"
    Invoke-WebRequest $url -OutFile $localZipPath
    $actualHash = (Get-FileHash $localZipPath -Algorithm $expectedHashAlgorithm).Hash
    if ($actualHash -ne $expectedHash) {
        throw "$name downloaded from $url to $localZipPath has $actualHash hash that does not match the expected $expectedHash"
    }
    $destinationPath = Join-Path $env:ProgramFiles $name
    [IO.Compression.ZipFile]::ExtractToDirectory($localZipPath, $destinationPath)
}

# set keyboard layout.
# NB you can get the name from the list:
#      [Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures') | Out-GridView
Set-WinUserLanguageList pt-PT -Force

# set the date format, number format, etc.
Set-Culture pt-PT

# set the welcome screen culture and keyboard layout.
# NB the .DEFAULT key is for the local SYSTEM account (S-1-5-18).
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
'Control Panel\International','Keyboard Layout' | ForEach-Object {
    Remove-Item -Path "HKU:.DEFAULT\$_" -Recurse -Force
    Copy-Item -Path "HKCU:$_" -Destination "HKU:.DEFAULT\$_" -Recurse -Force
}

# set the timezone.
# tzutil /l lists all available timezone ids
& $env:windir\system32\tzutil /s "GMT Standard Time"

# show window content while dragging.
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name DragFullWindows -Value 1

# show hidden files.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Hidden -Value 1

# show protected operating system files.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowSuperHidden -Value 1

# show file extensions.
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0

# display full path in the title bar.
New-Item -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState -Force `
    | New-ItemProperty -Name FullPath -Value 1 -PropertyType DWORD `
    | Out-Null

# set desktop background.
Copy-Item C:\vagrant\vs.png C:\Windows\Web\Wallpaper\Windows
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name Wallpaper -Value C:\Windows\Web\Wallpaper\Windows\vs.png
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name WallpaperStyle -Value 0
Set-ItemProperty -Path 'HKCU:Control Panel\Desktop' -Name TileWallpaper -Value 0
Set-ItemProperty -Path 'HKCU:Control Panel\Colors' -Name Background -Value '30 30 30'

# set lock screen background.
Copy-Item C:\vagrant\vs.png C:\Windows\Web\Screen
New-Item -Path HKLM:Software\Policies\Microsoft\Windows\Personalization -Force `
    | New-ItemProperty -Name LockScreenImage -Value C:\Windows\Web\Screen\vs.png `
    | New-ItemProperty -Name PersonalColors_Background -Value '#1e1e1e' `
    | New-ItemProperty -Name PersonalColors_Accent -Value '#007acc' `
    | Out-Null

# set account picture.
$accountSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$accountPictureBasePath = "C:\Users\Public\AccountPictures\$accountSid"
$accountRegistryKeyPath = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\$accountSid"
mkdir $accountPictureBasePath | Out-Null
New-Item $accountRegistryKeyPath | Out-Null
# NB we are resizing the same image for all the resolutions, but for better
#    results, you should use images with different resolutions.
Add-Type -AssemblyName System.Drawing
$accountImage = [System.Drawing.Image]::FromFile("c:\vagrant\vagrant.png")
32,40,48,96,192,240,448 | ForEach-Object {
    $p = "$accountPictureBasePath\Image$($_).jpg"
    $i = New-Object System.Drawing.Bitmap($_, $_)
    $g = [System.Drawing.Graphics]::FromImage($i)
    $g.DrawImage($accountImage, 0, 0, $_, $_)
    $i.Save($p)
    New-ItemProperty -Path $accountRegistryKeyPath -Name "Image$_" -Value $p -Force | Out-Null
}

# enable audio.
Set-Service Audiosrv -StartupType Automatic
Start-Service Audiosrv

# install classic shell.
New-Item -Path HKCU:Software\IvoSoft\ClassicStartMenu -Force `
    | New-ItemProperty -Name ShowedStyle2      -Value 1 -PropertyType DWORD `
    | Out-Null
New-Item -Path HKCU:Software\IvoSoft\ClassicStartMenu\Settings -Force `
    | New-ItemProperty -Name EnableStartButton -Value 1 -PropertyType DWORD `
    | New-ItemProperty -Name SkipMetro         -Value 1 -PropertyType DWORD `
    | Out-Null
choco install -y classic-shell -installArgs ADDLOCAL=ClassicStartMenu

# install Google Chrome.
# see https://www.chromium.org/administrators/configuring-other-preferences
choco install -y googlechrome
$chromeLocation = 'C:\Program Files (x86)\Google\Chrome\Application'
cp -Force GoogleChrome-external_extensions.json (Get-Item "$chromeLocation\*\default_apps\external_extensions.json").FullName
cp -Force GoogleChrome-master_preferences.json "$chromeLocation\master_preferences"
cp -Force GoogleChrome-master_bookmarks.html "$chromeLocation\master_bookmarks.html"

# replace notepad with notepad2.
choco install -y notepad2

# install other useful applications and dependencies.
choco install -y baretail
choco install -y dependencywalker
choco install -y autoruns
choco install -y processhacker
choco install -y procexp
choco install -y procmon
choco install -y winobj
choco install -y 7zip
choco install -y git --params '/GitOnlyOnPath /NoAutoCrlf'
choco install -y gitextensions
choco install -y meld
choco install -y visualstudiocode

# install fiddler.
(New-Object Net.WebClient).DownloadFile(
    'https://telerik-fiddler.s3.amazonaws.com/fiddler/FiddlerSetup.exe',
    "$env:TEMP\FiddlerSetup.exe")
&"$env:TEMP\FiddlerSetup.exe" /S | Out-String -Stream

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# configure git.
# see http://stackoverflow.com/a/12492094/477532
git config --global user.name 'Rui Lopes'
git config --global user.email 'rgl@ruilopes.com'
git config --global push.default simple
git config --global core.autocrlf false
git config --global diff.guitool meld
git config --global difftool.meld.path 'C:/Program Files (x86)/Meld/Meld.exe'
git config --global difftool.meld.cmd '\"C:/Program Files (x86)/Meld/Meld.exe\" \"$LOCAL\" \"$REMOTE\"'
git config --global merge.tool meld
git config --global mergetool.meld.path 'C:/Program Files (x86)/Meld/Meld.exe'
git config --global mergetool.meld.cmd '\"C:/Program Files (x86)/Meld/Meld.exe\" \"$LOCAL\" \"$BASE\" \"$REMOTE\" --auto-merge --output \"$MERGED\"'
#git config --list --show-origin

# install .NET decompiler and deofuscator.
# see https://github.com/0xd4d/dnSpy/releases
# see https://ci.appveyor.com/project/0xd4d/dnspy/build/x.x.522
Install-Application `
    dnSpy `
    https://ci.appveyor.com/api/buildjobs/1t9qhmutda8jqvng/artifacts/dnSpy%2FdnSpy%2Fbin%2FdnSpy.zip `
    3c08a1c948caf3b82c41f346e68e1e073ea963d17d6f5a2b4cf932b2f3fed892
Install-BinFile dnSpy 'C:\Program Files\dnSpy\dnSpy.exe'
# see https://github.com/0xd4d/de4dot
# see https://ci.appveyor.com/project/0xd4d/de4dot/build/x.x.16
Install-Application `
    de4dot `
    https://ci.appveyor.com/api/buildjobs/v4o57dpf47po2vaw/artifacts/de4dot.zip `
    8e97e76da12711b92e19019ceb34a9c78d44b96dc8afd37f7dca99e49fae7cec
Install-BinFile de4dot 'C:\Program Files\de4dot\de4dot.exe'

# install msys2.
# NB we have to manually build the msys2 package from source because the
#    current chocolatey package is somewhat brittle to install.
Push-Location $env:TEMP
$p = Start-Process git clone,https://github.com/rgl/choco-packages -PassThru -Wait
if ($p.ExitCode) {
    throw "git failed with exit code $($p.ExitCode)"
}
cd choco-packages/msys2
choco pack
choco install -y msys2 -Source $PWD
Pop-Location

# configure the msys2 launcher to let the shell inherith the PATH.
$msys2BasePath = 'C:\tools\msys64'
$msys2ConfigPath = "$msys2BasePath\msys2.ini"
[IO.File]::WriteAllText(
    $msys2ConfigPath,
    ([IO.File]::ReadAllText($msys2ConfigPath) `
        -replace '#?(MSYS2_PATH_TYPE=).+','$1inherit')
)

# define a function for easying the execution of bash scripts.
$bashPath = "$msys2BasePath\usr\bin\bash.exe"
function Bash($script) {
    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        # we also redirect the stderr to stdout because PowerShell
        # oddly interleaves them.
        # see https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin
        echo 'exec 2>&1;set -eu;export PATH="/usr/bin:$PATH";export HOME=$USERPROFILE;' $script | &$bashPath
        if ($LASTEXITCODE) {
            throw "bash execution failed with exit code $LASTEXITCODE"
        }
    } finally {
        $ErrorActionPreference = $eap
    }
}

# install the remaining dependencies.
Bash 'pacman --noconfirm -Sy make zip unzip tar dos2unix'

# configure the shell.
Bash @'
pacman --noconfirm -Sy vim

cat>~/.bash_history<<"EOF"
EOF

cat>~/.bashrc<<"EOF"
# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

export EDITOR=vim
export PAGER=less

alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

cat>~/.inputrc<<"EOF"
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOD": backward-word
"\eOC": forward-word
set show-all-if-ambiguous on
set completion-ignore-case on
EOF

cat>~/.vimrc<<"EOF"
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup

autocmd BufNewFile,BufRead Vagrantfile set ft=ruby
autocmd BufNewFile,BufRead *.config set ft=xml

" Usefull setting for working with Ruby files.
autocmd FileType ruby set tabstop=2 shiftwidth=2 smarttab expandtab softtabstop=2 autoindent
autocmd FileType ruby set smartindent cinwords=if,elsif,else,for,while,try,rescue,ensure,def,class,module

" Usefull setting for working with Python files.
autocmd FileType python set tabstop=4 shiftwidth=4 smarttab expandtab softtabstop=4 autoindent
" Automatically indent a line that starts with the following words (after we press ENTER).
autocmd FileType python set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class

" Usefull setting for working with Go files.
autocmd FileType go set tabstop=4 shiftwidth=4 smarttab expandtab softtabstop=4 autoindent
" Automatically indent a line that starts with the following words (after we press ENTER).
autocmd FileType go set smartindent cinwords=if,else,switch,for,func
EOF
'@

# install useful tools.
Bash 'pacman --noconfirm -Sy netcat'

# install mingw gcc.
Bash @'
pacman --noconfirm -Sy mingw-w64-x86_64-gcc

cat>>~/.bashrc<<'EOF'

export PATH="/mingw64/bin:$PATH"
EOF

/mingw64/bin/gcc --version
'@

# install ConEmu.
choco install -y conemu
cp ConEmu.xml $env:APPDATA\ConEmu.xml
reg import ConEmu.reg
