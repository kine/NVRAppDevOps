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
        $AppsOrdered = @();
        $AppsCompiled = @{};
        do {
            foreach($App in $Apps.GetEnumerator()) {
                if (-not $AppsCompiled.ContainsKey($App.Value.name)) {
                    #test if all dependencies are compiled
                    $DependencyOk = $true
                    foreach ($Dependency in $App.Value.dependencies) {
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
        } while ($Apps.Count -ne $AppsCompiled.Count)
        return $AppsOrdered
    }
    $AppConfigs = Get-ChildItem -Path $Path -Filter App.json -Recurse
    $Apps = ConvertTo-ALAppsInfo -Files $AppConfigs
    $AppsOrdered = Get-ALBuildOrder -Apps $Apps
    Write-Output $AppsOrdered
}