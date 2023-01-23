function Format-AppNameForNuget
{
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Name
    )

    return $Name -replace '\s','_' -replace '&','_' -replace '(','_' -replace ')','_'
}