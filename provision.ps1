# define the process privilege manipulation function.
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.ComponentModel;

public class ProcessPrivileges
{
    [DllImport("advapi32.dll", SetLastError = true)]
    static extern bool LookupPrivilegeValue(string host, string name, ref long luid);

    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    static extern bool AdjustTokenPrivileges(IntPtr token, bool disableAllPrivileges, ref TOKEN_PRIVILEGES newState, int bufferLength, IntPtr previousState, IntPtr returnLength);

    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    static extern bool OpenProcessToken(IntPtr processHandle, int desiredAccess, ref IntPtr processToken);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool CloseHandle(IntPtr handle);

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    struct TOKEN_PRIVILEGES
    {
        public int PrivilegeCount;
        public long Luid;
        public int Attributes;
    }

    const int SE_PRIVILEGE_ENABLED     = 0x00000002;
    const int SE_PRIVILEGE_DISABLED    = 0x00000000;

    const int TOKEN_QUERY              = 0x00000008;
    const int TOKEN_ADJUST_PRIVILEGES  = 0x00000020;

    public static void EnablePrivilege(IntPtr processHandle, string privilegeName, bool enable)
    {
        var processToken = IntPtr.Zero;

        if (!OpenProcessToken(processHandle, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref processToken))
        {
            throw new Win32Exception();
        }

        try
        {
            var privileges = new TOKEN_PRIVILEGES
            {
                PrivilegeCount = 1,
                Luid = 0,
                Attributes = enable ? SE_PRIVILEGE_ENABLED : SE_PRIVILEGE_DISABLED,
            };
            
            if (!LookupPrivilegeValue(null, privilegeName, ref privileges.Luid))
            {
                throw new Win32Exception();
            }

            if (!AdjustTokenPrivileges(processToken, false, ref privileges, 0, IntPtr.Zero, IntPtr.Zero))
            {
                throw new Win32Exception();
            }
        }
        finally
        {
            CloseHandle(processToken);
        }
    }
}
'@
function Enable-ProcessPrivilege {
    param(
        # see https://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx
        [string]$privilegeName,
        [int]$processId = $PID,
        [Switch][bool]$disable
    )
    $process = Get-Process -Id $processId
    try {
        [ProcessPrivileges]::EnablePrivilege(
            $process.Handle,
            $privilegeName,
            !$disable)
    } finally {
        $process.Close()
    }
}

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

# set the user lock screen culture.
Enable-ProcessPrivilege SeTakeOwnershipPrivilege
$accountSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$accountLocaleRegistryKeyName = "SOFTWARE\Microsoft\Windows\CurrentVersion\SystemProtectedUserData\$accountSid\AnyoneRead\LocaleInfo"
$key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($accountLocaleRegistryKeyName, 'ReadWriteSubTree', 'TakeOwnership')
$acl = $key.GetAccessControl('None')
$acl.SetOwner([Security.Principal.NTAccount]'Administrators')
$key.SetAccessControl($acl)
Enable-ProcessPrivilege SeTakeOwnershipPrivilege -Disable
$acl = $key.GetAccessControl()
$acl.SetAccessRule((New-Object Security.AccessControl.RegistryAccessRule('Administrators', 'FullControl', 'ContainerInherit', 'None', 'Allow')))
$key.SetAccessControl($acl)
$key.Close()
Set-ItemProperty `
    -Path "HKLM:$accountLocaleRegistryKeyName" `
    -Name Language `
    -Value (Get-ItemProperty -Path 'HKCU:Control Panel\International' -Name LocaleName).LocaleName
Set-ItemProperty `
    -Path "HKLM:$accountLocaleRegistryKeyName" `
    -Name LocaleName `
    -Value (Get-ItemProperty -Path 'HKCU:Control Panel\International' -Name LocaleName).LocaleName
Set-ItemProperty `
    -Path "HKLM:$accountLocaleRegistryKeyName" `
    -Name TimeFormat `
    -Value (Get-ItemProperty -Path 'HKCU:Control Panel\International' -Name sShortTime).sShortTime

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

# never combine the taskbar buttons.
#
# possibe values:
#   0: always combine and hide labels (default)
#   1: combine when taskbar is full
#   2: never combine
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarGlomLevel -Value 2

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
$accountRegistryKey = "SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\$accountSid"
$accountRegistryKeyPath = "HKLM:$accountRegistryKey"
# see https://powertoe.wordpress.com/2010/08/28/controlling-registry-acl-permissions-with-powershell/
$key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
    "SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\$accountSid",
    'ReadWriteSubTree',
    'ChangePermissions')
$acl = $key.GetAccessControl()
$acl.SetAccessRule((New-Object Security.AccessControl.RegistryAccessRule('Administrators', 'FullControl', 'Allow')))
$key.SetAccessControl($acl)
mkdir $accountPictureBasePath | Out-Null
$accountPicturePath = "$accountPictureBasePath\vagrant.png"
Copy-Item -Force C:\vagrant\vagrant.png $accountPicturePath
# NB we are using the same image for all the resolutions, but for better
#    results, you should use images with different resolutions.
40,96,200,240,448 | ForEach-Object {
    New-ItemProperty -Path $accountRegistryKeyPath -Name "Image$_" -Value $accountPicturePath -Force | Out-Null
}

# install classic shell.
New-Item -Path HKCU:Software\IvoSoft\ClassicStartMenu -Force `
    | New-ItemProperty -Name ShowedStyle2      -Value 1 -PropertyType DWORD `
    | Out-Null
New-Item -Path HKCU:Software\IvoSoft\ClassicStartMenu\Settings -Force `
    | New-ItemProperty -Name EnableStartButton -Value 1 -PropertyType DWORD `
    | New-ItemProperty -Name SkipMetro         -Value 1 -PropertyType DWORD `
    | Out-Null
