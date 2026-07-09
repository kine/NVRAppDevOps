function Invoke-AICli {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('ClaudeCode', 'GitHubCopilot', 'OpenAI')]
        [string]$Provider,

        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [Parameter()]
        [string[]]$SkillFiles,

        [Parameter()]
        [string[]]$AllowedTools,

        [Parameter()]
        [string]$Model,

        [Parameter()]
        [string]$ApiKey,

        [Parameter()]
        [string]$WorkingDirectory,

        [Parameter()]
        [hashtable]$EnvironmentVars,

        [Parameter()]
        [int]$TimeoutMinutes = 30,

        [Parameter()]
        [switch]$EnableStream,

        [Parameter()]
        [switch]$ShowRawOutput,

        [Parameter()]
        [string]$RawOutputPath
    )

    if ($WorkingDirectory -and (Test-Path $WorkingDirectory)) {
        Push-Location $WorkingDirectory
    }

    try {
        $cliArgs = Build-AICLiArguments -Provider $Provider -Prompt $Prompt -SkillFiles $SkillFiles `
            -AllowedTools $AllowedTools -Model $Model

        $envBackup = @{}
        if ($ApiKey) {
            switch ($Provider) {
                'ClaudeCode' {
                    $envBackup['ANTHROPIC_API_KEY'] = $env:ANTHROPIC_API_KEY
                    $env:ANTHROPIC_API_KEY = $ApiKey
                }
                'GitHubCopilot' {
                    $envBackup['COPILOT_GITHUB_TOKEN'] = $env:COPILOT_GITHUB_TOKEN
                    $env:COPILOT_GITHUB_TOKEN = $ApiKey
                }
                'OpenAI' {
                    $envBackup['OPENAI_API_KEY'] = $env:OPENAI_API_KEY
                    $env:OPENAI_API_KEY = $ApiKey
                }
            }
        }

        if ($EnvironmentVars) {
            foreach ($key in $EnvironmentVars.Keys) {
                $envBackup[$key] = [System.Environment]::GetEnvironmentVariable($key)
                [System.Environment]::SetEnvironmentVariable($key, $EnvironmentVars[$key])
            }
        }

        $executable = Get-AICliExecutable -Provider $Provider
        Write-Host "Invoking $Provider CLI: $executable $($cliArgs -join ' ')"

        if ($EnableStream) {
            $result = Invoke-AICliStreaming -Executable $executable -Arguments $cliArgs -TimeoutMinutes $TimeoutMinutes
        }
        else {
            $result = Invoke-AICliBuffered -Executable $executable -Arguments $cliArgs -TimeoutMinutes $TimeoutMinutes
        }

        if ($ShowRawOutput -and $result.Output) {
            Write-Host "##[group]AI CLI Raw Output"
            Write-Host $result.Output
            Write-Host "##[endgroup]"
        }

        if ($RawOutputPath -and $result.Output) {
            $result.Output | Set-Content -Path $RawOutputPath -Encoding UTF8
            Write-Host "Raw output saved to: $RawOutputPath"
        }

        return $result
    }
    finally {
        foreach ($key in $envBackup.Keys) {
            if ($null -eq $envBackup[$key]) {
                [System.Environment]::SetEnvironmentVariable($key, $null)
            }
            else {
                [System.Environment]::SetEnvironmentVariable($key, $envBackup[$key])
            }
        }

        if ($WorkingDirectory -and (Test-Path $WorkingDirectory)) {
            Pop-Location
        }
    }
}

function Build-AICLiArguments {
    [CmdletBinding()]
    param(
        [string]$Provider,
        [string]$Prompt,
        [string[]]$SkillFiles,
        [string[]]$AllowedTools,
        [string]$Model
    )

    $cliArgs = @()

    switch ($Provider) {
        'ClaudeCode' {
            $cliArgs += '--print'
            if ($AllowedTools) {
                $cliArgs += '--allowedTools'
                $cliArgs += ($AllowedTools -join ',')
            }
            else {
                $cliArgs += '--allowedTools'
                $cliArgs += '""'
            }
            if ($SkillFiles) {
                foreach ($skillFile in $SkillFiles) {
                    if (Test-Path $skillFile) {
                        $cliArgs += '--skill-file'
                        $cliArgs += $skillFile
                    }
                    else {
                        Write-Warning "Skill file not found: $skillFile"
                    }
                }
            }
            if ($Model) {
                $cliArgs += '--model'
                $cliArgs += $Model
            }
            $cliArgs += '--'
            $cliArgs += $Prompt
        }
        'GitHubCopilot' {
            $cliArgs += '-p'
            $cliArgs += $Prompt
            $cliArgs += '-s'
            $cliArgs += '--no-ask-user'
            if ($AllowedTools) {
                $cliArgs += '--allow-tool'
                $cliArgs += ($AllowedTools -join ',')
            }
            else {
                $cliArgs += '--allow-all-tools'
            }
            if ($SkillFiles) {
                foreach ($skillFile in $SkillFiles) {
                    if (Test-Path $skillFile) {
                        $cliArgs += '--attachment'
                        $cliArgs += $skillFile
                    }
                    else {
                        Write-Warning "Skill file not found: $skillFile"
                    }
                }
            }
            if ($Model) {
                $cliArgs += '--model'
                $cliArgs += $Model
            }
            $cliArgs += '--secret-env-vars'
            $cliArgs += 'COPILOT_GITHUB_TOKEN,GH_TOKEN,GITHUB_TOKEN,SYSTEM_ACCESSTOKEN'
        }
        'OpenAI' {
            $cliArgs += 'chat'
            if ($Model) {
                $cliArgs += '--model'
                $cliArgs += $Model
            }
            $cliArgs += '--message'
            $cliArgs += $Prompt
        }
    }

    return $cliArgs
}

function Get-AICliExecutable {
    [CmdletBinding()]
    param(
        [string]$Provider
    )

    switch ($Provider) {
        'ClaudeCode' { return Get-ExecutablePath -ExecutableName 'claude' -NativeInstallSubPath '.local\bin\claude.exe' }
        'GitHubCopilot' { return 'copilot' }
        'OpenAI' { return 'openai' }
    }
}

function Get-ExecutablePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExecutableName,

        [Parameter(Mandatory = $true)]
        [string]$NativeInstallSubPath
    )

    $command = Get-Command $ExecutableName -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $nativeInstallPath = Join-Path $HOME $NativeInstallSubPath
    if (Test-Path $nativeInstallPath) {
        return $nativeInstallPath
    }

    return $ExecutableName
}

function Invoke-AICliBuffered {
    [CmdletBinding()]
    param(
        [string]$Executable,
        [string[]]$Arguments,
        [int]$TimeoutMinutes
    )

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $Executable
    $psi.Arguments = ($Arguments | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }) -join ' '
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $psi

    try {
        $process.Start() | Out-Null

        $outputTask = $process.StandardOutput.ReadToEndAsync()
        $errorTask = $process.StandardError.ReadToEndAsync()

        $timeoutMs = $TimeoutMinutes * 60 * 1000
        if (-not $process.WaitForExit($timeoutMs)) {
            $process.Kill()
            Write-Warning "AI CLI process timed out after $TimeoutMinutes minutes"
            return @{
                ExitCode = -1
                Output   = "Process timed out after $TimeoutMinutes minutes"
                Success  = $false
            }
        }

        $output = $outputTask.GetAwaiter().GetResult()
        $errorOutput = $errorTask.GetAwaiter().GetResult()

        if ($errorOutput) {
            Write-Warning "AI CLI stderr: $errorOutput"
        }

        return @{
            ExitCode = $process.ExitCode
            Output   = $output
            Success  = ($process.ExitCode -eq 0)
        }
    }
    finally {
        if ($process) { $process.Dispose() }
    }
}

function Invoke-AICliStreaming {
    [CmdletBinding()]
    param(
        [string]$Executable,
        [string[]]$Arguments,
        [int]$TimeoutMinutes
    )

    $outputBuilder = [System.Text.StringBuilder]::new()

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $Executable
    $psi.Arguments = ($Arguments | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }) -join ' '
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $psi

    Write-Host "##[group]AI CLI Streaming Output"

    try {
        $process.Start() | Out-Null

        $deadline = [DateTime]::Now.AddMinutes($TimeoutMinutes)

        while (-not $process.StandardOutput.EndOfStream) {
            if ([DateTime]::Now -gt $deadline) {
                $process.Kill()
                Write-Host "##[endgroup]"
                Write-Warning "AI CLI process timed out after $TimeoutMinutes minutes"
                return @{
                    ExitCode = -1
                    Output   = $outputBuilder.ToString()
                    Success  = $false
                }
            }

            $line = $process.StandardOutput.ReadLine()
            if ($null -ne $line) {
                Write-Host $line
                $outputBuilder.AppendLine($line) | Out-Null
            }
        }

        $process.WaitForExit()
        Write-Host "##[endgroup]"

        $errorOutput = $process.StandardError.ReadToEnd()
        if ($errorOutput) {
            Write-Warning "AI CLI stderr: $errorOutput"
        }

        return @{
            ExitCode = $process.ExitCode
            Output   = $outputBuilder.ToString()
            Success  = ($process.ExitCode -eq 0)
        }
    }
    catch {
        Write-Host "##[endgroup]"
        throw
    }
}
