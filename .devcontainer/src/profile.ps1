#Requires -Version 7.2
#Requires -Modules @{ ModuleName="PSReadLine"; RequiredVersion="2.2.1" }, posh-git

# *StartUp settings.
# import modules
Import-Module posh-git; $GitPromptSettings.EnablePromptStatus = $false
# make PowerShell console Unicode (UTF-8) aware
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()
# set culture to English Sweden for ISO-8601 datetime settings
[Threading.Thread]::CurrentThread.CurrentCulture = 'en-SE'
<# Change PSStyle for directory coloring. Enable coloring:
Enable-ExperimentalFeature PSAnsiRenderingFileInfo #>
$PSStyle.FileInfo.Directory = "$($PSStyle.Bold)$($PSStyle.Foreground.Blue)"
# configure PSReadLine
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Chord Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord F2 -Function SwitchPredictionView
Set-PSReadLineKeyHandler -Chord Shift+Tab -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord Alt+j -Function NextHistory
Set-PSReadLineKeyHandler -Chord Alt+k -Function PreviousHistory
# set Startup Working Directory variable
$SWD = $PWD.Path

# *Aliases and functions.
Set-Alias -Name _ -Value sudo
# navigation functions
function cds { Set-Location $SWD }
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }

# list directory contents
function l { ls -1 --color=auto --time-style=long-iso --group-directories-first $args }
function la { ls -lAh --color=auto --time-style=long-iso --group-directories-first $args }
function lsa { ls -lah --color=auto --time-style=long-iso --group-directories-first $args }

function ll { Get-ChildItem -Force $args }

function src { . $PROFILE.CurrentUserAllHosts }

function Get-CmdletAlias ($cmdletname) {
    <#
    .SYNOPSIS
    Gets the aliases for any cmdlet.#>
    Get-Alias | `
        Where-Object -FilterScript { $_.Definition -match $cmdletname } | `
        Sort-Object -Property Definition, Name | `
        Select-Object -Property Definition, Name
}

function Format-Duration ([timespan]$TimeSpan) {
    switch ($TimeSpan) {
        { $_.TotalMilliseconds -gt 0 -and $_.TotalMilliseconds -lt 10 } { '{0:N2}ms' -f $_.TotalMilliseconds }
        { $_.TotalMilliseconds -ge 10 -and $_.TotalMilliseconds -lt 100 } { '{0:N1}ms' -f $_.TotalMilliseconds }
        { $_.TotalMilliseconds -ge 100 -and $_.TotalMilliseconds -lt 1000 } { '{0:N0}ms' -f $_.TotalMilliseconds }
        { $_.TotalSeconds -ge 1 -and $_.TotalSeconds -lt 10 } { '{0:N3}s' -f $_.TotalSeconds }
        { $_.TotalSeconds -ge 10 -and $_.TotalSeconds -lt 100 } { '{0:N2}s' -f $_.TotalSeconds }
        { $_.TotalSeconds -ge 100 -and $_.TotalHours -le 1 } { $_.ToString('mm\:ss\.ff') }
        { $_.TotalHours -ge 1 -and $_.TotalDays -le 1 } { $_.ToString('hh\:mm\:ss') }
        { $_.TotalDays -ge 1 } { "$($_.Days * 24 + $_.Hours):$($_.ToString('mm\:ss'))" }
        Default { '0ms' }
    }
}

# *Prompt.
function Prompt {
    $execStatus = $?
    # get execution time of the last command
    $executionTime = (Get-History).Count -gt 0 ? (Format-Duration(Get-History)[-1].Duration) : $null
    # get prompt path
    $promptPath = $PWD.Path.Replace($HOME, '~').Replace('Microsoft.PowerShell.Core\FileSystem::', '') -replace '\\$', ''
    $split = $promptPath.Split([IO.Path]::DirectorySeparatorChar)
    if ($split.Count -gt 3) {
        $promptPath = [IO.Path]::Join((($split[0] -eq '~') ? '~' : ($IsWindows ? "$($PWD.Drive.Name):" : $split[1])), '..', $split[-1])
    }
    # write last execution time
    if ($executionTime) { [Console]::Write("[$($PSStyle.Foreground.BrightYellow)$executionTime$($PSStyle.Reset)] ") }
    # write last execution status
    [Console]::Write("$($PSStyle.Bold){0}`u{2192} ", $execStatus ? $PSStyle.Foreground.BrightGreen : $PSStyle.Foreground.BrightRed)
    # write prompt path
    [Console]::Write("$($PSStyle.Foreground.Blue)$promptPath$($PSStyle.Reset) ")
    # write git branch/status
    try {
        # get git status
        if ($gstatus = @(git status -b --porcelain=v2 2>$null)[1..4]) {
            # get branch name and upstream status
            $branch = $gstatus[0].Split(' ')[2] + ($gstatus[1] -match 'branch.upstream' ? $null : " `u{21E1}")
            # format branch name color depending on working tree status
            [Console]::Write("{0}`u{E0A0}$branch ", ($gstatus | Select-String -Pattern '^(?!#)' -Quiet) ? "`e[38;2;255;146;72m" : "`e[38;2;212;170;252m")
        }
    } catch {}
    return '{0}{1} ' -f ($PSStyle.Reset, '>' * ($nestedPromptLevel + 1))
}

# *Display startup information.
"$($PSStyle.Foreground.BrightCyan)BootUp: $((Get-Uptime -Since).ToString('u')) | Uptime: $(Get-Uptime)$($PSStyle.Reset)"
"$($PSStyle.Foreground.BrightWhite){0} | PowerShell $($PSVersionTable.PSVersion)$($PSStyle.Reset)" `
    -f (Select-String '^PRETTY_NAME=' /etc/os-release -Raw).Split('=')[1] -replace ("['`"]")
