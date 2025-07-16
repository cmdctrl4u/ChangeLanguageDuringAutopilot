[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [System.String]$DeploymentType = 'Install',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [System.String]$DeployMode = 'Interactive',

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$AllowRebootPassThru,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$TerminalServerMode,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.SwitchParameter]$DisableLogging
)


##================================================
## MARK: Variables
##================================================

$adtSession = @{
    # App variables.
    AppVendor                   = 'CmdCtrl4U'
    AppName                     = 'Change language during Autopilot'
    AppVersion                  = ''
    AppArch                     = ''
    AppLang                     = 'EN'
    AppRevision                 = '01'
    AppSuccessExitCodes         = @(0)
    AppRebootExitCodes          = @(1641, 3010)
    AppScriptVersion            = '1.0.0'
    AppScriptDate               = '02.27.2025'
    AppScriptAuthor             = 'M. Langenhoff'

    # Install Titles (Only set here to override defaults set by the toolkit).
    InstallName                 = ''
    InstallTitle                = ''

    # Script variables.
    DeployAppScriptFriendlyName = $MyInvocation.MyCommand.Name
    DeployAppScriptVersion      = '4.0.5'
    DeployAppScriptParameters   = $PSBoundParameters
}

##########################################################################################
# Definition of variables
##########################################################################################

$EnableTestMode = $False # Set to $true for testmode
$languageMap = @()
# Map country code to language settings
$languageMap = @{
    "DE" = @{ Language = "de-DE"; KeyboardLayout = "0407:00000407" }
    "FR" = @{ Language = "fr-FR"; KeyboardLayout = "040C:0000040C" }
    "IT" = @{ Language = "it-IT"; KeyboardLayout = "0410:00000410" }
    "ES" = @{ Language = "es-ES"; KeyboardLayout = "0C0A:0000040A" }
    "GB" = @{ Language = "en-GB"; KeyboardLayout = "0809:00000809" }
    "US" = @{ Language = "en-US"; KeyboardLayout = "0409:00000409" }
    "AT" = @{ Language = "de-AT"; KeyboardLayout = "0C07:00000C07" }
    "CH" = @{ Language = "de-CH"; KeyboardLayout = "0807:00000807" }
    "NL" = @{ Language = "nl-NL"; KeyboardLayout = "0413:00020409" }
    "BE" = @{ Language = "nl-BE"; KeyboardLayout = "0813:00000813" }
    "SE" = @{ Language = "sv-SE"; KeyboardLayout = "041D:0000041D" }
    "DK" = @{ Language = "da-DK"; KeyboardLayout = "0406:00000406" }
    "NO" = @{ Language = "no-NO"; KeyboardLayout = "0414:00000414" }
    "FI" = @{ Language = "fi-FI"; KeyboardLayout = "040B:0000040B" }
    "JP" = @{ Language = "ja-JP"; KeyboardLayout = "0411:{03B5835F-F03C-411B-9CE2-AA23E1171E36}{A76C93D9-5523-4E90-AAFA-4DB112F9AC76}" }
    "CN" = @{ Language = "zh-CN"; KeyboardLayout = "0804:{81D4E9C9-1D3B-41BC-9E6C-4B40BF79E35E}{FA550B04-5AD7-411F-A5AC-CA038EC515D7}" }
    "ZA" = @{ Language = "af-ZA"; KeyboardLayout = "0C09:00000C09" }
    "AU" = @{ Language = "en-AU"; KeyboardLayout = "0C09:00000409" }
    "IN" = @{ Language = "en-IN"; KeyboardLayout = "0409:00000409" }
    "RS" = @{ Language = "sr-Latn-RS"; KeyboardLayout = "241A:0000081A" }
    # More mappings can be added as needed
}
# Set registry key for Intune detection rule
$regPath = "HKLM:\SOFTWARE\WOW6432Node\CmdCtrl4U\ComputerManagement\Autopilot"
$regKeyName = "ChangeLanguageDuringAutopilot"
$regValue = "v1"

#-------------------------------- End of variable definition -----------------------------

