function Get-CurrentModuleVersion {
    return $MyInvocation.MyCommand.ScriptBlock.Module.Version.ToString();
}