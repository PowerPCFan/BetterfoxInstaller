function Install-PSModule { # Approved Verb ("Places a resource in a location, and optionally initializes it")
    param (
        [string]$moduleName,        
        [string]$requiredVersion    
    )

    $module = Get-Module -ListAvailable -Name $moduleName -All | Where-Object { $_.Version -eq $requiredVersion }
    if (-not $module) {
        if (-not (Get-Module PSResourceGet -listavailable -All)) {
            Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Force -Repository PSGallery -Confirm:$false
        } else {
            Install-PSResource -Name $moduleName -Version $requiredVersion -TrustRepository -Reinstall -Repository PSGallery -Quiet -AcceptLicense
        }
    }
}

function Get-UserChoice { # Approved Verb ("Specifies an action that retrieves a resource")
    param (
        [Parameter(Mandatory=$true)]
        [string]$readHostMessage,
        [string]$choicePrompt,
        [string[]]$keys,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$choiceActions
    )
    
    # Validate that there's an action for each key
    foreach ($key in $keys) {
        $actionKey = "choiceIs$key"
    }
    
    # Check if "Default" is defined as a key
    $hasDefaultAction = $keys -contains "Default"
    
    Write-Host "$choicePrompt"    
    $key = Read-Host "$readHostMessage"
    $validInput = $false
    
    while (-not $validInput) {
        $upperKey = $key.ToUpper()
        
        if ($keys -contains $upperKey) {
            $validInput = $true
            $actionKey = "choiceIs$upperKey"
            
            if ($choiceActions.ContainsKey($actionKey) -and $null -ne $choiceActions[$actionKey]) {
                & $choiceActions[$actionKey]
            }
        }
        elseif ($hasDefaultAction) {
            # If "Default" is defined and user pressed an undefined key, use the default action
            $validInput = $true
            $actionKey = "choiceIsDefault"
            
            if ($choiceActions.ContainsKey($actionKey) -and $null -ne $choiceActions[$actionKey]) {
                & $choiceActions[$actionKey]
            }
            
            # Return the actual key pressed when using default action
            return $upperKey
        }
        else {
            Write-Host -ForegroundColor Red "Invalid input. Please try again"
            $key = Read-Host "$readHostMessage"
        }
    }
    
    return $upperKey
}

