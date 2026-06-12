function Get-RegistryValue($key, $value) {
  $item = Get-ItemProperty $key $value -ErrorAction SilentlyContinue

  if ($item -ne $null) {
    return $item.$value
  }

  return $null
}

function Get-PythonHome() {
  $result = $null

  $filename = Get-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Python.exe" '(default)'

  if (!$filename) {
    $filename = Get-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Python.exe" '(default)'
  }

  if (!$filename) {
    $command = Get-Command -ErrorAction SilentlyContinue "python.exe"
    $filename = $command.Source
  }

  if (!$filename) {
    $command = Get-Command -ErrorAction SilentlyContinue "python3.exe"
    $filename = $command.Source
  }

  if (!$filename) {
    $command = Get-Command -ErrorAction SilentlyContinue "python"
    $filename = $command.Source
  }

  if (!$filename) {
    $command = Get-Command -ErrorAction SilentlyContinue "python3"
    $filename = $command.Source
  }

  if ($null -ne $filename) {
    $result = Get-ChildItem $filename -ErrorAction SilentlyContinue
  }

  return $result
}

$global:pipx_version = "1.1.0"

function Get-Python-Executable() {
  return Get-PythonHome
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

  if (!$ChocolateyInstall) {
    throw 'Chocolatey installation root could not be determined.'
  }

  if (!$python_exe) {
    throw 'Python executable could not be found in registry or PATH.'
  }

  $installDir = "$ChocolateyInstall\lib\pipx\.venv"

  try {
    Write-Host "Creating a venv using $python_exe in $installDir..."
    
    & $python_exe -m venv --copies --system-site-packages $installDir
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to create venv (exit code: $LASTEXITCODE)"
    }
    
    Write-Debug "Upgrading pip in venv"
    
    & $installDir\Scripts\python -m pip install -U pip
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to upgrade pip (exit code: $LASTEXITCODE)"
    }
    
    Write-Host "Installing pipx into venv..."
    
    & $installDir\Scripts\pip install pipx==$pipx_version
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to install pipx (exit code: $LASTEXITCODE)"
    }

    # find all exe's except pipx itself
    $files = Get-ChildItem $installDir -Include *.exe -Recurse | Where-Object {
      $_.Name -notmatch 'pipx'
    }

    foreach ($file in $files) {
      # generate an ignore file for all exe's except pipx
      New-Item "$($file.FullName).ignore" -ItemType File -Force | Out-Null
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
