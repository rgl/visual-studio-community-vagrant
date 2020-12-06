# cleanup the taskbar by removing the existing buttons and unpinning all applications; once the user logs on.
# NB the shell executes these RunOnce commands about ~10s after the user logs on.
[IO.File]::WriteAllText(
    "C:\tmp\ConfigureTaskbar.ps1",
@'
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1

# unpin all applications.
# NB this can only be done in a logged on session.
$pinnedTaskbarPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
(New-Object -Com Shell.Application).NameSpace($pinnedTaskbarPath).Items() `
    | ForEach-Object {
        $unpinVerb = $_.Verbs() | Where-Object { $_.Name -eq 'Unpin from tas&kbar' }
        if ($unpinVerb) {
            $unpinVerb.DoIt()
        } else {
            $shortcut = (New-Object -Com WScript.Shell).CreateShortcut($_.Path)
            if (!$shortcut.TargetPath -and ($shortcut.IconLocation -eq '%windir%\explorer.exe,0')) {
                Remove-Item -Force $_.Path
            }
        }
    }
Get-Item HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband `
    | Set-ItemProperty -Name Favorites -Value 0xff `
    | Set-ItemProperty -Name FavoritesResolve -Value 0xff `
    | Set-ItemProperty -Name FavoritesVersion -Value 3 `
    | Set-ItemProperty -Name FavoritesChanges -Value 1 `
    | Set-ItemProperty -Name FavoritesRemovedChanges -Value 1

# hide the search button.
Set-ItemProperty -Path HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 0

# hide the task view button.
Set-ItemProperty -Path HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowTaskViewButton -Value 0

# never combine the taskbar buttons.
# possibe values:
#   0: always combine and hide labels (default)
#   1: combine when taskbar is full
#   2: never combine
Set-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarGlomLevel -Value 2

# remove the default desktop shortcuts.
del C:\Users\*\Desktop\*.lnk
del -Force C:\Users\*\Desktop\*.ini

# add desktop shortcuts.
@(
    ,('Autoruns',              'C:\ProgramData\chocolatey\lib\AutoRuns\tools\AutoRuns.exe')
    ,('Dependencies',          'C:\ProgramData\chocolatey\lib\dependencies\tools\DependenciesGui.exe')
    ,('Dependency Walker',     'C:\ProgramData\chocolatey\lib\dependencywalker\content\depends.exe')
    ,('dnSpy',                 'C:\Program Files\dnSpy\dnSpy.exe')
    ,('Fiddler',               'C:\Users\vagrant\AppData\Local\Programs\Fiddler\Fiddler.exe')
    ,('MSYS2 Bash',            'C:\Program Files\ConEmu\ConEmu64.exe', '-icon C:\tools\msys64\msys2.ico -run {MSYS2}', 'C:\tools\msys64\msys2.ico', '%USERPROFILE%')
    ,('Portainer',             'http://localhost:9000')
    ,('Process Explorer',      'C:\ProgramData\chocolatey\lib\procexp\tools\procexp64.exe')
    ,('Process Hacker',        'C:\Program Files\Process Hacker 2\ProcessHacker.exe')
    ,('Process Monitor',       'C:\ProgramData\chocolatey\lib\procmon\tools\Procmon.exe')
    ,('Qt Creator',            'C:\Qt5101\Tools\QtCreator\bin\qtcreator.exe')
    ,('Ubuntu 20.04',          'C:\Users\All Users\Microsoft\Windows\Start Menu\Programs\Ubuntu 20.04.lnk')
    ,('Visual Studio Code',    'C:\Program Files\Microsoft VS Code\Code.exe')
    ,('Visual Studio',         'C:\VisualStudio2019Community\Common7\IDE\devenv.exe')
    ,('WinObj',                'C:\ProgramData\chocolatey\lib\winobj\tools\Winobj.exe')
) | ForEach-Object {
    if (!(Test-Path $_[1])) {
        return
    }
    if ($_[1] -like 'http*') {
        [IO.File]::WriteAllText("$env:USERPROFILE\Desktop\$($_[0]).url", @"
[InternetShortcut]
URL=$_[1]
"@)
    } elseif ($_[1] -like '*.lnk') {
        Copy-Item $_[1] "$env:USERPROFILE\Desktop\$($_[0]).lnk"
    } else {
        $extraArguments = @{
            IconLocation = $_[1]
        }
        if ($_.Length -gt 2) {
            $extraArguments.Arguments = $_[2]
            $extraArguments.IconLocation = $_[3]
            $extraArguments.WorkingDirectory = $_[4]
        }
        # add into the Desktop.
        Install-ChocolateyShortcut `
            -ShortcutFilePath "$env:USERPROFILE\Desktop\$($_[0]).lnk" `
            -TargetPath $_[1] `
            @extraArguments
        # add into the Start Menu.
        Copy-Item `
            "$env:USERPROFILE\Desktop\$($_[0]).lnk" `
            "C:\Users\All Users\Microsoft\Windows\Start Menu\Programs"
    }
}

# set windows terminal settings.
$settingsPath = "$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
mkdir -Force (Split-Path -Parent $settingsPath) | Out-Null
cp windows-terminal-settings.json $settingsPath

# restart explorer to apply the changed settings.
(Get-Process explorer).Kill()
'@)
New-Item -Path HKCU:Software\Microsoft\Windows\CurrentVersion\RunOnce -Force `
    | New-ItemProperty -Name ConfigureTaskbar -Value 'PowerShell -WindowStyle Hidden -File "C:\tmp\ConfigureTaskbar.ps1"' -PropertyType ExpandString `
    | Out-Null
