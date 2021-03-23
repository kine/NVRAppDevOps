function Compile-AppWithArtifact
{
    param(
        [parameter(Mandatory=$true)]
        [string]$alcPath,
        [parameter(Mandatory=$true)]
        [string]$artifactUrl,
        [parameter(Mandatory=$true)]
        [string]$appProjectFolder,
        [parameter(Mandatory=$true)]
        [string]$appOutputFolder,
        [parameter(Mandatory=$true)]
        [string]$appSymbolsFolder,
        [switch]$AzureDevOps,
        [switch]$EnableCodeCop,
        [switch]$EnableAppSourceCop,
        [switch]$EnablePerTenantExtensionCop,
        [switch]$EnableUICop,
        [ValidateSet('none','error','warning')]
        [string] $FailOn = 'none',
        [string]$rulesetFile,
        [string]$assemblyProbingPaths,
        [scriptblock] $outputTo = { Param($line) Write-Host $line }
    )
    $startTime = [DateTime]::Now
    $appJsonFile = Join-Path $appProjectFolder 'app.json'
    $appJsonObject = [System.IO.File]::ReadAllLines($appJsonFile) | ConvertFrom-Json
    if ("$appName" -eq "") {
        $appName = "$($appJsonObject.Publisher)_$($appJsonObject.Name)_$($appJsonObject.Version).app".Split([System.IO.Path]::GetInvalidFileNameChars()) -join ''
    }

    Write-Host "Using Symbols Folder: $appSymbolsFolder"
    if (!(Test-Path -Path $appSymbolsFolder -PathType Container)) {
        New-Item -Path $appSymbolsFolder -ItemType Directory | Out-Null
    }

    Write-Host 'Copying Microsoft apps from artifact folder'
    $ArtifactPaths = Download-Artifacts -artifactUrl $artifactUrl -includePlatform
    if (-not (Test-Path (Join-Path $ArtifactPaths[0] 'Applications'))) {
        $AppPath = $ArtifactPaths[1]
    } else {
        $AppPath = $ArtifactPaths[0]
    }
    (Join-Path $ArtifactPaths[1] "\ModernDev\program files\Microsoft Dynamics NAV\*\AL Development Environment\System.app"),
    (Join-Path $AppPath "\Applications\Application\Source\Microsoft_Application.app"),
    (Join-Path $AppPath "\Applications\BaseApp\Source\Microsoft_Base Application.app"),
    (Join-Path $AppPath "\Applications\System Application\source\Microsoft_System Application.app")| ForEach-Object {
        if ($_) {
            if (-not (Test-Path (Join-Path $appSymbolsFolder (Split-Path $_ -Leaf)))) {
                Write-Host "Copying $([System.IO.Path]::GetFileName($_)) "
                Copy-Item -Path $_ -Destination $appSymbolsFolder -Force
            }
        } 
    }
    import-module (Get-BCModulePathFromArtifact -artifactPath ((Download-Artifacts -artifactUrl $artifactUrl -includePlatform)[1]))

    $MSAppsFiles = Get-ChildItem -Path $AppPath -Filter *.app -Recurse
    $MSApps = @()
    foreach($File in $MSAppsFiles) {
        $AppInfo = get-navappinfo -Path $File.FullName
        $AppJson = New-Object -TypeName PSObject
        $AppJson | Add-Member -MemberType NoteProperty -Name "id" -Value $AppInfo.id
        $AppJson | Add-Member -MemberType NoteProperty -Name "name" -Value $AppInfo.Name
        $AppJson | Add-Member -MemberType NoteProperty -Name "publisher" -Value $AppInfo.Publisher
        $AppJson | Add-Member -MemberType NoteProperty -Name "version" -Value $AppInfo.Version
        $AppJson | Add-Member -MemberType NoteProperty -Name "file" -Value $File.FullName
        $MSApps += $AppJson
    }

    $dependencies = @()

    if (([bool]($appJsonObject.PSobject.Properties.name -eq "application")) -and $appJsonObject.application)
    {
        $dependencies += @{"publisher" = "Microsoft"; "name" = "Application"; "version" = $appJsonObject.application }
    }

    if (([bool]($appJsonObject.PSobject.Properties.name -eq "platform")) -and $appJsonObject.platform)
    {
        $dependencies += @{"publisher" = "Microsoft"; "name" = "System"; "version" = $appJsonObject.platform }
    }

    if (([bool]($appJsonObject.PSobject.Properties.name -eq "test")) -and $appJsonObject.test)
    {
        $dependencies +=  @{"publisher" = "Microsoft"; "name" = "Test"; "version" = $appJsonObject.test }
        if (([bool]($customConfig.PSobject.Properties.name -eq "EnableSymbolLoadingAtServerStartup")) -and ($customConfig.EnableSymbolLoadingAtServerStartup -eq "true")) {
            throw "app.json should NOT have a test dependency when running hybrid development (EnableSymbolLoading)"
        }
    }

    if (([bool]($appJsonObject.PSobject.Properties.name -eq "dependencies")) -and $appJsonObject.dependencies)
    {
        $appJsonObject.dependencies | ForEach-Object {
            $dependencies += @{ "publisher" = $_.publisher; "name" = $_.name; "version" = $_.version }
        }
    }

    Write-Host "Looking for missing MS dependencies"
    foreach($dep in ($dependencies | Where-Object {$_.publisher -like 'Microsoft'})) {
        $MSAppFile = $MSApps | Where-Object {($_.name -eq $dep.name) -and ($_.publisher -eq $dep.publisher)}
        if ($MSAppFile) {
            if (-not (Test-Path (Join-Path $appSymbolsFolder (Split-Path $MSAppFile -Leaf)))) {
                Write-Host "Copying $([System.IO.Path]::GetFileName($MSAppFile.file)) "
                Copy-Item -Path $MSAppFile.file -Destination $appSymbolsFolder -Force
            }
        }
    }
    $result = Invoke-Command -ScriptBlock {
        Param($binPath,$appProjectFolder, $appSymbolsFolder, $appOutputFile, $EnableCodeCop, $EnableAppSourceCop, $EnablePerTenantExtensionCop, $EnableUICop, $rulesetFile, $assemblyProbingPaths, $nowarn, $generateReportLayoutParam, $features, $preProcessorSymbols )

        Push-Location
        set-location $binPath
   
        #Add-Type -AssemblyName System.IO.Compression.FileSystem
        #Add-Type -AssemblyName System.Text.Encoding
        # Import types needed to invoke the compiler
        #Add-Type -Path (Join-Path $alcPath System.Collections.Immutable.dll)
        #Add-Type -Path (Join-Path $alcPath Microsoft.Dynamics.Nav.CodeAnalysis.dll)
        $alcParameters = @("/project:""$($appProjectFolder.TrimEnd('/\'))""", "/packagecachepath:""$($appSymbolsFolder.TrimEnd('/\'))""", "/out:""$appOutputFile""")
        if ($EnableCodeCop) {
            $alcParameters += @("/analyzer:$(Join-Path $binPath 'Analyzers\Microsoft.Dynamics.Nav.CodeCop.dll')")
        }
        if ($EnableAppSourceCop) {
            $alcParameters += @("/analyzer:$(Join-Path $binPath 'Analyzers\Microsoft.Dynamics.Nav.AppSourceCop.dll')")
        }
        if ($EnablePerTenantExtensionCop) {
            $alcParameters += @("/analyzer:$(Join-Path $binPath 'Analyzers\Microsoft.Dynamics.Nav.PerTenantExtensionCop.dll')")
        }
        if ($EnableUICop) {
            $alcParameters += @("/analyzer:$(Join-Path $binPath 'Analyzers\Microsoft.Dynamics.Nav.UICop.dll')")
        }
        
        if ($rulesetFile) {
            $alcParameters += @("/ruleset:$rulesetfile")
        }
        if ($assemblyProbingPaths) {
            $alcParameters += @("/assemblyprobingpaths:$assemblyProbingPaths")
        }
        
        Write-Host ".\alc.exe $([string]::Join(' ', $alcParameters))"
        
        & .\alc.exe $alcParameters
        Pop-Location
        if ($lastexitcode -ne 0) {
            "App generation failed with exit code $lastexitcode"
        }
    } -ArgumentList $alcPath,$appProjectFolder, $appSymbolsFolder, (Join-Path $appOutputFolder $appName), $EnableCodeCop, $EnableAppSourceCop, $EnablePerTenantExtensionCop, $EnableUICop, $containerRulesetFile, $assemblyProbingPaths, $nowarn, $GenerateReportLayoutParam, $features, $preProcessorSymbols

    $devOpsResult = ""
    if ($result) {
        $devOpsResult = Convert-ALCOutputToAzureDevOps -FailOn $FailOn -AlcOutput $result -DoNotWriteToHost
    }
    if ($AzureDevOps) {
        $devOpsResult | % { $outputTo.Invoke($_) }
    }    else {
        $result | % { $outputTo.Invoke($_) }
        if ($devOpsResult -like "*task.complete result=Failed*") {
            throw "App generation failed"
        }
    }
    $result | Where-Object { $_ -like "App generation failed*" } | % { throw $_ }
    $timespend = [Math]::Round([DateTime]::Now.Subtract($startTime).Totalseconds)
    $appFile = Join-Path $appOutputFolder $appName
    if (Test-Path -Path $appFile) {
        Write-Host "$appFile successfully created in $timespend seconds"
        if ($CopyAppToSymbolsFolder) {
            Copy-Item -Path $appFile -Destination $appSymbolsFolder -ErrorAction SilentlyContinue
            if (Test-Path -Path (Join-Path -Path $appSymbolsFolder -ChildPath $appName)) {
                Write-Host "${appName} copied to ${appSymbolsFolder}"
            }
        }
    }
    else {
        throw "App generation failed"
    }
    $appFile
}