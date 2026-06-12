$ErrorActionPreference = 'Stop';

Write-Host "Warning: Only removing pipx and path entry. Not removing pipx installed venvs. These can be found under $env:UserProfile\.local\pipx"

# region: remove PATH values
# based on https://gitlab.com/DarwinJS/ChocoPackages/-/blob/master/ec2clitools/tools/chocolateyuninstall.ps1
$PathToRemove = "$env:USERPROFILE\.local\bin"
$CurrentPath = [Environment]::GetEnvironmentVariable('PATH', 'User')

if ($CurrentPath) {
  [string[]]$Newpath = @()
  foreach ($path in $CurrentPath.Split(';')) {
    if ($path) {
      if (($path -ine $PathToRemove) -and ($path -ine "$PathToRemove\")) {
        $Newpath += $path
      }
    }
  }
  $AssembledNewPath = ($Newpath -join ';').TrimEnd(';')
} else {
  $AssembledNewPath = ''
}

if ($AssembledNewPath -or !$CurrentPath) {
  [Environment]::SetEnvironmentVariable('PATH', $AssembledNewPath, 'User')
}

# endregion

