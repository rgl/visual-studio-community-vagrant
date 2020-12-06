# define the Install-Application function that downloads and unzips an application.
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Install-Application($name, $url, $expectedHash, $expectedHashAlgorithm = 'SHA256') {
    $localZipPath = "$env:TEMP\$name.zip"
    (New-Object Net.WebClient).DownloadFile($url, $localZipPath)
    $actualHash = (Get-FileHash $localZipPath -Algorithm $expectedHashAlgorithm).Hash
    if ($actualHash -ne $expectedHash) {
        throw "$name downloaded from $url to $localZipPath has $actualHash hash that does not match the expected $expectedHash"
    }
    $destinationPath = Join-Path $env:ProgramFiles $name
    [IO.Compression.ZipFile]::ExtractToDirectory($localZipPath, $destinationPath)
}

# disable cortana and web search.
New-Item -Path 'HKLM:SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Force `
    | New-ItemProperty -Name AllowCortana -Value 0 `
    | New-ItemProperty -Name ConnectedSearchUseWeb -Value 0 `
    | Out-Null

# set keyboard layout.
# NB you can get the name from the list:
#      [Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures') | Out-GridView
Set-WinUserLanguageList pt-PT -Force

# set the date format, number format, etc.
Set-Culture pt-PT

# set the welcome screen culture and keyboard layout.
# NB the .DEFAULT key is for the local SYSTEM account (S-1-5-18).
New-PSDrive HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
'Control Panel\International','Keyboard Layout' | ForEach-Object {
    Remove-Item -Path "HKU:.DEFAULT\$_" -Recurse -Force
    Copy-Item -Path "HKCU:$_" -Destination "HKU:.DEFAULT\$_" -Recurse -Force
}
Remove-PSDrive HKU

# set the timezone.
# use Get-TimeZone -ListAvailable to list the available timezone ids.
Set-TimeZone -Id 'GMT Standard Time'

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

# install Google Chrome.
# see https://www.chromium.org/administrators/configuring-other-preferences
choco install -y --ignore-checksums googlechrome
$chromeLocation = 'C:\Program Files\Google\Chrome\Application'
cp -Force GoogleChrome-external_extensions.json (Resolve-Path "$chromeLocation\*\default_apps\external_extensions.json")
cp -Force GoogleChrome-master_preferences.json "$chromeLocation\master_preferences"
cp -Force GoogleChrome-master_bookmarks.html "$chromeLocation\master_bookmarks.html"

# set the default browser.
choco install -y SetDefaultBrowser
SetDefaultBrowser HKLM "Google Chrome"

# replace notepad with notepad2.
choco install -y notepad2

# install other useful applications and dependencies.
# NB we ignore the sysinternals utilities checksums because they have no proper
#    versioning and can be updated at any time, which would break this
#    automatic installation.
choco install -y baretail
choco install -y dependencies
choco install -y dependencywalker
choco install -y processhacker
choco install -y --ignore-checksums autoruns    # sysinternals.
choco install -y --ignore-checksums procexp     # sysinternals.
choco install -y --ignore-checksums procmon     # sysinternals.
choco install -y --ignore-checksums winobj      # sysinternals.
choco install -y 7zip
choco install -y git --params '/GitOnlyOnPath /NoAutoCrlf /SChannel'
choco install -y gitextensions
choco install -y meld
choco install -y vscode
choco install -y python3
choco install -y golang
choco install -y jq
choco install -y fiddler

# import the gitlab-vagrant environment site https certificate into the local machine trust store.
if (Test-Path C:/vagrant/tmp/gitlab.example.com-crt.der) {
    Import-Certificate `
        -FilePath C:/vagrant/tmp/gitlab.example.com-crt.der `
        -CertStoreLocation Cert:/LocalMachine/Root
}

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# configure git.
# see http://stackoverflow.com/a/12492094/477532
git config --global user.name 'Rui Lopes'
git config --global user.email 'rgl@ruilopes.com'
git config --global http.sslbackend schannel
git config --global push.default simple
git config --global core.autocrlf false
git config --global core.longpaths true
git config --global diff.guitool meld
git config --global difftool.meld.path 'C:/Program Files (x86)/Meld/Meld.exe'
git config --global difftool.meld.cmd '\"C:/Program Files (x86)/Meld/Meld.exe\" \"$LOCAL\" \"$REMOTE\"'
git config --global merge.tool meld
git config --global mergetool.meld.path 'C:/Program Files (x86)/Meld/Meld.exe'
git config --global mergetool.meld.cmd '\"C:/Program Files (x86)/Meld/Meld.exe\" \"$LOCAL\" \"$BASE\" \"$REMOTE\" --auto-merge --output \"$MERGED\"'
#git config --list --show-origin

