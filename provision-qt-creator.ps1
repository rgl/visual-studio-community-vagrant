# see http://doc.qt.io/qtcreator/
# see https://download.qt.io/archive/online_installers/

$archiveUrl = 'https://download.qt.io/archive/online_installers/3.0/qt-unified-windows-x86-3.0.5-online.exe'
$archiveHash = '93f0fc89c345b5663477b932037c28c3a9a3456a907b088dbce5bd2815710b9f'
$archiveName = Split-Path $archiveUrl -Leaf
$archivePath = "$env:TEMP\$archiveName"
Write-Host 'Downloading the Qt Creator Installer...'
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA256).Hash
if ($archiveHash -ne $archiveActualHash) {
    throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
}
Write-Host 'Installing Qt Creator...'
@'
// see http://doc.qt.io/qtinstallerframework/
// see http://doc.qt.io/qtinstallerframework/noninteractive.html
// see http://doc.qt.io/qtinstallerframework/scripting-qmlmodule.html

function Controller() {
    console.log("Initializing the Controller...");
    installer.autoRejectMessageBoxes();
    installer.installationFinished.connect(function() {
        console.log("On installationFinished...");
        gui.clickButton(buttons.NextButton);
    });
}

Controller.prototype.WelcomePageCallback = function() {
    console.log("On WelcomePageCallback...");
    // NB we must add a delay because the next button is not immediately enabled.
    gui.clickButton(buttons.NextButton, 2000);
};

Controller.prototype.CredentialsPageCallback = function() {
    console.log("On CredentialsPageCallback...");
    gui.clickButton(buttons.NextButton);
};

Controller.prototype.IntroductionPageCallback = function() {
    console.log("On IntroductionPageCallback...");
    gui.clickButton(buttons.NextButton);
    console.log("Retrieving meta information from remote repository...");
};

Controller.prototype.TargetDirectoryPageCallback = function() {
    console.log("On TargetDirectoryPageCallback...");
    // NB the target directory cannot contain spaces.
    gui.currentPageWidget().TargetDirectoryLineEdit.setText("C:\\Qt5101");
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.ComponentSelectionPageCallback = function() {
    console.log("On ComponentSelectionPageCallback...");
    var widget = gui.currentPageWidget();
    widget.deselectAll();
    widget.selectComponent("qt.qt5.5101.win64_msvc2017_64");
    gui.clickButton(buttons.NextButton);
};

Controller.prototype.LicenseAgreementPageCallback = function() {
    console.log("On LicenseAgreementPageCallback...");
    gui.currentPageWidget().AcceptLicenseRadioButton.checked = true;
    gui.clickButton(buttons.NextButton);
};

Controller.prototype.StartMenuDirectoryPageCallback = function() {
    console.log("On StartMenuDirectoryPageCallback...");
    gui.currentPageWidget().StartMenuPathLineEdit.setText("Qt5101");
    gui.clickButton(buttons.NextButton);
};

Controller.prototype.ReadyForInstallationPageCallback = function() {
    console.log("On ReadyForInstallationPageCallback...");
    gui.clickButton(buttons.NextButton);
};

Controller.prototype.PerformInstallationPageCallback = function() {
    console.log("On PerformInstallationPageCallback...");
    gui.clickButton(buttons.NextButton);
};

Controller.prototype.FinishedPageCallback = function() {
    console.log("On FinishedPageCallback...");
    gui.currentPageWidget().LaunchQtCreatorCheckBoxForm.launchQtCreatorCheckBox.checked = false;
    gui.clickButton(buttons.FinishButton);
};
'@ | Out-File -Encoding ascii "$env:TEMP\qt-creator.qs"
&$archivePath --version | Out-String -Stream
&$archivePath --verbose --script "$env:TEMP\qt-creator.qs" | Out-String -Stream
if ($LASTEXITCODE) {
    throw "Failed to install Qt Creator with Exit Code $LASTEXITCODE"
}
