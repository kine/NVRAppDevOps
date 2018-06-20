function Run-DesktopClient
{
    param(
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName=$env:ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ClientPath,
        [Switch]$Configure,
        [Switch]$FullScreen,
        [Switch]$Debugger,
        [Switch]$ConsoleMode,
        $Profile,
        $URI
    )

    $params = @()
    switch ($true) {
        $Configure { $params += @('-configure')  }
        $FullScreen { $params += @('-configure')  }
        $Profile { $params += @("-profile:'$Profile'")  }
        $ConsoleMode { $params += @('-consolemode') }
        $URI {$params += @($URI)}
        Default {}
    }
    $ClientExe = Join-Path -Path $ClientPath 'Microsoft.Dynamics.Nav.Client.exe'
    Write-Host "Running: $($ClientExe) $params"
    & "$ClientExe" $params
    
}