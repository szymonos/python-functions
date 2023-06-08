#Requires -Version 7.2

#region startup settings
# import posh-git module for git autocompletion.
try {
    Import-Module posh-git -ErrorAction Stop
    $GitPromptSettings.EnablePromptStatus = $false
} catch {
    Out-Null
}
# make PowerShell console Unicode (UTF-8) aware
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()
# set culture to English Sweden for ISO-8601 datetime settings
[Threading.Thread]::CurrentThread.CurrentCulture = 'en-SE'
# Change PSStyle for directory coloring.
$PSStyle.FileInfo.Directory = "$($PSStyle.Bold)$($PSStyle.Foreground.Blue)"
# Configure PSReadLine setting.
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Chord Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord F2 -Function SwitchPredictionView
Set-PSReadLineKeyHandler -Chord Shift+Tab -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord Alt+j -Function NextHistory
Set-PSReadLineKeyHandler -Chord Alt+k -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord Ctrl+LeftArrow -Function BackwardWord
Set-PSReadLineKeyHandler -Chord Ctrl+RightArrow -Function ForwardWord
Set-PSReadLineKeyHandler -Chord Alt+Delete -Function DeleteLine
#endregion

#region environment variables and aliases
[Environment]::SetEnvironmentVariable('OMP_PATH', '/usr/local/share/oh-my-posh')
[Environment]::SetEnvironmentVariable('SCRIPTS_PATH', '/usr/local/share/powershell/Scripts')
(Select-String '(?<=^ID.+)(alpine|arch|fedora|debian|ubuntu|opensuse)' -List /etc/os-release).Matches.Value.ForEach({
        [Environment]::SetEnvironmentVariable('DISTRO_FAMILY', $_)
    }
)
# $env:PATH variable
@(
    [IO.Path]::Combine($HOME, '.local', 'bin')
) | ForEach-Object {
    if ((Test-Path $_) -and $env:PATH -NotMatch "$_/?($([IO.Path]::PathSeparator)|$)") {
        [Environment]::SetEnvironmentVariable('PATH', [string]::Join([IO.Path]::PathSeparator, $_, $env:PATH))
    }
}
# dot source PowerShell alias scripts
if (Test-Path $env:SCRIPTS_PATH) {
    Get-ChildItem -Path $env:SCRIPTS_PATH -Filter '_aliases_*.ps1' -File | ForEach-Object { . $_.FullName }
}
#endregion

#region venv initialize
if (Test-Path .vscode/init.ps1) {
    & .vscode/init.ps1
}
#endregion

#region prompt
try {
    Get-Command oh-my-posh -CommandType Application -ErrorAction Stop | Out-Null
    oh-my-posh --init --shell pwsh --config "$(Resolve-Path $env:OMP_PATH/theme.omp.json -ErrorAction Stop)" | Invoke-Expression
    # disable venv prompt as it is handled in oh-my-posh theme
    [Environment]::SetEnvironmentVariable('VIRTUAL_ENV_DISABLE_PROMPT', $true)
} catch {
    function Format-Duration {
        [CmdletBinding()]
        param (
            [timespan]$TimeSpan
        )

        switch ($TimeSpan) {
            { $_.TotalMilliseconds -gt 0 -and $_.TotalMilliseconds -lt 10 } { '{0:N2}ms' -f $_.TotalMilliseconds; continue }
            { $_.TotalMilliseconds -ge 10 -and $_.TotalMilliseconds -lt 100 } { '{0:N1}ms' -f $_.TotalMilliseconds; continue }
            { $_.TotalMilliseconds -ge 100 -and $_.TotalMilliseconds -lt 1000 } { '{0:N0}ms' -f $_.TotalMilliseconds; continue }
            { $_.TotalSeconds -ge 1 -and $_.TotalSeconds -lt 10 } { '{0:N3}s' -f $_.TotalSeconds; continue }
            { $_.TotalSeconds -ge 10 -and $_.TotalSeconds -lt 100 } { '{0:N2}s' -f $_.TotalSeconds; continue }
            { $_.TotalSeconds -ge 100 -and $_.TotalHours -le 1 } { $_.ToString('mm\:ss\.ff'); continue }
            { $_.TotalHours -ge 1 -and $_.TotalDays -le 1 } { $_.ToString('hh\:mm\:ss'); continue }
            { $_.TotalDays -ge 1 } { "$($_.Days * 24 + $_.Hours):$($_.ToString('mm\:ss'))"; continue }
            Default { '0ms' }
        }
    }
    function Prompt {
        # get execution time of the last command
        $executionTime = (Get-History).Count -gt 0 ? (Format-Duration(Get-History)[-1].Duration) : $null
        # get prompt path
        $split = $($PWD.Path.Replace($HOME, '~').Replace('Microsoft.PowerShell.Core\FileSystem::', '') -replace '\\$').Split([IO.Path]::DirectorySeparatorChar, [StringSplitOptions]::RemoveEmptyEntries)
        $promptPath = if ($split.Count -gt 3) {
            [string]::Join('/', $split[0], '..', $split[-1])
        } else {
            [string]::Join('/', $split)
        }
        # run elevated indicator
        if ((id -u) -eq 0) {
            [Console]::Write("`e[91m#`e[0m ")
        }
        # write last execution time
        if ($executionTime) {
            [Console]::Write("[`e[93m$executionTime`e[0m] ")
        }
        # write prompt path
        [Console]::Write("`e[94m`u{e0b3}`u{e0b2}`e[0m`e[104;1m$promptPath`e[0m`e[94m`u{e0b0}`u{e0b1}`e[0m ")
        # write git branch/status
        if ($GitPromptSettings) {
            # get git status
            $gstatus = @(git status -b --porcelain=v2 2>$null)[1..4]
            if ($gstatus) {
                # get branch name and upstream status
                $branch = $gstatus[0].Split(' ')[2] + ($gstatus[1] -match 'branch.upstream' ? $null : " `u{21E1}")
                # format branch name color depending on working tree status
                [Console]::Write("{0}`u{E0A0} $branch ", ($gstatus | Select-String -Pattern '^(?!#)' -Quiet) ? "`e[38;2;255;146;72m" : "`e[38;2;212;170;252m")
            }
        }
        return "`e[92m$("`u{276d} " * ($nestedPromptLevel + 1))`e[0m"
    }
}
#endregion
