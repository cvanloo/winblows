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

$Langs = (Get-WinUserLanguageList) | ForEach-Object {
    $LangEntry = $_

    foreach ($layout in $LangEntry.InputMethodTips.Split(':')) {
        if ($layout.Length -gt 8) {continue}
        $padded_layout = $layout.PadLeft(8, '0')
        $keeb = Get-ItemProperty -path "hklm:\System\CurrentControlSet\Control\Keyboard Layouts\$padded_layout"

        $obj = [PSCustomObject] @{
            Lang = $LangEntry.LocalizedName
            LayoutDLL = $keeb.'Layout File'
        }
    }

    return $obj
}

Write-Host 'Languages:'
for ($i = 0; $i -lt $Langs.Length; $i++) {
    $Lang = $Langs[$i]
    Write-Host "[$i] $($Lang.Lang) $($Lang.LayoutDLL)"
}

$SelectedLang = $null
:prompt while ($SelectedLang -eq $null) {
    $choice = Read-Host 'Select a language (default: 0)'
    switch -regex ($choice) {
        '^\d*$' {
            $choice = if ($choice -ne $null) { [int]$choice } else { 0 }
            if ($choice -lt $Langs.Length) {
                $SelectedLang = $Langs[$choice]
                break prompt
            }
        }
        default {}
    }
    Write-Host 'invalid option'
}

$IMEPath = 'hklm:\System\CurrentControlSet\Control\Keyboard Layouts\00000411'
$IMEProp = 'Layout File'

New-ItemProperty -Path $IMEPath -Name $IMEProp -Value $SelectedLang.LayoutDLL -PropertyType String -Force

$i8042Path = 'hklm:\System\CurrentControlSet\Services\i8042prt\Parameters'
$driverJPN = 'LayerDriver JPN'
$driverKOR = 'LayerDriver KOR'

New-ItemProperty -Path $i8042Path -Name $driverJPN -Value $SelectedLang.LayoutDLL -PropertyType String -Force
New-ItemProperty -Path $i8042Path -Name $driverKOR -Value $SelectedLang.LayoutDLL -PropertyType String -Force

Read-Host '<enter> finish'
exit 0
