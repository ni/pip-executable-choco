$scriptPath = Join-Path $PSScriptRoot '..\pip_executable_choco\tools\chocolateyinstall.ps1'
$scriptPath = Resolve-Path $scriptPath -ErrorAction Stop
. $scriptPath

Describe 'Get-PythonHome' {
  It 'returns the HKCU app path when present' {
    Mock Get-RegistryValue {
      'C:\Python311\python.exe'
    } -ParameterFilter { $key -like 'HKCU:*' }

    Mock Get-RegistryValue { $null } -ParameterFilter { $key -like 'HKLM:*' }
    Mock Get-Command { throw 'Get-Command should not be called' }
    Mock Get-ChildItem {
      [System.IO.FileInfo]::new('C:\Python311\python.exe')
    } -ParameterFilter { $Path -eq 'C:\Python311\python.exe' }

    $result = Get-PythonHome

    $result.FullName | Should Be 'C:\Python311\python.exe'
    Assert-MockCalled Get-Command -Times 0 -Exactly -Scope It
  }

  It 'falls back to the HKLM app path when HKCU is absent' {
    Mock Get-RegistryValue { $null } -ParameterFilter { $key -like 'HKCU:*' }
    Mock Get-RegistryValue {
      'C:\Python312\python.exe'
    } -ParameterFilter { $key -like 'HKLM:*' }
    Mock Get-Command { throw 'Get-Command should not be called' }
    Mock Get-ChildItem {
      [System.IO.FileInfo]::new('C:\Python312\python.exe')
    } -ParameterFilter { $Path -eq 'C:\Python312\python.exe' }

    $result = Get-PythonHome

    $result.FullName | Should Be 'C:\Python312\python.exe'
    Assert-MockCalled Get-Command -Times 0 -Exactly -Scope It
  }

  It 'finds python.exe on PATH when registry entries are absent' {
    Mock Get-RegistryValue { $null } -ParameterFilter { $key -like 'HKCU:*' }
    Mock Get-RegistryValue { $null } -ParameterFilter { $key -like 'HKLM:*' }
    Mock Get-Command {
      [pscustomobject]@{ Source = 'C:\Python311\python.exe' }
    } -ParameterFilter { $Name -eq 'python.exe' }
    Mock Get-Command { $null } -ParameterFilter { $Name -ne 'python.exe' }
    Mock Get-ChildItem {
      [System.IO.FileInfo]::new('C:\Python311\python.exe')
    } -ParameterFilter { $Path -eq 'C:\Python311\python.exe' }

    $result = Get-PythonHome

    $result.FullName | Should Be 'C:\Python311\python.exe'
    Assert-MockCalled Get-Command -Times 1 -Exactly -Scope It -ParameterFilter { $Name -eq 'python.exe' }
  }

  It 'falls back to python3.exe when python.exe is unavailable' {
    Mock Get-RegistryValue { $null } -ParameterFilter { $key -like 'HKCU:*' }
    Mock Get-RegistryValue { $null } -ParameterFilter { $key -like 'HKLM:*' }
    Mock Get-Command { $null } -ParameterFilter { $Name -eq 'python.exe' }
    Mock Get-Command {
      [pscustomobject]@{ Source = 'C:\Python311\python3.exe' }
    } -ParameterFilter { $Name -eq 'python3.exe' }
    Mock Get-Command { $null } -ParameterFilter { $Name -in @('python', 'python3') }
    Mock Get-ChildItem {
      [System.IO.FileInfo]::new('C:\Python311\python3.exe')
    } -ParameterFilter { $Path -eq 'C:\Python311\python3.exe' }

    $result = Get-PythonHome

    $result.FullName | Should Be 'C:\Python311\python3.exe'
    Assert-MockCalled Get-Command -Times 1 -Exactly -Scope It -ParameterFilter { $Name -eq 'python.exe' }
    Assert-MockCalled Get-Command -Times 1 -Exactly -Scope It -ParameterFilter { $Name -eq 'python3.exe' }
  }

  It 'falls back to python when the exe aliases are unavailable' {
    Mock Get-RegistryValue { $null } -ParameterFilter { $key -like 'HKCU:*' }
    Mock Get-RegistryValue { $null } -ParameterFilter { $key -like 'HKLM:*' }
    Mock Get-Command { $null } -ParameterFilter { $Name -in @('python.exe', 'python3.exe') }
    Mock Get-Command {
      [pscustomobject]@{ Source = 'C:\Python311\python.cmd' }
    } -ParameterFilter { $Name -eq 'python' }
    Mock Get-Command { $null } -ParameterFilter { $Name -eq 'python3' }
    Mock Get-ChildItem {
      [System.IO.FileInfo]::new('C:\Python311\python.cmd')
    } -ParameterFilter { $Path -eq 'C:\Python311\python.cmd' }

    $result = Get-PythonHome

    $result.FullName | Should Be 'C:\Python311\python.cmd'
    Assert-MockCalled Get-Command -Times 1 -Exactly -Scope It -ParameterFilter { $Name -eq 'python' }
  }

  It 'falls back to python3 when python is unavailable' {
    Mock Get-RegistryValue { $null } -ParameterFilter { $key -like 'HKCU:*' }
    Mock Get-RegistryValue { $null } -ParameterFilter { $key -like 'HKLM:*' }
    Mock Get-Command { $null } -ParameterFilter { $Name -in @('python.exe', 'python3.exe', 'python') }
    Mock Get-Command {
      [pscustomobject]@{ Source = 'C:\Python311\python3.cmd' }
    } -ParameterFilter { $Name -eq 'python3' }
    Mock Get-ChildItem {
      [System.IO.FileInfo]::new('C:\Python311\python3.cmd')
    } -ParameterFilter { $Path -eq 'C:\Python311\python3.cmd' }

    $result = Get-PythonHome

    $result.FullName | Should Be 'C:\Python311\python3.cmd'
    Assert-MockCalled Get-Command -Times 1 -Exactly -Scope It -ParameterFilter { $Name -eq 'python3' }
  }

  It 'returns null when Python cannot be found' {
    Mock Get-RegistryValue { $null } -ParameterFilter { $key -like 'HKCU:*' }
    Mock Get-RegistryValue { $null } -ParameterFilter { $key -like 'HKLM:*' }
    Mock Get-Command { $null } -ParameterFilter { $Name -eq 'python.exe' }
    Mock Get-Command { $null } -ParameterFilter { $Name -eq 'python3.exe' }
    Mock Get-Command { $null } -ParameterFilter { $Name -eq 'python' }
    Mock Get-Command { $null } -ParameterFilter { $Name -eq 'python3' }
    Mock Get-ChildItem { throw 'Get-ChildItem should not be called' }

    $result = Get-PythonHome

    $result | Should Be $null
    Assert-MockCalled Get-Command -Times 4 -Exactly -Scope It
  }
}

