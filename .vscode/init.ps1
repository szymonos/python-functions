$activateScript = [IO.Path]::Combine('.venv', ($IsWindows ? 'Scripts' : 'bin'), 'Activate.ps1')
if (Test-Path $activateScript) { & $activateScript }
