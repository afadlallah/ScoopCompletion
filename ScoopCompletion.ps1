$baseCommands = @('alias', 'bucket', 'cache', 'cat', 'checkup', 'cleanup', 'config', 'create', 'depends', 'download', 'export', 'help', 'hold', 'home', 'import', 'info', 'install', 'list', 'prefix', 'reset', 'search', 'shim', 'status', 'unhold', 'uninstall', 'update', 'virustotal', 'which')

$configParameters = @('aria2-enabled', 'aria2-max-connection-per-server', 'aria2-min-split-size', 'aria2-options', 'aria2-retry-wait', 'aria2-split', 'aria2-warning-enabled', 'autostash_on_conflict', 'cache_path', 'cat_style', 'debug', 'default_architecture', 'force_update', 'gh_token', 'global_path', 'hold_update_until', 'ignore_running_processes', 'no_junction', 'private_hosts', 'proxy', 'root_path', 'scoop_branch', 'scoop_repo', 'shim', 'show_manifest', 'show_update_log', 'update_nightly', 'use_external_7zip', 'use_lessmsi', 'virustotal_api_key')

$configParameterValues = @{
    "aria2-enabled"          = 'false true'
    "aria2-warning-enabled"  = 'false true'
    autostash_on_conflict    = 'false true'
    debug                    = 'false true'
    default_architecture     = '32bit 64bit arm64'
    force_update             = 'false true'
    ignore_running_processes = 'false true'
    no_junction              = 'false true'
    scoop_branch             = 'develop master'
    shim                     = '71 kiennq scoopcs'
    show_manifest            = 'false true'
    show_update_log          = 'false true'
    update_nightly           = 'false true'
    use_external_7zip        = 'false true'
    use_lessmsi              = 'false true'
}

$longParameters = @{
    alias      = 'verbose'
    cache      = 'all'
    cleanup    = 'all cache global'
    download   = 'arch force no-hash-check no-update-scoop'
    export     = 'config'
    hold       = 'global'
    info       = 'verbose'
    install    = 'arch global independent no-cache no-update-scoop skip'
    reset      = 'all'
    shim       = 'global'
    status     = 'local'
    unhold     = 'global'
    uninstall  = 'global purge'
    update     = 'all force global independent no-cache quiet skip'
    virustotal = 'all no-depends no-update-scoop passthru scan'
}

$shortParameters = @{
    alias      = 'v'
    cache      = 'a'
    cleanup    = 'a k g'
    download   = 'a f h u'
    export     = 'c'
    hold       = 'g'
    info       = 'v'
    install    = 'a g i k u s'
    reset      = 'a'
    shim       = 'g'
    status     = 'l'
    unhold     = 'g'
    uninstall  = 'g p'
    update     = 'a f g i k q s'
    virustotal = 'a n u p s'
}

$parameterValues = @{
    download = @{
        a    = '32bit 64bit arm64'
        arch = '32bit 64bit arm64'
    }
    install  = @{
        a    = '32bit 64bit arm64'
        arch = '32bit 64bit arm64'
    }
}

$subcommands = @{
    alias  = 'add list rm'
    bucket = 'add list known rm'
    cache  = 'rm show'
    config = (@('rm') + $configParameters) -join ' '
    shim   = 'add alter info list rm'
}

$parameterKeys  = ($longParameters.Keys | Sort-Object) -join "|"
$parameterValueKeys = ($parameterValues.Keys | Sort-Object) -join "|"

$scoopDir = $env:SCOOP, $configFileContent.root_path, "$([System.Environment]::GetFolderPath('UserProfile'))\scoop" | Where-Object { -not [String]::IsNullOrEmpty($_) } | Select-Object -First 1
if (-not $scoopDir) { throw 'Scoop installation not found! Exiting ScoopCompletion script...' }

$configDir = $env:XDG_CONFIG_HOME, "$env:USERPROFILE\.config" | Select-Object -First 1
$configFilePath = "$configDir\scoop\config.json"
$configFileContent = if (Test-Path $configFilePath) { Get-Content $configFilePath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue }

$cacheDir = $env:SCOOP_CACHE, $configFileContent.cache_path, "$scoopDir\cache" | Where-Object { -not [String]::IsNullOrEmpty($_) } | Select-Object -First 1

$userAliases = $configFileContent.alias | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
$scoopAliasesRegex = "($(@("scoop\.ps1", "scoop\.cmd") + @(Get-Alias | Where-Object { $_.Definition -eq 'scoop' } | Select-Object -ExpandProperty Name) + "scoop" -join '|'))"

function Get-FilteredUserAliases ($aliasFilter) {
    $userAliases | Where-Object { $_ -like "$aliasFilter*" } | Sort-Object
}

function Expand-Commands ($commandFilter, $includeAliases) {
    $commandList = @()
    $commandList += $baseCommands
    if ($includeAliases) {
        $commandList += Get-FilteredUserAliases($commandFilter)
    }
    $commandList -like "$commandFilter*" | Sort-Object
}

function Get-InstalledPackages ($packageFilter) {
    @(& Get-ChildItem -Path $scoopDir\apps -Name -Directory | Where-Object { $_ -ne "scoop" } | Where-Object { $_ -like "$packageFilter*" }) | Sort-Object

}

function Get-RemotePackages ($packageFilter) {
    @(& Get-ChildItem -Path $scoopDir\buckets\ -Name |
    ForEach-Object { Get-ChildItem -Path $scoopDir\buckets\$_\bucket -Name -Filter *.json } |
    ForEach-Object { if ( $_ -match '^([\w][\-\.\w]*)\.json$' ) { "$($Matches[1])" } } |
    Where-Object { $_ -like "$packageFilter*" }) | Sort-Object

}

