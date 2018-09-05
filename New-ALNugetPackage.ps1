function New-ALNugetPackage
{
    Param(
        $NuspecFileName,
        $OutputDir
    )
    nuget pack $NuspecFileName -OutputDirectory "$OutputDir"
}