function Install-ADTDeployment {
    ##================================================
    ## MARK: Pre-Install 
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Run pre-install tasks for $($adtSession.AppVendor) - $($adtSession.AppName)"

    # Check if powershell is 64bit, if not, restart in 64bit
    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Is 64bit PowerShell: $([Environment]::Is64BitProcess)"
    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Is 64bit OS: $([Environment]::Is64BitOperatingSystem)"

    if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
        
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Running in 32-bit Powershell, starting 64-bit..."
        if ($myInvocation.Line) {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
        }
        else {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
        }
            
        exit $lastexitcode
    }

    # Check if ESP is running
    
    if ($EnableTestMode -eq $True) {
        $proc = $null # Testmode active
    }
    else {
        $proc = Get-Process -Name SecurityHealthSystray -ErrorAction SilentlyContinue 
    }

    # Process not found, so ESP is not running
    if ($null -ne $proc) {
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "ESP-not-active. Exiting script."
        Close-ADTSession -ExitCode 0
    } 
    else {
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "ESP-active. Will continue the script."
            
    }

    # Check if module "LanguagePackManagement" is installed
    try {
        $module = Get-Module -ListAvailable LanguagePackManagement

        # If module not installed, install it
        if (-not $module) {
            Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "The module 'LanguagePackManagement' will be installed."
            Install-Module -Name LanguagePackManagement -Scope CurrentUser -Force -ErrorAction Stop
        }
        else {
            Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "The module 'LanguagePackManagement' is already installed."
        }

        # Check if Module "International" is already installed
        $module = Get-Module -ListAvailable International

        # If module not installed, install it
        if (-not $module) {
            Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "The module 'International' will be installed."
            Install-Module -Name International -Scope CurrentUser -Force -ErrorAction Stop
        }
        else {
            Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "The module 'International' is already installed."
        }

        # Import modules + International LanguagePackManagement
        Import-Module LanguagePackManagement -ErrorAction Stop
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "The module 'LanguagePackManagement' was imported."
        Import-Module International -ErrorAction Stop
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "The module 'International' was imported."
    }
    catch {
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Exiting script: Error: $_"
        Close-ADTSession -ExitCode 0
    }

    ##================================================
    ## MARK: Install
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Initializing installation of $($adtSession.AppVendor) - $($adtSession.AppName)"

    # Initialize variables
    
    $language = $null
    $keyboardLayout = $null
    $countryCode = $null
    $InstalledLanguages = @()
    $GeoID = $null
    $LangList = @()
    $HKCU = $null     

    #---------------------------------- Try to get GeoID and the language from the registry ----------------------------------#

    # Retrieve GeoID from registry
    $GeoID = (Get-ItemProperty -Path 'registry::HKEY_USERS\.DEFAULT\Control Panel\International\Geo').Nation

    $GeoName = (Get-ItemProperty -Path 'registry::HKEY_USERS\.DEFAULT\Control Panel\International\Geo').Name

    if ($GeoName) {
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "GeoName: $GeoName found"
        $countryCode = $GeoName    
    }
    else {    
        # If no non-English language is found, use IP-based detection
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "No GeoName found in registry. Trying IP-Info as source."
    
        # Get country code from IPInfo
        try {
            $countryCode = (Invoke-RestMethod http://ipinfo.io/json).country
            Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Country code from IPInfo: $countryCode"
        }
        catch {
            Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "IPInfo request failed. Falling back to default language en-US"
        }       
    }   
    
    # Set the detected language or fallback to en-US
    if ($languageMap.ContainsKey($countryCode)) {
        $language = $languageMap[$countryCode].Language
        $keyboardLayout = $languageMap[$countryCode].KeyboardLayout
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Successful gathered language from IP-Info: $language"
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Successful gathered keyboard layout from IP-Info: $keyboardLayout"
    }
    else {
        # Fallback, set language to default en-US
        $language = "en-US"
        $keyboardLayout = "0409:00000409"
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Fallback to default language en-US"
    }

    # Summarize
    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "*****************************************************************************"
    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Gathered informations:"
    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Language: $language"
    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "KeyboardLayout: $keyboardLayout"
    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "GeoID: $GeoID"
    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "CountryCode: $countryCode"
    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "*****************************************************************************"

    # Check currently installed languages
    $InstalledLanguages = Get-InstalledLanguage  # Get installed languages
    # Extract language codes
    $InstalledLanguages = $InstalledLanguages | ForEach-Object { $_.LanguageID }
    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Installed languages: $InstalledLanguages"
      
    try {
        # Attempt to install the language
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Installing language $language"
        Install-Language -Language $language -CopyToSettings    
    }
    catch {
        # Log error if installation fails
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Error installing language $language. Error: $($_.Exception.Message). Exiting script"
            
        Close-ADTSession -ExitCode 0
    }

    # Set the language as the system preferred language
    try {
        Set-SystemPreferredUILanguage $language
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Successfully set system preferred UI language to $language."       
    }
    catch {
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Error setting system preferred UI language to $language. Error: $($_.Exception.Message)"
    }
        
    # Set WinUILanguageOverride for the user
    try {
        Set-WinUILanguageOverride -Language $language -ErrorAction Stop
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Successfully set WinUI language override to $language."      
    }
    catch {
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Error setting WinUI language override to $language. Error: $($_.Exception.Message)"
    }

    # Set WinUserLanguageList for the user

    $LangList = New-WinUserLanguageList "$language"
    $LangList[0].InputMethodTips.Add("$keyboardLayout")

    try {
        $HKCU = "Registry::HKEY_CURRENT_USER"
        function Set-RegistryValue {
            param (
                [string]$Path,
                [string]$Name,
                [string]$Type,
                [string]$Value
            )
                
            if (-not (Test-Path $Path)) {
                Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Registry key $Path does not exist. Creating key."
                New-Item -Path $Path -Force | Out-Null
            }
            
            try {
                $currentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
                if ($currentValue -ne $Value) {
                    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "$Name is not set to $Value. Updating $Name."
                    Set-ItemProperty -Path $Path -Name $Name -Value $Value
                        
                }
                else {
                    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "$Name is already set to $Value."
                }
            }
            catch {
                Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "$Name does not exist. Creating and setting it to $Value."
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
                    
            }
        }

        Set-RegistryValue -Path "$HKCU\Control Panel\International\User Profile" -Name "InputMethodOverride" -Type "String" -Value $keyboardLayout
        Set-RegistryValue -Path "$HKCU\Control Panel\International\User Profile System Backup" -Name "InputMethodOverride" -Type "String" -Value $keyboardLayout
        Set-WinUserLanguageList $LangList -Force
    }
    catch {
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Failure: $_"
    }

    # Set culture
    try {
        Set-Culture -CultureInfo $language
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Culture successfully set to $language"
    }
    catch {
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Error setting culture: $_"
    }
        
    # Set GeoID for the user
    try {
        if ([string]::IsNullOrEmpty($GeoID)) {
            throw "GeoID is null or empty."
        }
        
        Set-WinHomeLocation -GeoId $GeoID
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Home location successfully set to GeoID $GeoID"
    }
    catch {
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Error setting home location: $($_.Exception.Message)"
    }
        
    # Execute Copy-UserInternationalSettingsToSystem if necessary
    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Copying user international settings to system."
    try {
        Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True
    }
    catch {
        Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Error copying user international settings to system. Error: $($_.Exception.Message)"
    }

    # Check if the registry path exists, if not create it
    if (!(Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
  
    # Set the registry key "ChangeLanguageDuringAutopilot" to "v1"
    New-ItemProperty -Path $regPath -Name $regKeyName -Value $regValue -PropertyType String -Force
    Write-ADTLogEntry -Source $adtSession.InstallPhase -LogType 'CMTrace' -Message "Set registry key `"$regKeyName`" in $regPath"


    Close-ADTSession -ExitCode 3010
    
    
    ##================================================
    ## MARK: Post-Install
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

}

function Uninstall-ADTDeployment {
    ##================================================
    ## MARK: Pre-Uninstall
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

  
    ##================================================
    ## MARK: Uninstall
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType


    ##================================================
    ## MARK: Post-Uninstallation
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

   
}

function Repair-ADTDeployment {
    ##================================================
    ## MARK: Pre-Repair
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"


    ##================================================
    ## MARK: Repair
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType


    ##================================================
    ## MARK: Post-Repair
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

 
}


##================================================
## MARK: Initialization
##================================================

# Set strict error handling across entire operation.
$ErrorActionPreference = 'Stop'
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
Set-StrictMode -Version 1

# Import the module and instantiate a new session.
try {
    $moduleName = if ([System.IO.File]::Exists("$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1")) {
        Get-ChildItem -LiteralPath $PSScriptRoot\PSAppDeployToolkit -Recurse -File | Unblock-File -ErrorAction Ignore
        "$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1"
    }
    else {
        'PSAppDeployToolkit'
    }
    Import-Module -FullyQualifiedName @{ ModuleName = $moduleName; Guid = '8c3c366b-8606-4576-9f2d-4051144f7ca2'; ModuleVersion = '4.0.5' } -Force
    try {
        $iadtParams = Get-ADTBoundParametersAndDefaultValues -Invocation $MyInvocation
        $adtSession = Open-ADTSession -SessionState $ExecutionContext.SessionState @adtSession @iadtParams -PassThru
    }
    catch {
        Remove-Module -Name PSAppDeployToolkit* -Force
        throw
    }
}
catch {
    $Host.UI.WriteErrorLine((Out-String -InputObject $_ -Width ([System.Int32]::MaxValue)))
    exit 60008
}


##================================================
## MARK: Invocation
##================================================

try {
    Get-Item -Path $PSScriptRoot\PSAppDeployToolkit.* | & {
        process {
            Get-ChildItem -LiteralPath $_.FullName -Recurse -File | Unblock-File -ErrorAction Ignore
            Import-Module -Name $_.FullName -Force
        }
    }
    & "$($adtSession.DeploymentType)-ADTDeployment"
    Close-ADTSession
}
catch {
    Write-ADTLogEntry -Message ($mainErrorMessage = Resolve-ADTErrorRecord -ErrorRecord $_) -Severity 3
    Show-ADTDialogBox -Text $mainErrorMessage -Icon Stop | Out-Null
    Close-ADTSession -ExitCode 60001
}
finally {
    Remove-Module -Name PSAppDeployToolkit* -Force
}