Describe 'Get-ChocolateyInstallRoot' {
  BeforeEach {
    $env:ChocolateyInstall = $null
  }

  It 'prefers the ChocolateyInstall environment variable' {
    $env:ChocolateyInstall = 'C:\ProgramData\chocolatey'
    Mock Get-Command { throw 'Get-Command should not be called' }

    $result = Get-ChocolateyInstallRoot

    $result | Should Be 'C:\ProgramData\chocolatey'
    Assert-MockCalled Get-Command -Times 0 -Exactly -Scope It
  }

  It 'falls back to the choco command path' {
    Mock Get-Command {
      [pscustomobject]@{ Source = 'C:\ProgramData\chocolatey\bin\choco.exe' }
    } -ParameterFilter { $Name -eq 'choco' }
    Mock Get-Command { $null } -ParameterFilter { $Name -eq 'chocolatey' }

    $result = Get-ChocolateyInstallRoot

    $result | Should Be 'C:\ProgramData\chocolatey'
    Assert-MockCalled Get-Command -Times 1 -Exactly -Scope It -ParameterFilter { $Name -eq 'choco' }
  }

  It 'falls back to the chocolatey command path when choco is unavailable' {
    Mock Get-Command { $null } -ParameterFilter { $Name -eq 'choco' }
    Mock Get-Command {
      [pscustomobject]@{ Source = 'C:\ProgramData\chocolatey\bin\chocolatey.exe' }
    } -ParameterFilter { $Name -eq 'chocolatey' }

    $result = Get-ChocolateyInstallRoot

    $result | Should Be 'C:\ProgramData\chocolatey'
    Assert-MockCalled Get-Command -Times 1 -Exactly -Scope It -ParameterFilter { $Name -eq 'chocolatey' }
  }

  It 'returns null when Chocolatey cannot be resolved' {
    Mock Get-Command { $null } -ParameterFilter { $Name -eq 'choco' }
    Mock Get-Command { $null } -ParameterFilter { $Name -eq 'chocolatey' }

    $result = Get-ChocolateyInstallRoot

    $result | Should Be $null
    Assert-MockCalled Get-Command -Times 2 -Exactly -Scope It
  }
}

Describe 'chocolatey-install' {
  It 'throws when Chocolatey root cannot be determined' {
    Mock Get-ChocolateyInstallRoot { return $null }
    Mock Get-Python-Executable { return 'C:\Python311\python.exe' }

    { chocolatey-install } | Should Throw 'Chocolatey installation root'
  }

  It 'throws when Python executable cannot be determined' {
    Mock Get-ChocolateyInstallRoot { return 'C:\ProgramData\chocolatey' }
    Mock Get-Python-Executable { return $null }

    { chocolatey-install } | Should Throw 'Python executable'
  }
}