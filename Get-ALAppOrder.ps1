function Get-ALAppOrder
{
    Param(
        #Path to the repository
        $Path='.\'
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
            $AppFile
        )
        $AppInfo = Get-NAVAppInfo -Path $AppFile
        $AppJson = New-Object -TypeName PSObject
        $AppJson | Add-Member -MemberType NoteProperty -Name "name" -Value $AppInfo.Name
        $AppJson | Add-Member -MemberType NoteProperty -Name "publisher" -Value $AppInfo.Publisher
        $AppJson | Add-Member -MemberType NoteProperty -Name "version" -Value $AppInfo.Version
        $AppDeps = @()
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

    $AppConfigs = Get-ChildItem -Path $Path -Filter App.json -Recurse
    if ($AppConfigs) {
        $Apps = ConvertTo-ALAppsInfo -Files $AppConfigs
    } else {
        $Apps = @{}
        $AppFiles = Get-ChildItem -Path $Path -Filter *.app
        foreach ($AppFile in $AppFiles) {
            #$App = Get-NAVAppInfo -Path $AppFile.FullName
            $App = Get-AppJsonFromApp -AppFile $AppFile.FullName
            if ($App.publisher -ne 'Microsoft') {
                $Apps.Add($App.name,$App)
            }
        }
    }
    $AppsOrdered = Get-ALBuildOrder -Apps $Apps
    Write-Output $AppsOrdered
}