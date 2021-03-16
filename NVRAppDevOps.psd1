#
# Module manifest for module 'PSGet_NVRAppDevOps'
#
# Generated by: Kamil Sacek
#
# Generated on: 13.06.2018
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'NVRAppDevOps.psm1'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'dc28788e-07b6-42c2-88b0-7cdc5fa6abd6'

# Author of this module
Author = 'Kamil Sacek'

# Company or vendor of this module
CompanyName = 'NAVERTICA a.s.'

# Copyright statement for this module
Copyright = '(c) 2018-2020 Kamil Sacek'

# Description of the functionality provided by this module
Description = 'cmdlets for DevOps for Business Central'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(
    @{
        ModuleName='BcContainerHelper'
        ModuleVersion='1.0.0'
        Guid='8e034fbc-8c30-446d-bbc3-5b3be5392491'
    }
    )

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = '*'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Version number of this module.
ModuleVersion = '2.0.2'


# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{
        Prerelease = ''

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'PSModule'

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://www.github.com/kine/NVRAppDevOps'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @'
2.0.2
- Add Import-BCModulesFromArtifacts

2.0.0
- Changed dependency on bccontainerhelper
- Add parameter DependencyVersion parameter to Download-ALAppFromNuget
- If LatestMinor used, list the available versions and select the corect version based on Major
- do not download Microsoft apps through download script when compiling
- Add IncludeAppFiles switch to Get-ALAppOrder

1.1.8
- Add Get-BatchWI to get multiple WIs in one call

1.1.7
- Add Expand parameter to Get-WI

1.1.1-1.1.5
- ArtifactUrl support - see https://freddysblog.com/
- Get-WI double api-version bug fix

1.1.0
- Artifacts support (preview)

1.0.11
- Add [bool]alwaysPull parameter to Init-ALEnvironment (default false, was false in older vesions)

1.0.9
- Add Get-WIFieldDefault to read default value for WI field (default values are not part of the data returned by Get-WI)

1.0.8
- Add Get-WI to get Work Item from Azure DevOps and Get-WIQResult to run WIQL and get the result

1.0.5
- Add AppPath to RulesetFile path if relative path used

1.0.4
- Add parameters RulesetFile and AsmProbingPaths to Compile-ALProjectTree

1.0.3
- Fix Add-ArtifactView authentication under Azure DevOps pipeline

1.0.2
- Remove Required from PAT parameter of Add-ArtifactView

1.0.1
- Add OAuth authorization to Add-ArtifactView
        
1.0.0
- Add function Add-ArtifactView to add view to Azure DevOps artifact
- Decided to make it v1.0.0 because already using it for long time and seems without issues

0.9.98
- Add useBestContainerOS parameter into init-alenvironment

0.9.97
- Fixed "Exception calling "Add" with "2" argument(s): "Item has already been added. Key in dictionary:"

0.9.96
- Add CustomScripts parameter support for config commands (Thanks Koubek)

0.9.95
- Add returnTrueIfAllPassed to Run-ALTestInContainer

0.9.94
- Fix Test webservice creation in Init-ALEnvironment for pre-BC15 versions (thanks kfuglsang)

0.9.93
- Remove warnings from Get-ContainerImageCurrentenss because the results are not reliable

0.9.92
- companyName parameter added to Run-ALTestInContainer

0.9.91
- TestLibraryOnly parameter added for configuration to import only test libraries when needed
- Support for extensionId and restartContainerAndRetry parameters when running tests in container

0.9.90
- Reverted the fixes and merged simplified version of Get-ContainerImageCurrentness to solve issue #25

0.9.89
- Fixed function Get-ContainerImageCurrentness to parse repository automatically from Image parameter

0.9.88
- Pull image only if newer available (Thanks to Sven Niehus)
- Added license file

0.9.87
- Fix NuSpec creatinon for BC v15.x - now ignoring Microsoft dependencies

0.9.86
- Fixed Read-ALConfiguration ignoring Auth and other parameters from .json config

0.9.85
- Add support for different Instance Name than NAV (BC) (thanks kfuglsang)

0.9.84
- Add parameter IncludeCSide (true by default if not set) for using in Init-ALEnvironment for v15.x containers

0.9.83
- Fixes from kfuglsang around file path and company name in URL

0.9.82
- Add parameter to support ssl (thanks MaxBelohoubek)

0.9.81
- Add parameter to install latest nuget package version instead specific version

0.9.80
- Add key parameter to Download-ALAppFromNuget to pass the key for e.g. Azure DevOps Artifacts feed

0.9.78
- Add Source and SourceUrl to Download-ALAppFromNuget

0.9.76
- Fixed 'Illegal value in myScripts' error

0.9.75
- Added myScripts parameter to Init-ALEnvironment (thanks MaxBelohoubek)

0.9.74
- Added parameters to choose CodeCops on Compile-ALProjectTree (thanks MJECloud)
- Small fixes of messages
- Change of dependency name format in New-ALNuSpec - by default set to $($Dep.publisher)_$($Dep.name) but could be changed by parameter

0.9.73
- Added DependencyFormat to New-ALNuSpec which by default format the dependencies in format Publisher_AppName

0.9.72
- Fixed SkipVerification flag error "Cannot process argument transformation on parameter 'skipVerification'. Cannot convert value"

