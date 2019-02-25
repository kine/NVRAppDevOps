# NVR App DevOps scripts

## Install and update

Install the module through:

    install-module NVRAppDevOps

Or update through

    update-module NVRAppDevOps

## Basic using

Import the module

    Import-Module NVRAppDevOps

If there is issue with Execution Policy, allow unsigned scripts by

    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

To init environment:

    Read-ALConfiguration -Path <path> | Init-ALEnvironment

\<path\> is where Scripts\settings.ps1 exists (.\ if you are in the root of the repo, ..\ if you are in subfolder like MainApp)

For list of commands use:

    Get-Command -module NVRAppDevOps
    
## CI/CD using

You can use YAML templates from https://github.com/kine/MSDYN365BC_Yaml to create your Pipelines using this PowerShell module.
Template for AL App using this is prepared here:https://github.com/kine/MSDyn365BC_AppTemplate

## Download of missing dependencies
When you use cmdlet Compile-AlProjectTree and you set the parameter $AppDownloadScript, when the app will find dependency, which could not be fullfilled by compiling some app in the subfolders (and it is not Microsoft app), content of $AppDownloadScript will be called with object including these properties:

-name - name of the App missing
-publisher - publisher of the App missing
-version - minimum required version of the App
-path - path to store the .App file

Result of the script should be the correct .App file in the path. This App will be then used to "compile" depending apps in the folder structure.

## Settings
Settings could be stored and read from two types of file:
-Scripts\Settings.ps1 script in the repository setting variables with appropriate values
-*.json file having default sections with at least one value "ContainerName"

## Settings in .JSON file
File with the settings could be placed anywhere inside the repository. If no parameter SettingsFileName is passed to Read-ALConfiguration cmdlet, all .JSON files will be read and if there is value "default.ContainerName", they will be taken as settings file for this module. If there are multiple files like that, all of them will be processed and values from the last wins. If SettingsFileName is passed, this will be used together with Path parameter to create path for the settings file. 

Structure of the JSON:
-first level - Profiles (at least one must be "default")
-second level - values for the profile

Example:
{
    "default":{
        "Name": "Default Settings",
        "ContainerName": "BC",
        "ImageName": "microsoft/bcsandbox"
    },
    "master":{
        "ImageName": "bcinsider.azurecr.io/bcsandbox-master"
    }
}

When non-default profile is selected, first all default profiles values are processed and then the specific profile values, overwriting the default one. It means the profile could have values only which are different from default.

Supported values for the settings:
-ContainerName
-ImageName
-LicenseFile
-VsixPath
-AppJSON
-TestAppJSON
-AppFile
-TestAppFile
-RepoPath
-AppPath
-TestAppPath
-Build
-Password
-ClientPath
-AppDownloadScript
-Auth
-Username
-RAM
-optionalParameters