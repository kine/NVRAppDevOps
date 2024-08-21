<#
.SYNOPSIS
    Sort apps into order in which must be compiled/installed to fullfill their dependencies
.DESCRIPTION
    Sort apps into order in which must be compiled/installed to fullfill their dependencies. Key in the hash table is ID of the app.
.EXAMPLE
    PS C:\> Get-ALAppOrderByID -Path .\
    Read all app.json from the subfolders and sort the app objects
.Parameter ContainerName
    Name of the container to use to get info from .App file
.Parameter ArtifactUrl
    Url of artifact to be used to get BC PS modules without using container
.Parameter Path
    Folder in which the app.json will be searched. If no app.json is found, all *.app packages will be used.
.Parameter Recurse
    Will search for files recursively
.Parameter AppCollection
    Array of app.json files you want to compile. Key is the ID of the app
.OUTPUTS
    Array of App objects having these members:
        id
        name
        publisher
        version
        AppPath
        dependencies
            id
            name
            publisher
            version

#>
function Get-ALAppOrderByID {
    [CMDLetBinding(DefaultParameterSetName = "Path")]
    Param(

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $ContainerName,
        [Parameter(ValueFromPipelineByPropertyName = $True)]
        $ArtifactUrl,
        #Path to the repository
        [Parameter(ParameterSetName = "Path")]
        $Path = '.\',
        [switch]$Recurse,
        #Array of Files you want to use
        [Parameter(ValueFromPipelineByPropertyName = $True, ParameterSetName = "Collection")]
        [Hashtable]$AppCollection,
        [bool]$IncludeAppFiles = $false
    )

    function ConvertTo-ALAppsInfo {
        Param(
            $Files
        )
        $result = @{};
        foreach ($F in $Files) {
            $AppJson = Get-Content -Path $F.FullName | ConvertFrom-Json
            $AppJson | Add-Member -MemberType NoteProperty -Name "AppPath" -Value $F.FullName
            $Key = $AppJson.id
            if (-not $result.ContainsKey($Key)) {
                Write-Verbose "Adding dependency $($Key) $($AppJson.Name) $($AppJson.Version) *"
                $result.Add($Key, $AppJson)
            }
            else {
                $OldApp = $result[$Key]
                Write-Verbose "Adding dependency $($Key) $($AppJson.Name) $($AppJson.Version) *"
                $NewVersion = [Version]$AppJson.Version
                $OldVersion = [Version]$OldApp.Version
                if (($NewVersion) -gt ($OldVersion)) {
                    Write-Host "Updating dependency $($OldApp.Version) to $($AppJson.Version) *"
                    $Apps.Remove($Key)
                    $Apps.Add($Key, $AppJson)
                }
            }
        }
        return $result
    }

    function Get-ALBuildOrder {
        Param(
            $Apps
        )
        $AppsOrdered = @()
        $AppsToAdd = @{}
        $AppsCompiled = @{}
        $Level = 0
        do {
            $Level += 1
            $unresolvedDependencies = @{}
            Write-Verbose "------ $Level -----"
            foreach ($App in $Apps.GetEnumerator()) {
                if (-not $AppsCompiled.ContainsKey($App.Value.id)) {
                    #test if all dependencies are compiled
                    $DependencyOk = $true
                    foreach ($Dependency in $App.Value.dependencies) {
                        Write-Verbose "$($App.Value.id)->$($Dependency.id) $($App.Value.name)->$($Dependency.name) $($Dependency.version)"
                        if (-not $Apps.Contains($Dependency.id)) {
                            Write-Verbose "Add dependency $($Dependency.id) $($Dependency.name) $($Dependency.version)"
                            $NewApp = New-Object -TypeName PSObject
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'name' -Value $Dependency.name
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'version' -Value $Dependency.version
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'publisher' -Value $Dependency.publisher
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'id' -Value $Dependency.id
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'AppPath' -Value ""
    
                            if (-not $AppsCompiled.ContainsKey($Dependency.id)) {
                                $AppsCompiled.Add($Dependency.id, $NewApp)
                                $AppsToAdd.Add($Dependency.id, $NewApp)
                                $AppsOrdered += $NewApp
                            }
                            else {
                                $OldApp = $AppsCompiled[$Dependency.id]
                                if (([Version]$Dependency.version) -gt ([Version]$OldApp.Version)) {
                                    Write-Verbose "Replacing dependency $($OldApp.id) $($OldApp.Name) $($OldApp.Version) $($Dependency.id) $($Dependency.name) $($Dependency.version) "
                                    $AppsCompiled.Remove($Dependency.id)
                                    $AppsCompiled.Add($Dependency.id, $NewApp)
                                    $AppsToAdd.Remove($Dependency.id)
                                    $AppsToAdd.Add($Dependency.id, $NewApp)
                                    $a = $AppsOrdered | where-object { $_.id -eq $OldApp.id }
                                    $a.version = $Dependency.version
                                }
                            }
                        } 
                        if (-not $AppsCompiled.ContainsKey($Dependency.id)) {
                            $DependencyOk = $false
                            if (-not $unresolvedDependencies.ContainsKey($Dependency.id)) {
                                Write-Verbose "Unresolved $($App.Value.id)->$($Dependency.id) $($App.Value.Name)->$($Dependency.Name) $($Dependency.version)"
                                $unresolvedDependencies.Add($Dependency.id, $Dependency)
                            }
                        }
                    }
                    if ($DependencyOk) {
                        $AppsOrdered += $App.Value
                        if (-not $AppsCompiled.ContainsKey($App.Value.id)) {
                            $AppsCompiled.Add($App.Value.id, $App.Value)
                        }
                    }
                }
            }
            foreach ($App in $AppsToAdd.GetEnumerator()) {
                if (-not $Apps.ContainsKey($App.Value.id)) {
                    $Apps.Add($App.Value.id, $App.Value)
                }
            }
            $AppsToAdd = @{}
        } while ($Apps.Count -ne $AppsCompiled.Count -and (($unresolvedDependencies.Count -eq 0) -or ($Level -lt 20)))
        if ($unresolvedDependencies.Count -gt 0) {
            Write-Error "Unresolved dependencies: $($unresolvedDependencies.Keys -join ', ')"
        }
        return $AppsOrdered
    }
    function Get-AppJsonFromApp {
        Param(
            $AppFile,
            $ContainerName,
            $ArtifactUrl
        )
        $AppDeps = @()
        if (Get-Command -Module bccontainerhelper -Name Get-AppJsonFromAppFile) {
            $AppInfo = Get-AppJsonFromAppFile -appFile $AppFile
        }
        else {
            if ($ArtifactUrl) {
                if (-not $global:BCModuleImported) {
                    import-module (Get-BCModulePathFromArtifact -artifactPath ((Download-Artifacts -artifactUrl $artifactUrl -includePlatform)[1]))
                    $global:BCModuleImported = $true
                }
                $AppInfo = Get-NavAppInfo -Path $AppFile
            }
            else {
                $AppInfo = Get-NavContainerAppInfoFile -AppPath $AppFile -ContainerName $ContainerName
            }
        }
        $AppJson = New-Object -TypeName PSObject
        $AppJson | Add-Member -MemberType NoteProperty -Name "name" -Value $AppInfo.Name
        $AppJson | Add-Member -MemberType NoteProperty -Name "publisher" -Value $AppInfo.Publisher
        $AppJson | Add-Member -MemberType NoteProperty -Name "id" -Value $AppInfo.Id
        $AppJson | Add-Member -MemberType NoteProperty -Name "version" -Value $AppInfo.Version
        foreach ($AppDep in $AppInfo.Dependencies) {
            $AppDepJson = New-Object -TypeName PSObject
            $AppDepJson | Add-Member -MemberType NoteProperty -Name "name" -Value $AppDep.Name
            $AppDepJson | Add-Member -MemberType NoteProperty -Name "publisher" -Value $AppDep.Publisher
            if ($AppDep.AppId) {
                $AppDepJson | Add-Member -MemberType NoteProperty -Name "id" -Value $AppDep.AppId
            }
            else {
                $AppDepJson | Add-Member -MemberType NoteProperty -Name "id" -Value $AppDep.Id
            }
            $AppDepJson | Add-Member -MemberType NoteProperty -Name "version" -Value $AppDep.MinVersion
            $AppDeps += $AppDepJson
        }
        $AppJson | Add-Member -MemberType NoteProperty -Name "dependencies" -Value $AppDeps
        $AppJson | Add-Member -MemberType NoteProperty -Name "AppPath" -Value $AppFile
        return $AppJson
    }

    if ($AppCollection) {
        $Apps = $AppCollection
    }
    else {
        $AppConfigs = Get-ChildItem -Path $Path -Filter App.json -Recurse
        if ($AppConfigs) {
            $Apps = ConvertTo-ALAppsInfo -Files $AppConfigs
        }
    }

    if ((-not $Apps) -or ($IncludeAppFiles)) {
        if (-not $Apps) {
            $Apps = @{}
        }
        $AppFiles = Get-ChildItem -Path $Path -Filter *.app -Recurse:$Recurse
        foreach ($AppFile in $AppFiles) {
            $App = Get-AppJsonFromApp -AppFile $AppFile.FullName -ContainerName $ContainerName -ArtifactUrl $ArtifactUrl
            if ($App.publisher -ne 'Microsoft') {
                if (-not $Apps.ContainsKey($App.id)) {
                    Write-Verbose "Adding dependency $($App.id) $($App.Name) $($App.Version)"
                    $Apps.Add($App.id, $App)
                }
                else {
                    $OldApp = $Apps[$App.id]
                    Write-Host "Adding dependency $($App.id) $($App.Name) $($App.Version) *"
                    if ($App.version.GetType().Name -eq 'PSCustomObject') {
                        $NewVersion = [version]::new($App.version.Major, $App.version.Minor, $App.version.Build, $App.version.Revision)
                    }
                    else {
                        $NewVersion = [version]($App.version)
                    }
                    if ($OldApp.version.GetType().Name -eq 'PSCustomObject') {
                        $OldVersion = [version]::new($OldApp.version.Major, $OldApp.version.Minor, $OldApp.version.Build, $OldApp.version.Revision)
                    }
                    else {
                        $OldVersion = [version]($OldApp.version)
                    }
                    if (($NewVersion) -gt ($OldVersion)) {
                        Write-Host "Updating dependency $($OldApp.Version) to $($App.Version) *"
                        $Apps.Remove($App.id)
                        $Apps.Add($App.id, $App)
                    }
                }
            }
        }
    }

    $AppsOrdered = Get-ALBuildOrder -Apps $Apps
    Write-Output $AppsOrdered
}
