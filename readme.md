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
