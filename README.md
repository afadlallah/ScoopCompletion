# ScoopCompletion: Scoop Tab Completion in PowerShell

PowerShell-based tab completion module for the [Scoop](https://github.com/ScoopInstaller/Scoop) Windows package manager. Works with all PowerShell versions.

## Requirements

* [Scoop](https://github.com/ScoopInstaller/Scoop)
* [PowerShell 5+](https://learn.microsoft.com/en-us/skypeforbusiness/set-up-your-computer-for-windows-powershell/download-and-install-windows-powershell-5-1) or [PowerShell Core](https://github.com/PowerShell/PowerShell)

## Installation

### 1. Via Scoop

- You'll first need to create a manifest for ScoopCompletion.

- It will be installed in the Scoop `apps` folder, and you can then create a symlink to this installation in the Scoop `modules` folder.

```powershell
scoop install ScoopCompletion
```

### 2. Direct from Source

- Clone this repository and install using the `Install-Module` command

```powershell
# Clone
git clone https://github.com/afadlallah/ScoopCompletion.git

# Install
Install-Module -Path .\ScoopCompletion -Scope CurrentUser
```

## Usage

There are two main ways to load the module:

1. Manually in the current shell (will not persist across sessions)

2. Automatically via a PowerShell `$Profile`

### Loading Manually

- If the Scoop modules folder is in your `$Env:PSModulePath`, you can load the module manually in the current shell like this:

```powershell
Import-Module ScoopCompletion
```

- Otherwise, you can load the module manually by specifying the full path to the module:

```powershell
Import-Module "$($(Get-Item $(Get-Command scoop.ps1).Path).Directory.Parent.FullName)\modules\ScoopCompletion"
```

### Loading via PowerShell `$Profile`

- Create your `$Profile` if it doesn't exist:

```powershell
if (!(Test-Path $profile)) { New-Item -Path $profile -ItemType "file" -Force }
```

- Add the following line:

```powershell
Import-Module ScoopCompletion
```

Alternatively, you can load the entire Scoop modules folder on PowerShell startup:

```powershell
$scoopModulesFolder = "C:\Users\<username>\scoop\modules"
if (Test-Path $scoopModulesFolder) {
    Get-ChildItem -Path $scoopModulesFolder -Directory | ForEach-Object { Import-Module $_.FullName -ErrorAction SilentlyContinue }
}
```
