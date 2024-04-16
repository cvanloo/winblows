$ErrorActionPreference = "Stop"

# https://www.kaufmann.no/roland/dvorak/
# https://immanuel-albrecht.de/pdvrkde/
$kbddvp_kaufmann = 'https://www.kaufmann.no/downloads/winnt/kbddvp-1_2_8-i386.exe'
$kbddvp_albrecht = 'https://immanuel-albrecht.de/pdvrkde/pdvrkde.zip'

# @via: https://stackoverflow.com/a/34559554
function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

$tmp_dir = New-TemporaryDirectory

function Check {
    if ($LastExitCode -ne 0) {
        Write-Host 'setup failed.'
        exit -1
    }
}

function Install-Kaufmann {
    Write-Host 'downloading kaufmann...'
    $out_file = [IO.Path]::Combine($tmp_dir, 'kaufmann.exe')
    Invoke-WebRequest $kbddvp_kaufmann -OutFile $out_file
    Write-Host 'exe saved to ' $out_file
    Write-Host 'running kaufmann.exe...'
    & $out_file | Out-Null
    Check
    Write-Host 'installation finished'
}

function Install-Albrecht {
    Write-Host 'downloading albrecht...'
    $out_file = [IO.Path]::Combine($tmp_dir, 'albrecht.zip')
    Invoke-WebRequest $kbddvp_albrecht -OutFile $out_file
    Write-Host 'archive saved to ' $out_file
    $ext_path = [IO.Path]::Combine($tmp_dir, 'albrecht')
    Expand-Archive $out_file -DestinationPath $ext_path
    Write-Host 'achive extracted to ' $ext_path
    Write-Host 'running setup.exe...'
    $exe_file = [IO.Path]::Combine($ext_path, 'pdvrkde\setup.exe')
    & $exe_file | Out-Null
    Check
    Write-Host 'installation finished'
}

function Setup-Registry {
    #Get-Command reg
    Write-Host 'configuring registry...'
    reg import .\dvorak_please.reg
    Check
}

$choice = Read-Host "[K]aufmann or [A]lbrecht? (default K)"
Switch ($choice) {
    '' {Install-Kaufmann}
    'K' {Install-Kaufmann}
    'A' {Install-Albrecht}
    default {Write-Host 'invalid option'; exit -1}
}

Setup-Registry

Write-Host 'setup completed.'