$ErrorActionPreference = "Stop"

# @via: https://learn.microsoft.com/en-us/archive/blogs/virtual_pc_guy/a-self-elevating-powershell-script
$winID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$winPrinc = new-object System.Security.Principal.WindowsPrincipal($winID)
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

if (-Not $winPrinc.IsInRole($adminRole)) {
    $newProc = new-object System.Diagnostics.ProcessStartInfo "PowerShell"
    $newProc.Arguments = $myInvocation.MyCommand.Definition
    $newProc.Verb = "runas"
    [System.Diagnostics.Process]::Start($newProc)
    exit
}

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

function Install-Japanese-IME {
    Install-Language -Language ja-JP
    Write-Host 'IME installed.'
}

function Ensure-Japanese-IME {
    $langs = Get-InstalledLanguage -Language ja-JP
    if ($langs.count -gt 0) {
        Write-Host 'Japanese IME already installed.'
        return
    }
    $prompt = {
        $choice = Read-Host 'No Japanese IME installed, install now? [Y/n]'
        switch -regex ($choice) {
            '^Y?$' {Install-Japanese-IME}
            '^N$' {Write-Host "You'll have to setup IME manually, and then import the .reg file yourself."; exit -1}
            default {Write-Host 'invalid option'; &$prompt}
        }
    }
    &$prompt
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

$prompt = {
    $choice = Read-Host "[K]aufmann or [A]lbrecht? (default K)"
    Switch -regex ($choice) {
        '^K?$' {Install-Kaufmann}
        '^A$' {Install-Albrecht}
        default {Write-Host 'invalid option'; &$prompt}
    }
}
&$prompt

Ensure-Japanese-IME

Setup-Registry

Write-Host 'setup completed.'

Read-Host '<enter> finish'
exit 0