0.9.71
- Fixed bug when Azure DevOps build no. was not updated in Set-ALAppBuildNo

0.9.70
- Add parameters useDevEndpoint and tenant and ForceSync mode to Publish-ALAppTree

0.9.69
- Set-ALAppBuildNo extended with new parameters and return the version as a result

0.9.68
- Isolation parameter is null fixed

0.9.67
- Fixed Isolation parameter

0.9.66
- Fixed usage of isolation during Build processes
- Add WaitForResult switch to Upload-PerTenantApp cmdlet to wait till the publishing is done

0.9.65
- Fixed usage of isolation during Build processes

0.9.64
- Added parameter Isolation to override the isolation level (e.g. when falling back to Hyper-V because differrent build no. of OS and container)

0.9.63
- Add Verbose to BCAPIData functions to show called URL
        
0.9.62
- Add APIVersion into Upload-PerTenantApp function to support named sandboxes

0.9.61
- Add APIVersion to Get/Post/Patch-BCAPIData to support v2.0 and other versions for BC v14.0. Use the v2.0 for usage with named sandboxes in BC v14!        

0.9.60
- Add functions for GET/POST/PATCH with Business Central API using OAuth2, Upload-PerTenantApp function

0.9.59
- Fixed script invocation in container when non-admin user used (Thanks @ernestasju!)

0.9.58
- Add Exclude into JSON setting search to be able to exclude Dependencies subfolder from the search
        
0.9.57
- Enable web client when creating container under CI/CD to be able to run tests from container

0.9.56
- Fixed missing username parameter in Run-ALTestInContainer

0.9.55
- Added parameters CreateTestWebServices and EnableSymbolLoading through which you can disable these two things

0.9.54
- Added cmdlet Run-ALTestInContainer to use the new function to run tests in container from navcontainerhelper module

0.9.53
- Added support for CodeCop in Compile-ALProjectTree
- Added support for reading Configuration from JSON file with multiple profiles support

0.9.52
- Added support for downloading missing dependencies when publishing app tree through using AppDownloadScript parameter

0.9.51
- Added support for downloading missing dependencies when compiling app tree through using AppDownloadScript parameter
- Fixed bug when Test webservices were published even when test toolkit was not imported (thus objects published are not present)

0.9.50
- Fixed Nuget package creation when App name has spaces
- Added webservice for Automated tests into creating the environment (before the test app must register the webservices)

0.9.48..0.9.49
- Fixed Get-ALAppOrder bug when no AppCollection passed and no app.json exists

0.9.47        
- Fixed Get-ALAppOrder bug with default parameter set
- Added possibility to pass password and RAM through pipeline

0.9.46
- Running under Build agent on Azure DevOps but no output formated bug fixed (@MJECloud)

0.9.45
- Added different password dialogs in Init-ALEnvironment based on Authentication method
- Added new parameters to Publish-AlApp and Publish-AlAppTree
- Fix from @MJECloud regarding singing the app when NavUserPassword authentication used
- Added possibility to pass array with app.json files to process in Get-ALAppOrder (@MJECloud)

0.9.44
- Fixedmissing & in Sign-ALApp

0.9.43
- Fixed missing } in Compile-ALProjectTree

0.9.42
- Fixed Compile-ALProjectTree
- Sign in container in Compile-ALProjectTree

0.9.41
- SignTool existence test added
        
0.9.38
- Fixing bug in Compile-ALProjectTree to support NavUserPassword

0.9.36-0.9.37
- Added package id prefix support for install-alnugetpackage and New-ALNuSpec

0.9.35
- Added support for Version attribute in dependencies when creating nuspec file

0.9.27-0.9.34
- Fixed bugs connected to Container usage to get app info needed for Get-ALAppOrder function running in release pipeline

0.9.26
- Using container to get info about App file in Get-ALAppOrder to support release pipeline

0.9.25
- Added UpdateDevOpsBuildNo to set Azure DevOps build version based on the new App build in Set-ALAppBuildNo

0.9.24
- Added Recurse parameter for Get-ALAppOrder to be able to find app files in subfolders

0.9.19-0.9.23
- Bug hunting fixes for Compile script

0.9.18
- Fixed Compile-ALAppTree in container support
- Added flag to skip import of test toolkit in Init-ALEnvironment

0.9.17
- Fixed Init-ALEnvironment parameters for volume

0.9.16
- Fixed Init-ALEnvironment MainLoop override bug

0.9.15
- Added parameter useBestContainerOS when creating environment

0.9.14
- Modified Set-ALAppBuildNo to include only MainApp and TestApp and use same Build and Revision for both

0.9.13
- Added Set-ALDockerHostFolder

0.9.12
- Added Set-ALAppBuildNo script

0.9.11
- Fixed Unpublish-AlAppTree

0.9.10
- Add AssignPremiumPlan
- Add updateHost

0.9.9 
- Fixed parameters in Download-ALSystemPackages

0.9.8 
- Fixed condition in Download-ALSystemPackages

0.9.7 
- Addd navcontainerhelper as dependency
- Fixed missing bracket

0.9.6
- Added force flag to Download-ALSystemPackages

0.9.5
- Added RAM size parameter
'@

        # External dependent modules of this module
        # ExternalModuleDependencies = ''

    } # End of PSData hashtable
    
 } # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

