$activatePath = if ($IsWindows) { 'Scripts' } else { 'bin' }
$activateScript = [IO.Path]::Combine('app', '.venv', $activatePath, 'Activate.ps1')
if (Test-Path $activateScript) { & $activateScript }
