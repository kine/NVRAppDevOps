function Format-AppNameForNuget
{
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Name
    )

    return $Name -replace '\s','_'
}