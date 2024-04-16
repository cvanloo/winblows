#param (
#    [Parameter(Mandatory=$true)]
#    [String]
#    $Language
#)
#
#$langs = Get-Language -Language $Language
#if ($langs.count -eq 0) {
#    Write-Host 'installing language' $Language
#    Install-Language -Language $Language
#}
#
#Get-ChildItem -path 'hklm:\System\CurrentControlSet\Control\Keyboard Layouts'
#
#Get-ChildItem -path 'hklm:\System\CurrentControlSet\Control\Keyboard Layouts' |
#    Foreach-Object {
#        $Entry = $_
#        $Entry.GetValue('Layout File')
#    }


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

Write-Host 'Select a language:'
for ($i = 0; $i -lt $Langs.Length; $i++) {
    $Lang = $Langs[$i]
    Write-Host "[$i] $($Lang.Lang) $($Lang.LayoutDLL)"
}

exit 0

Write-Host $Langs[0].LocalizedName ':' $Langs[0].InputMethodTips


$default_layout = (Get-ItemProperty -path 'hkcu:\Keyboard Layout\Preload').1
$keeb = Get-ItemProperty -path "hklm:\System\CurrentControlSet\Control\Keyboard Layouts\$default_layout"
$layout_dll = $keeb.'Layout File'

Host-Write 'found layout dll:' $layout_dll