function Test-AdminPrivileges { # Approved Verb ("Verifies the operation or consistency of a resource")
    # Check if the script is running as an administrator
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Clear-Host
        Write-Host -ForegroundColor Red "============================================================================="
        Write-Host -ForegroundColor Red "Failure: Current permissions inadequate: Script not running as administrator."
        Write-Host -ForegroundColor Red "============================================================================="
        Get-UserChoice -readHostMessage "[R] Attempt to relaunch as administrator [E] Exit" -choicePrompt "Please select an action:" -keys "R", "E" -choiceActions @{
            choiceIsR = { 
                Start-Process `
                -Verb RunAs `
                -FilePath "powershell.exe" `
                -ArgumentList "-Command", "Invoke-RestMethod -Uri 'https://bit.ly/betterfoxinstaller' | Invoke-Expression"
                
                Stop-Transcript
                exit
            }
            choiceIsE = { exit }
        }
    }
}

function Install-BetterfoxAllProfiles {
    if (Test-Path $firefoxProfilesPath) {
        Invoke-BetterfoxDownload
        $directories = Get-ChildItem -Path $firefoxProfilesPath -Directory
        foreach ($directory in $directories) {
            $dirName = $directory.FullName
            Copy-Item -Path $betterfoxPath -Destination "$dirName\user.js"
        }
        Write-Host "Successfully downloaded and installed Betterfox user.js to all Firefox profiles in $firefoxProfilesPath" -ForegroundColor Green
        
        # Prompt user to press any key to close firefox
        Write-Host "Press any key to relaunch Firefox to apply the tweaks. Make sure all work is saved!"
        Read-Host

        taskkill.exe /F /IM firefox.exe | Out-Null
        Start-Sleep -Seconds 3 # wait for all processes to end

        # restart firefox.exe
        Start-Process $firefoxExecutable | Out-Null

        Write-Host "Firefox has relaunched and the Betterfox tweaks are applied successfully."
    } else {
        Write-Host -ForegroundColor Red "Error: Firefox is most likely in an install location that is unsupported."
    }
}

function Install-BetterfoxDefaultProfile {
    $profilesIniHash = (ConvertFrom-IniFile -FilePath $iniPath)
    $match = $profilesIniHash.Keys | Where-Object { $_ -like 'Install*' } | Select-Object -First 1
    if ($match) {
        $nested = $profilesIniHash[$match]
        if ($nested.ContainsKey('Default')) {
            $defaultValue = $nested['Default']
        }
    }

    $defaultProfile = $defaultValue -replace '/', '\'
    $defaultProfilePath = "$ffAppDataPath\$defaultProfile"
    if (Test-Path $defaultProfilePath) {
        try {
            Invoke-BetterfoxDownload
            Copy-Item -Path $betterfoxPath -Destination "$defaultProfilePath\user.js"
            Write-Host "Successfully copied Betterfox user.js to the default Firefox profile." -ForegroundColor Green
        } catch {
            Write-Host "Failed to copy the user.js file. Error: $_" -ForegroundColor Red
            exit
        }

        # ask user to press any key to close firefox
        Read-Host -Prompt "Press any key to relaunch Firefox to apply the tweaks. Make sure all work is saved!"

        taskkill.exe /F /IM firefox.exe | Out-Null
        Start-Sleep -Seconds 3 # wait for all processes to end

        # restart firefox.exe
        Start-Process $firefoxExecutable | Out-Null

        Write-Host "Firefox has relaunched and the Betterfox tweaks are applied successfully."
    } else {
        Write-Host -ForegroundColor Red "Error: The default profile folder does not exist at $defaultProfilePath. `nFirefox may be in an unsupported install location."
    }
}

function Show-ChoiceBox {
    $anybox = New-Object AnyBox.AnyBox
    
    $anybox.Message = 'What Firefox profile(s) would you like to install Betterfox in?'

    $anybox.Buttons = @(
        New-AnyBoxButton -Name 'all' -Text 'All Profiles'
        New-AnyBoxButton -Name 'default' -Text 'Default Profile'
    )

    # Show the AnyBox; collect responses.
    $response = $anybox | Show-AnyBox

    # Act on responses.
    if ($response['all'] -eq $true) {
        Install-BetterfoxAllProfiles
    } elseif ($response['default'] -eq $true) {
        Install-BetterfoxDefaultProfile
    }
}

function Start-Countdown {
    param (
        [ValidateRange(1, 59)]
        [int]$Seconds,
        [string]$Message
    )

    for ($i = $Seconds; $i -ge 0; $i--) {
        $output = "`r" + ($Message -replace '{seconds}', $i.ToString()) + "  "
        Write-Host $output -NoNewline

        if ($i -gt 0) {
            Start-Sleep -Seconds 1
        }
    }

    Write-Host "`n"
}

function New-UnderlinedText {
    param([string]$text, [string]$underlinedWord)
    return $text -replace "\{u\}", "$([char]27)[4m$underlinedWord$([char]27)[24m"
}

function Write-BoldText {
    param([string]$Text, [switch]$NoNewline)
    Write-Host -NoNewline:$NoNewline -ForegroundColor White "$Text" 
}

function Test-FirefoxInstalled {
    if (Test-Path $firefoxExecutable) {
        return $true
    } else {
        return $false
    }
}

function Invoke-BetterfoxDownload {
    if (Test-Path $betterfoxDownloadFolder) {
        Remove-Item -Recurse -Force -Path $betterfoxDownloadFolder | Out-Null
    }
    New-Item -ItemType "Directory" -Path $betterfoxDownloadFolder | Out-Null
    try {
        Write-Host "Downloading Betterfox user.js..."
        Invoke-WebRequest -Uri $betterfoxDownloadLink -OutFile "$betterfoxDownloadFolder\user.js"
        Write-Host -ForegroundColor Green "Successfully downloaded!"
    } catch {
        Write-Host -ForegroundColor Red "Error downloading betterfox user.js: $_"
    }
}








$ProgressPreference = 'SilentlyContinue'

Test-AdminPrivileges

if (Test-FirefoxInstalled) {
    # AnyBox
    Install-PSModule -ModuleName 'AnyBox' -RequiredVersion 0.5.1
    Install-PSModule -ModuleName 'PSParseIni' -RequiredVersion 1.0.1
    Import-Module 'AnyBox'
    Import-Module 'PSParseIni'

    # i dont wanna deal with like passing params and stuff for now, script-scoped vars work
    $script:ffAppDataPath = "$env:APPDATA\Mozilla\Firefox"
    $script:firefoxProfilesPath = "$ffAppDataPath\Profiles"
    $script:betterfoxDownloadLink = "https://raw.githubusercontent.com/yokoffing/Betterfox/refs/heads/main/user.js"
    $script:iniPath = "$ffAppDataPath\profiles.ini"
    $script:firefoxExecutableParent = "$env:ProgramFiles\Mozilla Firefox"
    $script:firefoxExecutable = "$firefoxExecutableParent\firefox.exe"
    $script:betterfoxDownloadFolder = "$env:temp\betterfox-userjs"
    $script:betterfoxPath = "$betterfoxDownloadFolder\user.js"

    Write-Host -ForegroundColor Green "Welcome to Betterfox User.js Installer!"
    Write-Host "This is an automated installer for the Betterfox user.js mod for Firefox." 
    Write-Host "It improves Firefox's performance, security, and more!`n"

    Write-Host -NoNewline -ForegroundColor Yellow "NOTE: " 
    Write-Host -NoNewLine "This project is an "
    Write-BoldText -NoNewLine -Text (New-UnderlinedText -Text "{u}" -UnderlinedWord "unofficial")
    Write-Host " installer for https://github.com/yokoffing/Betterfox."

    Write-Host "`n`n"

    Start-Sleep -Milliseconds 500

    Start-Countdown -Seconds 5 -Message "Script starting in {seconds} seconds..."

    Show-ChoiceBox
} else {
    Write-Host -ForegroundColor Red "Error: firefox.exe not found at $firefoxExecutable`nThis likely means that Firefox is not installed, or is installed in a location other than $firefoxExecutableParent."
}