function ScoopTabExpansion($lastBlock) {

    switch -regex ($lastBlock) {
        # scoop <command> --<longParameter>|-<shortParameter> <value>
        "^(?<command>$parameterValueKeys)\s+(?:--|-)(?<parameter>.+) (?<value>\w*)$" {
            $command = $matches['command']
            $parameter = $matches['parameter'].TrimStart('-')
            $parameterValueFilter = $matches['value']
            if ($parameterValues[$command][$parameter]) {
                return $parameterValues[$command][$parameter] -split ' ' | Where-Object { $_ -like "$parameterValueFilter*" } | Sort-Object
            }
        }

        # scoop cleanup|hold|prefix|reset|unhold|uninstall|update|virustotal <package>
        "^(cleanup|hold|prefix|reset|unhold|uninstall|update|virustotal)\s+(?:.+\s+)?(?<package>[\w][\-\.\w]*)?$" {
            return Get-InstalledPackages $matches['package']
        }

        # scoop cat|download <package>
        "^(cat|download)\s+(?:.+\s+)?(?<package>[\w][\-\.\w]*)?$" {
            return Get-RemotePackages $matches['package'] + Get-InstalledPackages $matches['package']
        }

        # scoop config rm <parameter>
        "^config rm\s+(?:.+\s+)?(?<parameter>[\w][\-\.\w]*)?$" {
            $configParameterFilter = $matches['parameter']
            $configKeys = $configFileContent | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
            return $configKeys | Where-Object { $_ -like "$configParameterFilter*" -and $_ -ne 'alias' } | Sort-Object
        }

        # scoop depends|home|info|install <package>
        "^(depends|home|info|install)\s+(?:.+\s+)?(?<package>[\w][\-\.\w]*)?$" {
            return Get-RemotePackages $matches['package']
        }

        "^cache (rm|show)\s+(?:.+\s+)?(?<cache>[\w][\-\.\w]*)?$" {
            $cacheFilter = $matches['cache']
            $cacheFiles = @(Get-ChildItem $cachedir | Where-Object { $_.Name -match "^.*?#" } | ForEach-Object { $_.Name -split '#' | Select-Object -First 1 })
            $cacheFiles | Where-Object { $_ -like "$cacheFilter*" } | Sort-Object
        }

        # scoop bucket rm <bucket>
        "^bucket rm\s+(?:.+\s+)?(?<bucket>[\w][\-\.\w]*)?$" {
            $bucketFilter = $matches['bucket']
            & scoop bucket list | Where-Object { $_.Name -like "$bucketFilter*" } | Select-Object -ExpandProperty Name | Sort-Object
        }

        # scoop bucket add <bucket>
        "^bucket add\s+(?:.+\s+)?(?<bucket>[\w][\-\.\w]*)?$" {
            $bucketFilter = $matches['bucket']
            & scoop bucket known | Where-Object { $_ -like "$bucketFilter*" } | Sort-Object
        }

        # scoop alias rm <alias>
        "^alias rm\s+(?:.+\s+)?(?<alias>[\w][\-\.\w]*)?$" {
            return Get-FilteredUserAliases $matches['alias']
        }

        # scoop help <command>
        "^help (?<command>\S*)$" {
            return Expand-Commands $matches['command'] $false
        }

        # scoop <command> <subcommand>
        "^(?<command>$($subcommands.Keys -join '|'))\s+(?<subcommand>\S*)$" {
            $subcommand = $matches['command']
            $subcommandFilter = $matches['subcommand']
            $subcommands.$subcommand -split ' ' | Where-Object { $_ -like "$subcommandFilter*" } | Sort-Object
        }

        # scoop config <parameter> <value>
        "^config (?<parameter>[\w][\-\.\w]*)\s+(?<value>\w*)$" {
            $parameter = $matches['parameter']
            $configParameterFilter = $matches['value']
            $configParameterValues[$parameter] -split ' ' | Where-Object { $_ -like "$configParameterFilter*" } | Sort-Object
        }

        # scoop <command>
        "^(?<command>\S*)$" {
            return Expand-Commands $matches['command'] $true
        }

        # scoop <command> --<longParameter>
        "^(?<command>$parameterKeys).* --(?<longParameter>\S*)$" {
            $command = $matches['command']
            $longParameterFilter = $matches['longParameter']
            $longParameters[$command] -split ' ' | Where-Object { $_ -like "$longParameterFilter*" } | Sort-Object | ForEach-Object { -join ("--", $_) }
        }

        # scoop <command> -<shortParameter>
        "^(?<command>$parameterKeys).* -(?<shortParameter>\S*)$" {
            $command = $matches['command']
            $shortParameterFilter = $matches['shortParameter']
            $shortParameters[$command] -split ' ' | Where-Object { $_ -like "$shortParameterFilter*" } | Sort-Object | ForEach-Object { -join ("-", $_) }
        }
    }
}

Register-ArgumentCompleter -Native -CommandName (@(Get-Alias | Where-Object { $_.Definition -eq 'scoop' } | Select-Object -ExpandProperty Name) + "scoop") -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $lastBlock = if ($wordToComplete) { $commandAst.ToString() } else { $commandAst.ToString() + ' ' }

    switch -regex ($lastBlock) {
        "^(sudo\s+)?$scoopAliasesRegex\s*(?<rest>.*)$" {
            ScoopTabExpansion $matches['rest']
        }
    }
}
