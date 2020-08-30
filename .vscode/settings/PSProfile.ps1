<#
.SYNOPSIS
My PowerShell $profile. Prompt requires posh-git
Install-Module -Name posh-git -AllowPrerelease
.LINK
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_special_characters?view=powershell-7
https://docs.microsoft.com/en-us/dotnet/standard/base-types/composite-formatting
https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
https://jonasjacek.github.io/colors/
https://github.com/dahlbyk/posh-git
https://github.com/PowerShell/PSReadLine
https://github.com/JanDeDobbeleer/oh-my-posh
.EXAMPLE
Prompt
#>
[void] [System.Reflection.Assembly]::Load('System.Windows.Forms')
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
function Prompt {
    if ($IsWindows) { filter repl1 { $_ -replace ('[c-z]:\\Users\\{0}' -f $env:USERNAME), '~' } }
    else { filter repl1 { $_ -replace ('{0}' -f $env:HOME), '~' } }
    filter repl2 { $_ -replace 'Microsoft.PowerShell.Core\\FileSystem::', '' }
    if ((Get-History).Count -gt 0) {
        $executionTime = ((Get-History)[-1].EndExecutionTime - (Get-History)[-1].StartExecutionTime).Totalmilliseconds
    }
    else {
        $executionTime = 0
    }
    $promptPath = $PWD | repl1 | repl2
    [System.Console]::WriteLine("`e[93m[`e[38;5;147m{0:N1}ms`e[93m] `e[1m`e[34m{1}`e[0m{2}", $executionTime, $promptPath, (Write-VcsStatus))
    return ("`e[92m`u{25BA}`e[0m" * ($nestedPromptLevel + 1)) + ' '
}
$4 = $PWD  # workspace path
$init = [IO.Path]::Combine('.vscode', 'init.ps1')
if (Test-Path $init) { & $init }
if ($IsLinux) { Set-Alias -Name python -Value python3 }
Clear-Host
Write-Output ('PowerShell ' + $PSVersionTable.PSVersion.ToString())
Write-Output ('BootUp: ' + (Get-Uptime -Since).ToString() + ' | Uptime: ' + (Get-Uptime).ToString())
