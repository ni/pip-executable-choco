


$ErrorActionPreference = 'Stop';


Write-Host "Warning: Only removing pipx and path entry. Not removing pipx installed venvs. These can be found under $env:UserProfile\.local\pipx"

# region: remove PATH values
# based on https://gitlab.com/DarwinJS/ChocoPackages/-/blob/master/ec2clitools/tools/chocolateyuninstall.ps1
$PathToRemove = "$env:USERPROFILE\.local\bin"

foreach ($path in [Environment]::GetEnvironmentVariable("PATH","User").split(';'))
{
  If ($Path)
  {
    If (($path -ine "$PathToRemove") -AND ($path -ine "$PathToRemove\"))
    {
      [string[]]$Newpath += "$path"
    }
  }
}
$AssembledNewPath = ($newpath -join(';')).trimend(';')

[Environment]::SetEnvironmentVariable("PATH",$AssembledNewPath,"User")

# endregion

