function ConvertTo-PaketDependencies {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        [string[]]$NuGetSources = @(),
        [ValidateSet('Max', 'Min')]
        [string]$Policy = 'Min',
        [string]$Localization,
        [switch]$Symbols,
        [version]$MaxApplicationVersion,
        [version]$MaxPlatformVersion
    )
    if ($Localization -ieq 'W1') {
        $Localization = ''
    }
    $AppJsonPath = Join-Path $ProjectPath "app.json"
    if (-not (Test-Path $AppJsonPath)) {
        Write-Error "app.json not found in $ProjectPath"
        return
    }

    $PaketDependenciesFilePath = Join-Path $ProjectPath "paket.dependencies"

    if (Test-Path $PaketDependenciesFilePath) {
        $OldContent = Get-Content $PaketDependenciesFilePath
    }

    if ((-not $NuGetSources) -and ($OldContent)) {
        Write-Verbose "No NuGet sources specified, using sources from existing paket.dependencies file"
        $NuGetSources = $OldContent | Where-Object { $_ -match '^source\s' } | ForEach-Object { $_ -replace '^source\s', '' }
    }

    $AppJson = Get-Content $AppJsonPath | ConvertFrom-Json
    $AppJsonDependencies = $AppJson.dependencies

    $PaketDependencies = New-Object System.Collections.ArrayList

    if ($Policy -eq 'Max') {
        $PaketDependencies.Add("strategy: max           # use the maximum version of transitive dependencies") | out-null
        $PaketDependencies.Add("lowest_matching: false  # use the highest matching version of a direct dependency") | out-null
        $PackageSuffix = "`tstrategy:min, lowest_matching:false"
    }
    else {
        $PaketDependencies.Add("strategy: min           # use the minimum version of transitive dependencies") | out-null
        $PaketDependencies.Add("lowest_matching: true   # use the lowest matching version of a direct dependency") | out-null
        $PackageSuffix = "`tstrategy:min, lowest_matching:true"
    }
    $PaketDependencies.Add("") | out-null

    foreach ($Source in $NuGetSources) {
        $PaketDependencies.Add("source $Source") | out-null
    }
    $PaketDependencies.Add("") | out-null
    $tag = $Localization
    if ($Symbols) {
        $tag += '.Symbols'
    }
    foreach ($Dependency in $AppJsonDependencies) {
        $DependencyName = Format-AppNameForNuget -appname $Dependency.name -publisher $Dependency.publisher -version $Dependency.version -id $Dependency.id -tag $tag -NuGetSources $NuGetSources
        $PaketDependencies.Add("nuget $($DependencyName) >= $($Dependency.version)") | out-null
    }
    if ($AppJson.application) {
        $AppDependency = @{
            appId     = ''
            name      = "Application"
            publisher = 'Microsoft'
            version   = $AppJson.application
        }
        $DependencyName = Format-AppNameForNuget -appname $AppDependency.name -publisher $AppDependency.publisher -version $AppDependency.version -id $AppDependency.appId -tag $tag
        $MaxLimit = ''
        if ($MaxApplicationVersion) {
            $MaxLimit = '~> ' + $MaxApplicationVersion
        }
        $PaketDependencies.Add("nuget $($DependencyName) $($MaxLimit) >= $($AppDependency.version) $($PackageSuffix)") | out-null
    }
    if ($AppJson.platform) {
        $AppDependency = @{
            appId     = ''
            name      = "Platform"
            publisher = 'Microsoft'
            version   = $AppJson.platform
        }
        $tag = ''
        if ($Symbols) {
            $tag = 'Symbols'
        }
        $DependencyName = Format-AppNameForNuget -appname $AppDependency.name -publisher $AppDependency.publisher -version $AppDependency.version -id $AppDependency.appId -tag $tag
        $MaxLimit = ''
        if ($MaxPlatformVersion) {
            $MaxLimit = '~> ' + $MaxPlatformVersion
        }
        $PaketDependencies.Add("nuget $($DependencyName) $($MaxLimit) >= $($AppDependency.version) $($PackageSuffix)") | out-null
    }

    $PaketDependencies | Out-File $PaketDependenciesFilePath -Encoding utf8
}