Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'

trap {
    Write-Output "`nERROR: $_`n$($_.ScriptStackTrace)"
    Exit 1
}

# wrap the choco command (to make sure this script aborts when it fails).
function Start-Choco([string[]]$Arguments, [int[]]$SuccessExitCodes=@(0)) {
    &C:\ProgramData\chocolatey\bin\choco.exe @Arguments `
        | Where-Object { $_ -NotMatch '^Progress: ' }
    if ($SuccessExitCodes -NotContains $LASTEXITCODE) {
        throw "$(@('choco')+$Arguments | ConvertTo-Json -Compress) failed with exit code $LASTEXITCODE"
    }
}
function choco {
    Start-Choco $Args
}

choco install -y resharper
