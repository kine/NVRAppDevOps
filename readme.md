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

## Hosted Docker

If you are using hosted Docker (e.g. on your local Hyper-V VM with Windows 2016), you can use command like `Set-ALDockerHostFolder` to setup the environment for you.

Set-ALDockerHostFolder - this command will create shared folder on the host and map it locally as new drive. You than can place the source code there and use the VSCode extension `NaverticAL` with them. This folder is mapped into the docker container automatically and container can do things like compilation directly over the source code.