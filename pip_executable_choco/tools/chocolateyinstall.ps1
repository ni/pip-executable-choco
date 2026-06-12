function Get-RegistryValue($key, $value) {
  $item = (Get-ItemProperty $key $value -ErrorAction SilentlyContinue)
  if ($item -ne $null) { return $item.$value } else { return $null }
}  

function Get-Python-Home() {
  $result = $null
  
  $filename = Get-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Python.exe" '(default)' 
  
  if ($null -eq $filename) {
    $filename = Get-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Python.exe" '(default)'  
  }

  if ($null -eq $filename) {
    $command = Get-Command -erroraction 'silentlycontinue' "python.exe"
    $filename = $command.Source
  }

  if ($null -eq $filename) {
    $command = Get-Command -erroraction 'silentlycontinue' "python3.exe"
    $filename = $command.Source
  }

  if ($null -eq $filename) {
    $command = Get-Command -erroraction 'silentlycontinue' "python"
    $filename = $command.Source
  }

  if ($null -eq $filename) {
    $command = Get-Command -erroraction 'silentlycontinue' "python3"
    $filename = $command.Source
  }
  
  if ($null -ne $filename) {
    $file = Get-ChildItem $filename
    $result = $file	  
  }
  
  return $result
}

$global:pipx_version = "1.1.0"

function Get-Python-Executable() {
  return Get-Python-Home
}

function Get-ChocolateyInstallRoot() {
  if ($null -ne $env:ChocolateyInstall -and $env:ChocolateyInstall.Trim().Length -gt 0) {
    return $env:ChocolateyInstall
  }

  $command = Get-Command -ErrorAction SilentlyContinue "choco"
  if ($null -ne $command) {
    return (Split-Path -Parent (Split-Path -Parent $command.Source))
  }

  $command = Get-Command -ErrorAction SilentlyContinue "chocolatey"
  if ($null -ne $command) {
    return (Split-Path -Parent (Split-Path -Parent $command.Source))
  }

  return $null
}

function chocolatey-install() {
  $ChocolateyInstall = Get-ChocolateyInstallRoot
  $python_exe = Get-Python-Executable

  $installDir = "$ChocolateyInstall\lib\pipx\.venv"

  try {
    Write-Host "Creating a venv using $python_exe in $installDir..."
    
    & $python_exe -m venv --copies --system-site-packages $installDir
    
    Write-Debug "Upgrading pip in venv"
    
    & $installDir\Scripts\python -m pip install -U pip
    
    Write-Host "Installing pipx into venv..."
    
    & $installDir\Scripts\pip install pipx==$pipx_version

    # find all exe's except pipx iteself
    $files = get-childitem $installDir -include *.exe -recurse | Where-Object {$_.name -notmatch 'pipx'}

    foreach ($file in $files) {
      # generate an ignore file for all exe's except pipx
      New-Item "$file.ignore" -type file -force | Out-Null
    }

    # Add pipx-shim's path to PATH
    Install-ChocolateyPath -PathToInstall "$env:USERPROFILE\.local\bin" -PathType User
  }
  catch {
    Write-Host Error installing pipx "$($_.Exception.Message)"
    throw
  }
}

if ($MyInvocation.InvocationName -ne '.') {
  chocolatey-install
}
