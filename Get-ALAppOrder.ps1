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
    Param(

        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName,
        #Path to the repository
        [Parameter(ParameterSetName="Path")]
        $Path='.\',
        [switch]$Recurse,
        #Array of Files you want to use
        [Parameter(ValueFromPipelineByPropertyName=$True,ParameterSetName="Collection")]
        [Array]$AppCollection
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
            $result.Add($AppJson.name,$AppJson)
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
                        if (-not $Apps.Contains($Dependency.name)) {
                            $NewApp=New-Object -TypeName PSObject
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'name' -Value $Dependency.name
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'version' -Value $Dependency.version
                            $NewApp | Add-Member -MemberType NoteProperty -Name 'AppPath' -Value ""

                            if (-not $AppsCompiled.ContainsKey($Dependency.name)) {
                                $AppsCompiled.Add($Dependency.name,$NewApp)
                                $AppsToAdd.Add($Dependency.name,$NewApp)
                                $AppsOrdered += $NewApp
                            }
                        }
                        if (-not $AppsCompiled.ContainsKey($Dependency.name)) {
                            $DependencyOk = $false
                        }
                    }
                    if ($DependencyOk) {
                        $AppsOrdered += $App.Value
                        $AppsCompiled.Add($App.Value.name,$App.Value)
                    }
                }
            }
            foreach ($App in $AppsToAdd.GetEnumerator()) {
                $Apps.Add($App.Value.name,$App.Value)
            }
            $AppsToAdd =@{}
        } while ($Apps.Count -ne $AppsCompiled.Count)
        return $AppsOrdered
    }

    function Get-AppJsonFromApp
    {
        Param(
            $AppFile,
            $ContainerName
        )
        $AppDeps = @()
        $AppInfo = Get-NavContainerAppInfoFile -AppPath $AppFile -ContainerName $ContainerName
        $AppJson = New-Object -TypeName PSObject
        $AppJson | Add-Member -MemberType NoteProperty -Name "name" -Value $AppInfo.Name
        $AppJson | Add-Member -MemberType NoteProperty -Name "publisher" -Value $AppInfo.Publisher
        $AppJson | Add-Member -MemberType NoteProperty -Name "version" -Value $AppInfo.Version
        foreach ($AppDep in $AppInfo.Dependencies) {
            $AppDepJson = New-Object -TypeName PSObject
            $AppDepJson | Add-Member -MemberType NoteProperty -Name "name" -Value $AppDep.Name
            $AppDepJson | Add-Member -MemberType NoteProperty -Name "version" -Value $AppDep.MinVersion
            $AppDepJson | Add-Member -MemberType NoteProperty -Name "publisher" -Value $AppDep.Publisher
            $AppDeps += $AppDepJson
        }
        $AppJson | Add-Member -MemberType NoteProperty -Name "dependencies" -Value $AppDeps
        $AppJson | Add-Member -MemberType NoteProperty -Name "AppPath" -Value $AppFile
        return $AppJson
    }

    if($Path) {
        $AppConfigs = Get-ChildItem -Path $Path -Filter App.json -Recurse
        $Apps = ConvertTo-ALAppsInfo -Files $AppConfigs
    }
    else {
        $Apps = $AppCollection
    }

    if(-not $Apps) {
        $Apps = @{}
        $AppFiles = Get-ChildItem -Path $Path -Filter *.app -Recurse:$Recurse
        foreach ($AppFile in $AppFiles) {
            #$App = Get-NAVAppInfo -Path $AppFile.FullName
            $App = Get-AppJsonFromApp -AppFile $AppFile.FullName -ContainerName $ContainerName
            if ($App.publisher -ne 'Microsoft') {
                $Apps.Add($App.name,$App)
            }
        }
    }

    $AppsOrdered = Get-ALBuildOrder -Apps $Apps
    Write-Output $AppsOrdered
}