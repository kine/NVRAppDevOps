#
# Module manifest for module 'PSGet_NVRAppDevOps'
#
# Generated by: Kamil Sacek
#
# Generated on: 13.06.2018
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule        = 'NVRAppDevOps.psm1'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID              = 'dc28788e-07b6-42c2-88b0-7cdc5fa6abd6'

    # Author of this module
    Author            = 'Kamil Sacek'

    # Company or vendor of this module
    CompanyName       = 'NAVERTICA a.s.'

    # Copyright statement for this module
    Copyright         = '(c) 2018-2023 Kamil Sacek'

    # Description of the functionality provided by this module
    Description       = 'cmdlets for DevOps for Business Central'

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
    RequiredModules   = @(
        @{
            ModuleName    = 'BcContainerHelper'
            ModuleVersion = '6.0.0'
            Guid          = '8e034fbc-8c30-446d-bbc3-5b3be5392491'
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
    CmdletsToExport   = '*'

    # Variables to export from this module
    # VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = '*'

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Version number of this module.
    ModuleVersion     = '2.8.4'

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{
            Prerelease   = 'beta01'

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = 'PSModule'

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri   = 'https://www.github.com/kine/NVRAppDevOps'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
2.8.4
- conditional mapping of the repository folder into the container

2.8.3
- BCv24 compilation support by adding the Microsoft Business Foundation.app into dependencies
- Long path support for NuGet cmdlets
- Add verbose output of paket.dependencies for better debugging
- Fix missing .app. management module in BCv24 Powershell 5 bridge

2.8.2
- Fix problems with Install-ALNugetPackage and Compile-ALProjectTree when packages were not installed

2.8.1
- Fix Download-ALApp when no dependencies to download

2.8.0
- Support for downloading NuGet packages with Unified naming for Download-ALApp, Download-ALAppFromNuget and Compile-ALProjectTree
- If $env:NVRAppDevOpsNugetFeedUrl is set to Azure DevOps MS feed with MS packages, the Format-AppNameForNuget will try to find the package name by ID. This is workaround for finding correct package names for e.g. Czech localization 
apps having tag CZ even when they are build on W1.

2.7.1
- Fixing compatibility with BCv24 folder structure of the vsix/alc.exe (Issue #37, #38)            

2.7.0
- Fixing compatibility with BCv24 folder structure of the vsix/alc.exe (Issue #37, #38 and #39 - thanks @skmcavoy for reporting!)

2.6.7
- Fix Get-ALAppOrder infinite loop in case of cyclic dependencies (set to max 20 iterations)

2.6.6
- Fix bug when Install-ALNugetPackageByPaket with Ignore parameter doesn't work correctly (no app is copied to target folder)

2.6.2
- Fix error " Method invocation failed because [System.Int32] does not contain a method named 'Contains'" in Install-ALNugetPackageByPaket.ps1

2.5.0
- Added ConvertTo-PaketDependencies script to convert App.json dependencies into paket.dependencies file to be able to download symbols/apps through Paket CLI (https://fsprojects.github.io/Paket/)
- Added parameters UnifiedNaming and DependencyTag into New-ALNuSpec to be able to use unified naming for the dependencies and the package as it will be used by Microsoft
- Added New-ALNuSpecForAppFile to create nuspec file for app file
- Added Format-AppNameForNuget to format app name for NuGet package name based on Unified naming rules

2.4.0
- Removed custom parameter '-e CustomNavSettings=ServicesUseNTLMAuthentication=true' when initializing environment. If needed, add it as optionalParameters. This parameter makes problems on BCv22.5 and newer ("There was no endpoint listening at http://localhost:7086/BC/ManagementServicePs/Service.svc that could accept the message. This is often caused by an incorrect address or SOAP action. See InnerException, if present, for more details."))

2.3.0
- Add support for new alc.exe parameters SourceRepositoryUrl, SourceCommit, BuildBy and BuildUrl
            
2.2.0
- Add Install-ALNugetPackageByPaket to install nuget package by Paket manager. Paket have better dependency resolving than nuget.exe

2.1.0
- Add IncludeBaseApp switch into New-ALNuSpec to include microsoft Application into dependencies (preview, to be able to select package based on MS application version dependency)

2.0.44
- Fixed issue #34 - rulesetfile parameter bug in Compile-AppWithArtifact.ps1 (thanks @skmcavoy)

2.0.43
- Fixed support for v21 and older management script location in Get-BCModulePathFromArtifact

2.0.42
- Add support for v22 management script location in Get-BCModulePathFromArtifact
        
2.0.41
- Format-AppNameForNuget now replace / character

2.0.40
- Fixing regular expression for replacing () characters
        
2.0.39
- Format-AppNameForNuget now replace even () characters
        
2.0.38
- Update lastused on the artifact when module is imported from it

2.0.36
- Replace & i nuget package with _

2.0.35
- Add Escaping of special chars in New-ALNuSpec

2.0.34
- Install-ALNugetPackage HighestMinor for x.y.z.0 will search for x.y.*.* instead x.*.*.*
        
2.0.33
- Install-ALNugetPackage Lowest and HighestMinor search bugfix

2.0.32
- Install-ALNugetPackage ExactVersion filter bugfix

2.0.31
- Install-ALNugetPackage ExactVersion switch to prevent applying DependencyVersion for the main package

2.0.19
- Get-ALAppOrder gets the highest dependency version if multiple dependencies on same app

2.0.15
- Install-ALNugetPackage versionmode Lowest now search for lowest version which is higher or equal to requested version (e.g. requeted 1.2.0.0 will take 1.2.123.0 if lowest)

2.0.14
- Add Upload-FileToShp function for uploading file to sharepoint
        
2.0.10
- Fixing Microsoft dependencies when sandbox artifact used in Compile-AppWithArtifact.ps1 (localization apps not found bug)

2.0.7
- Add Compile-AppWithArtifact, Get-ALCompileFromArtifact and parameter artifactUrl into Compile-ALProjectTree and Get-ALAppOrder to
  support compilation without container

2.0.6
- Add Get-BCModulePathFromArtifact
        
2.0.5
- Fixed way how the SQL libraries are loaded. You need to install SqlServer PS Module (Install-module SqlServer)

2.0.3
- Add support for SQL libraries needed for database manipulation cmdlets as part of Import-BCModulesFromArtifacts

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