choco install -y classic-shell --allow-empty-checksums -installArgs ADDLOCAL=ClassicStartMenu

# install Google Chrome and some useful extensions.
# see https://developer.chrome.com/extensions/external_extensions
choco install -y googlechrome
@(
    # JSON Formatter (https://chrome.google.com/webstore/detail/json-formatter/bcjindcccaagfpapjjmafapmmgkkhgoa).
    'bcjindcccaagfpapjjmafapmmgkkhgoa'
    # uBlock Origin (https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm).
    'cjpalhdlnbpafiamejdnhcphjbkeiagm'
) | ForEach-Object {
    New-Item -Force -Path "HKLM:Software\Wow6432Node\Google\Chrome\Extensions\$_" `
        | Set-ItemProperty -Name update_url -Value 'https://clients2.google.com/service/update2/crx'
}

# replace notepad with notepad2.
choco install -y notepad2

# install other useful applications and dependencies.
choco install -y baretail
choco install -y --allow-empty-checksums dependencywalker
choco install -y procexp
choco install -y procmon
choco install -y fiddler4
choco install -y 7zip
choco install -y git --params '/GitOnlyOnPath /NoAutoCrlf'
choco install -y gitextensions
choco install -y meld
choco install -y visualstudiocode

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# configure git.
# see http://stackoverflow.com/a/12492094/477532
git config --global user.name 'Rui Lopes'
git config --global user.email 'rgl@ruilopes.com'
git config --global push.default simple
git config --global diff.guitool meld
git config --global difftool.meld.path 'C:/Program Files (x86)/Meld/Meld.exe'
git config --global difftool.meld.cmd '\"C:/Program Files (x86)/Meld/Meld.exe\" \"$LOCAL\" \"$REMOTE\"'
git config --global merge.tool meld
git config --global mergetool.meld.path 'C:/Program Files (x86)/Meld/Meld.exe'
git config --global mergetool.meld.cmd '\"C:/Program Files (x86)/Meld/Meld.exe\" --diff \"$LOCAL\" \"$BASE\" \"$REMOTE\" --output \"$MERGED\"'
#git config --list --show-origin

# install .NET decompiler and deofuscator.
Install-Application `
    dnSpy `
    https://github.com/0xd4d/dnSpy/releases/download/v3.0.0/dnSpy.zip `
    cdc52610c8445d39db7ee93e29de6ded53c0a1f9c0d92f86263478cbe85b3a51
Install-BinFile de4dot 'C:\Program Files\dnSpy\dnSpy.exe'
Install-Application `
    de4dot `
    https://ci.appveyor.com/api/buildjobs/inku0l04uplh1d1r/artifacts/de4dot.zip `
    547fec992f1e77caf35849fad2919a6bf8bc02163940c596c4ad0597272a224e
Install-BinFile de4dot 'C:\Program Files\de4dot\de4dot.exe'

# install msys2.
choco install -y msys2

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
        echo 'exec 2>&1;set -eu;export PATH="/usr/bin:$PATH"' $script | &$bashPath
        if ($LASTEXITCODE) {
            throw "bash execution failed with exit code $LASTEXITCODE"
        }
    } finally {
        $ErrorActionPreference = $eap
    }
}

# install the remaining dependencies.
Bash 'pacman --noconfirm -Sy make unzip tar dos2unix'

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

# remove the default desktop shortcuts.
del C:\Users\Public\Desktop\*.lnk

# add MSYS2 shortcut to the Desktop and Start Menu.
Install-ChocolateyShortcut `
  -ShortcutFilePath "$env:USERPROFILE\Desktop\MSYS2 Bash.lnk" `
  -TargetPath "$msys2BasePath\msys2.exe"
Install-ChocolateyShortcut `
  -ShortcutFilePath "C:\Users\All Users\Microsoft\Windows\Start Menu\Programs\MSYS2 Bash.lnk" `
  -TargetPath "$msys2BasePath\msys2.exe"

# add Services shortcut to the Desktop.
Install-ChocolateyShortcut `
  -ShortcutFilePath "$env:USERPROFILE\Desktop\Services.lnk" `
  -TargetPath "$env:windir\system32\services.msc" `
  -Description 'Windows Services'

# install the huge KB2919355 (needed by Visual Studio Community 2015).
# NB will return 3010 as a flag to let us known to reboot the machine.
Start-Choco install,-y,kb2919355 -SuccessExitCodes 0,3010