# configure Git Extensions.
function Set-GitExtensionsStringSetting($name, $value) {
    $settingsPath = "$env:APPDATA\GitExtensions\GitExtensions\GitExtensions.settings"
    [xml]$settingsDocument = Get-Content $settingsPath
    $node = $settingsDocument.SelectSingleNode("/dictionary/item[key/string[text()='$name']]")
    if (!$node) {
        $node = $settingsDocument.CreateElement('item')
        $node.InnerXml = "<key><string>$name</string></key><value><string/></value>"
        $settingsDocument.dictionary.AppendChild($node) | Out-Null
    }
    $node.value.string = $value
    $settingsDocument.Save($settingsPath)
}
Set-GitExtensionsStringSetting TelemetryEnabled 'False'
Set-GitExtensionsStringSetting translation 'English'
Set-GitExtensionsStringSetting gitbindir 'C:\Program Files\Git\bin\'

# install vscode extensions.
@(
    'hookyqr.beautify'
    'dotjoshjohnson.xml'
    'docsmsft.docs-authoring-pack'
    'ms-vscode.powershell'
    'ms-vscode.csharp'
    'golang.go'
    'ms-python.python'
    'mauve.terraform'
    'ms-azuretools.vscode-docker'
    'zamerick.vscode-caddyfile-syntax'
) | ForEach-Object {
    code --install-extension $_
}

# install .NET decompiler and deofuscator.
# see https://github.com/rgl/dnSpy/releases
Install-Application `
    dnSpy `
    https://github.com/rgl/dnSpy/releases/download/v6.0.2/dnSpy.zip `
    3fb0db7d35f32006c7855fbdf69fbf793747707bbcf6dd5505ebe69b96067ec3
Install-BinFile dnSpy 'C:\Program Files\dnSpy\dnSpy.exe'
# see https://github.com/rgl/de4dot/releases
# see https://github.com/0xd4d/de4dot
# see https://ci.appveyor.com/project/0xd4d/de4dot/build/x.x.68
Install-Application `
    de4dot `
    https://github.com/rgl/de4dot/releases/download/vba8ee30e82a9dbc3c7fe5b7c7846ec9e03e6e23e/de4dot-net35.zip `
    e398e54a20d9a4aba71a23c40054059a97d0b4360f5e9dfb94ec402733746bea
Install-BinFile de4dot 'C:\Program Files\de4dot\de4dot.exe'

# install msys2.
choco install -y msys2 --params '/NoPath'

# configure the msys2 launcher to let the shell inherith the PATH.
$msys2BasePath = 'C:\tools\msys64'
Get-ChildItem "$msys2BasePath\*.ini" | ForEach-Object {
    [IO.File]::WriteAllText(
        $_,
        ([IO.File]::ReadAllText($_) `
            -replace '#?(MSYS2_PATH_TYPE=).+','$1inherit')
    )
}

# configure msys2 to mount C:\Users at /home.
[IO.File]::WriteAllText(
    "$msys2BasePath\etc\nsswitch.conf",
    ([IO.File]::ReadAllText("$msys2BasePath\etc\nsswitch.conf") `
        -replace '(db_home: ).+','$1windows')
)
Write-Output 'C:\Users /home' | Out-File -Encoding ASCII -Append "$msys2BasePath\etc\fstab"

# register msys2 bash in the windows explorer context menu.
reg import MSYS2-Bash-Here.reg

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

cat>~/.minttyrc<<"EOF"
Term=xterm-256color
Font=Consolas
FontHeight=10
EOF

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
Bash 'pacman --noconfirm -Sy netcat procps xorriso'
Bash 'pacman --noconfirm -Sy mingw-w64-x86_64-openldap' # ldap utilities (e.g. ldapsearch)

# install mingw gcc.
Bash @'
pacman --noconfirm -Sy mingw-w64-x86_64-gcc

/mingw64/bin/gcc --version
'@

# install the windows terminal.
# NB this needs Windows 18362+ (aka Windows 10 1903).
$windowsCurrentVersionKey = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$windowsBuildNumber = $windowsCurrentVersionKey.CurrentBuildNumber
if ($windowsBuildNumber -ge 18362) {
    choco install -y microsoft-windows-terminal
} else {
    Write-Host "WARN: windows terminal was skipped because you need Windows Build 18362+ (aka Windows 10 1903) and you are using Windows Build $windowsBuildNumber."
}
