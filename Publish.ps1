function publish-NVRAppDevOpsModule
{
    UnRegister-PSRepository -Name "NVRTools"
    Register-PSRepository -Name "NVRTools" -SourceLocation "http://tfs:8080/tfs/Dynamics_NAV/_packaging/NVRTools/nuget/v2"
    publish-module -Path .\ -Tags "PSModule" -Repository NVRTools -NuGetApiKey VSTS
}