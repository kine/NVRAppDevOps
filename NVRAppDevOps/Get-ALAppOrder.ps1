<#
.SYNOPSIS
    Sort apps into order in which must be compiled/installed to fullfill their dependencies
.DESCRIPTION
    Sort apps into order in which must be compiled/installed to fullfill their dependencies
.EXAMPLE
    PS C:\> Get-ALAppOrder -Path .\
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
    Array of app.json files you want to compile.
.OUTPUTS
    Array of App objects having these members:
        name
        publisher
        version
        AppPath
        dependencies
            name
            publisher
            version

#>
function Get-ALAppOrder
{
    [CMDLetBinding(DefaultParameterSetName="Path")]
    Param(

        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ArtifactUrl,
        #Path to the repository
        [Parameter(ParameterSetName="Path")]
        $Path='.\',
        [switch]$Recurse,
        #Array of Files you want to use
        [Parameter(ValueFromPipelineByPropertyName=$True,ParameterSetName="Collection")]
        [Hashtable]$AppCollection,
        [bool]$IncludeAppFiles=$false
    )

    function ConvertTo-ALAppsInfo
    {
        Param(
            $Files
        )
        $result = @{};
        foreach ($F in $Files) {
            $AppJson = Get-Content -Path $F.FullName | ConvertFrom-Json
            $AppJson | Add-Member -MemberType NoteProperty -Name "AppPath" -Value $F.FullName
            if (-not $result.ContainsKey($AppJson.name)) {
                Write-Verbose "Adding dependency $($AppJson.Name) $($AppJson.Version) *"
                $result.Add($AppJson.name,$AppJson)
            } else {
                $OldApp = $result[$AppJson.name]
                Write-Verbose "Adding dependency $($AppJson.Name) $($AppJson.Version) *"
                if (([Version]$AppJson.Version) -gt ([Version]$OldApp.Version)) {
                    Write-Host "Updating dependency $($OldApp.Version) to $($AppJson.Version) *"
                    $Apps.Remove($AppJson.name)
                    $Apps.Add($AppJson.name,$AppJson)
                }
            }
        }
        return $result
    }

    function Get-ALBuildOrder
    {
        Param(
            $Apps
        )
        $AppsOrdered = @()
        $AppsToAdd = @{}
        $AppsCompiled = @{}
        do {
            foreach($App in $Apps.GetEnumerator()) {
                if (-not $AppsCompiled.ContainsKey($App.Value.name)) {
                    #test if all dependencies are compiled
                    $DependencyOk = $true
                    foreach ($Dependency in $App.Value.dependencies) {
                        Write-Verbose "$($App.Value.Name)->$($Dependency.Name) $($Dependency.version)"
                        if (-not $Apps.Contains($Dependency.name)) {
                            Write-Verbose "Add dependency $($Dependency.name) $($Dependency.version)"
                            $NewApp=New-Object -TypeName PSObject
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'name' -Value $Dependency.name
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'version' -Value $Dependency.version
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'publisher' -Value $Dependency.publisher
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'AppPath' -Value ""

                            if (-not $AppsCompiled.ContainsKey($Dependency.name)) {
                                $AppsCompiled.Add($Dependency.name,$NewApp)
                                $AppsToAdd.Add($Dependency.name,$NewApp)
                                $AppsOrdered += $NewApp
                            } else {
                                $OldApp = $AppsCompiled[$Dependency.name]
                                if (([Version]$Dependency.version) -gt ([Version]$OldApp.Version)) {
                                    Write-Verbose "Replacing dependency $($OldApp.Name) $($OldApp.Version) $($Dependency.name) $($Dependency.version) "
                                    $AppsCompiled.Remove($Dependency.name)
                                    $AppsCompiled.Add($Dependency.name,$NewApp)
                                    $AppsToAdd.Remove($Dependency.name)
                                    $AppsToAdd.Add($Dependency.name,$NewApp)
                                    #$AppsOrdered = $AppsOrdered -replace $OldApp,$NewApp
                                    $AppsOrdered.Item($AppsOrdered.IndexOf($OldApp)).version = $Dependency.version
                                }
                            }
                        } else {
                            Write-Verbose "?Add dependency $($Dependency.name) $($Dependency.version)"
                            $NewApp=New-Object -TypeName PSObject
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'name' -Value $Dependency.name
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'version' -Value $Dependency.version
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'publisher' -Value $Dependency.publisher
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'AppPath' -Value ""

                            $OldApp = $Apps[$Dependency.name]
                            if (([Version]$Dependency.version) -gt ([Version]$OldApp.Version)) {
                                Write-Verbose "Replacing dependency $($OldApp.Name) $($OldApp.Version) $($Dependency.name) $($Dependency.version) "
                                $AppsCompiled.Remove($Dependency.name)
                                $AppsCompiled.Add($Dependency.name,$NewApp)
                                $AppsToAdd.Remove($Dependency.name)
                                $AppsToAdd.Add($Dependency.name,$NewApp)
                                #$AppsOrdered = $AppsOrdered -replace $OldApp,$NewApp
                                $AppsOrdered.Item($AppsOrdered.IndexOf($OldApp)).version = $Dependency.version
                            }
                        }
                        if (-not $AppsCompiled.ContainsKey($Dependency.name)) {
                            $DependencyOk = $false
                        }
                    }
                    if ($DependencyOk) {
                        $AppsOrdered += $App.Value
                        if (-not $AppsCompiled.ContainsKey($App.Value.name)) {
                            $AppsCompiled.Add($App.Value.name,$App.Value)
                        }
                    }
                }
            }
            foreach ($App in $AppsToAdd.GetEnumerator()) {
                if (-not $Apps.ContainsKey($App.Value.name)) {
                    $Apps.Add($App.Value.name,$App.Value)
                }
            }
            $AppsToAdd =@{}
        } while ($Apps.Count -ne $AppsCompiled.Count)
        return $AppsOrdered
    }

    function Get-AppJsonFromApp
    {
        Param(
            $AppFile,
            $ContainerName,
            $ArtifactUrl
        )
        $AppDeps = @()
        if ($ArtifactUrl) {
            import-module (Get-BCModulePathFromArtifact -artifactPath ((Download-Artifacts -artifactUrl $artifactUrl -includePlatform)[1]))
            $AppInfo = Get-NavAppInfo -Path $AppFile
        } else {
            $AppInfo = Get-NavContainerAppInfoFile -AppPath $AppFile -ContainerName $ContainerName
        }
        $AppJson = New-Object -TypeName PSObject
        $AppJson | Add-Member -MemberType NoteProperty -Name "name" -Value $AppInfo.Name
        $AppJson | Add-Member -MemberType NoteProperty -Name "publisher" -Value $AppInfo.Publisher
        $AppJson | Add-Member -MemberType NoteProperty -Name "version" -Value $AppInfo.Version
        foreach ($AppDep in $AppInfo.Dependencies) {
            $AppDepJson = New-Object -TypeName PSObject
            $AppDepJson | Add-Member -MemberType NoteProperty -Name "name" -Value $AppDep.Name
            $AppDepJson | Add-Member -MemberType NoteProperty -Name "publisher" -Value $AppDep.Publisher
            $AppDepJson | Add-Member -MemberType NoteProperty -Name "version" -Value $AppDep.MinVersion
            $AppDeps += $AppDepJson
        }
        $AppJson | Add-Member -MemberType NoteProperty -Name "dependencies" -Value $AppDeps
        $AppJson | Add-Member -MemberType NoteProperty -Name "AppPath" -Value $AppFile
        return $AppJson
    }

    if($AppCollection) {
        $Apps = $AppCollection
    }
    else {
        $AppConfigs = Get-ChildItem -Path $Path -Filter App.json -Recurse
        if ($AppConfigs) {
            $Apps = ConvertTo-ALAppsInfo -Files $AppConfigs
        }
    }

    if((-not $Apps) -or ($IncludeAppFiles)) {
        if (-not $Apps) {
            $Apps = @{}
        }
        $AppFiles = Get-ChildItem -Path $Path -Filter *.app -Recurse:$Recurse
        foreach ($AppFile in $AppFiles) {
            $App = Get-AppJsonFromApp -AppFile $AppFile.FullName -ContainerName $ContainerName -ArtifactUrl $ArtifactUrl
            if ($App.publisher -ne 'Microsoft') {
                if (-not $Apps.ContainsKey($App.name)) {
                    Write-Host "Adding dependency $($App.Name) $($App.Version)"
                    $Apps.Add($App.name,$App)
                } else {
                    $OldApp = $Apps[$App.Name]
                    Write-Host "Adding dependency $($App.Name) $($App.Version) *"
                    if (([Version]$App.Version) -gt ([Version]$OldApp.Version)) {
                        Write-Host "Updating dependency $($OldApp.Version) to $($App.Version) *"
                        $Apps.Remove($App.name)
                        $Apps.Add($App.name,$App)
                    }
                }
            }
        }
    }

    $AppsOrdered = Get-ALBuildOrder -Apps $Apps
    Write-Output $AppsOrdered
}
