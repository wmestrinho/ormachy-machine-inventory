[CmdletBinding()]
param(
    [string]$OutputRoot = (Join-Path -Path $PSScriptRoot -ChildPath 'capture'),
    [switch]$IncludeHardwareIdentifiers
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'SilentlyContinue'

function Get-FirstValue {
    param([object]$Object, [string]$Property, [object]$Default = $null)
    if ($null -ne $Object) {
        $propertyValue = $Object.PSObject.Properties[$Property]
        if ($null -ne $propertyValue -and $null -ne $propertyValue.Value -and "$($propertyValue.Value)" -ne '') {
            return $propertyValue.Value
        }
    }
    return $Default
}

function Invoke-ReadOnlyQuery {
    param([scriptblock]$Query)
    try {
        return @( & $Query )
    } catch {
        return @()
    }
}

function Redact-Value {
    param([object]$Value, [string]$Replacement = '<redacted>')
    if ($null -eq $Value -or "$Value" -eq '') { return $null }
    if ($IncludeHardwareIdentifiers) { return "$Value" }
    return $Replacement
}

function Get-SecureBootState {
    try {
        return [bool](Confirm-SecureBootUEFI)
    } catch {
        return 'Unavailable'
    }
}

function Get-TPMState {
    $tpm = @(Invoke-ReadOnlyQuery { Get-Tpm })
    if ($tpm.Count -eq 0) { return @{ Present = $false; Ready = 'Unavailable'; Enabled = 'Unavailable' } }
    return @{
        Present = $true
        Ready = Get-FirstValue $tpm[0] 'TpmReady' 'Unknown'
        Enabled = Get-FirstValue $tpm[0] 'TpmEnabled' 'Unknown'
        Manufacturer = Get-FirstValue $tpm[0] 'ManufacturerIdTxt' 'Unknown'
    }
}

function Get-NetworkSummary {
    $adapters = @(Invoke-ReadOnlyQuery { Get-NetAdapter -Physical })
    $result = @()
    foreach ($adapter in $adapters) {
        $addresses = @(Invoke-ReadOnlyQuery {
            Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4,IPv6
        })
        $dns = @(Invoke-ReadOnlyQuery {
            Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex
        })
        $result += [ordered]@{
            Name = $adapter.Name
            Description = $adapter.InterfaceDescription
            Status = $adapter.Status
            LinkSpeed = $adapter.LinkSpeed
            MacAddress = Redact-Value $adapter.MacAddress
            AddressCount = $addresses.Count
            Addresses = @($addresses | ForEach-Object {
                [ordered]@{
                    AddressFamily = $_.AddressFamily
                    Address = Redact-Value $_.IPAddress
                    PrefixLength = $_.PrefixLength
                }
            })
            DnsServerCount = @($dns | ForEach-Object { $_.ServerAddresses } | Where-Object { $_ }).Count
            DnsServers = @($dns | ForEach-Object { $_.ServerAddresses } | Where-Object { $_ } |
                ForEach-Object { Redact-Value $_ })
        }
    }
    return $result
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$capturePath = Join-Path -Path $OutputRoot -ChildPath $timestamp
New-Item -ItemType Directory -Path $capturePath -Force | Out-Null

$computer = Invoke-ReadOnlyQuery { Get-CimInstance Win32_ComputerSystem } | Select-Object -First 1
$bios = Invoke-ReadOnlyQuery { Get-CimInstance Win32_BIOS } | Select-Object -First 1
$os = Invoke-ReadOnlyQuery { Get-CimInstance Win32_OperatingSystem } | Select-Object -First 1
$cpu = @(Invoke-ReadOnlyQuery { Get-CimInstance Win32_Processor })
$memory = @(Invoke-ReadOnlyQuery { Get-CimInstance Win32_PhysicalMemory })
$disks = @(Invoke-ReadOnlyQuery { Get-CimInstance Win32_DiskDrive })
$volumes = @(Invoke-ReadOnlyQuery { Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" })
$hotfixes = @(Invoke-ReadOnlyQuery { Get-CimInstance Win32_QuickFixEngineering })
$products = @(Invoke-ReadOnlyQuery { Get-ItemProperty `
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' }) |
    Where-Object {
        $displayName = $_.PSObject.Properties['DisplayName']
        $null -ne $displayName -and $displayName.Value
    } | Sort-Object DisplayName -Unique

$inventory = [ordered]@{
    Collection = [ordered]@{
        CollectedAt = (Get-Date).ToUniversalTime().ToString('o')
        ComputerName = Redact-Value $env:COMPUTERNAME
        CollectorVersion = '1.0'
        HardwareIdentifiersIncluded = [bool]$IncludeHardwareIdentifiers
        ReadOnly = $true
    }
    Hardware = [ordered]@{
        Manufacturer = Get-FirstValue $computer 'Manufacturer'
        Model = Get-FirstValue $computer 'Model'
        SerialNumber = Redact-Value (Get-FirstValue $bios 'SerialNumber')
        BiosVersion = Get-FirstValue $bios 'SMBIOSBIOSVersion' 'Unknown'
        BiosReleaseDate = Get-FirstValue $bios 'ReleaseDate' 'Unknown'
        UefiSecureBoot = Get-SecureBootState
        Tpm = Get-TPMState
    }
    OperatingSystem = [ordered]@{
        Caption = Get-FirstValue $os 'Caption'
        Version = Get-FirstValue $os 'Version'
        Build = Get-FirstValue $os 'BuildNumber'
        Architecture = Get-FirstValue $os 'OSArchitecture'
        LastBoot = Get-FirstValue $os 'LastBootUpTime'
    }
    Compute = [ordered]@{
        Cpu = @($cpu | ForEach-Object {
            [ordered]@{
                Name = $_.Name
                Cores = $_.NumberOfCores
                LogicalProcessors = $_.NumberOfLogicalProcessors
                MaxClockMHz = $_.MaxClockSpeed
            }
        })
        Memory = [ordered]@{
            InstalledGiB = [math]::Round((($memory | Measure-Object Capacity -Sum).Sum / 1GB), 2)
            ModuleCount = $memory.Count
        }
    }
    Storage = [ordered]@{
        PhysicalDisks = @($disks | ForEach-Object {
            [ordered]@{
                Model = $_.Model
                MediaType = $_.MediaType
                SizeGiB = [math]::Round(($_.Size / 1GB), 2)
                Status = $_.Status
            }
        })
        Volumes = @($volumes | ForEach-Object {
            [ordered]@{
                Drive = $_.DeviceID
                FileSystem = $_.FileSystem
                SizeGiB = [math]::Round(($_.Size / 1GB), 2)
                FreeGiB = [math]::Round(($_.FreeSpace / 1GB), 2)
                FreePercent = if ($_.Size) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } else { $null }
            }
        })
        Health = @((Invoke-ReadOnlyQuery { Get-PhysicalDisk }) | ForEach-Object {
            [ordered]@{ FriendlyName = $_.FriendlyName; HealthStatus = $_.HealthStatus; OperationalStatus = "$($_.OperationalStatus)" }
        })
    }
    Network = @(Get-NetworkSummary)
    InstalledSoftware = @($products | ForEach-Object {
        [ordered]@{ Name = $_.DisplayName; Version = $_.DisplayVersion; Publisher = $_.Publisher }
    })
    WindowsPosture = [ordered]@{
        HotfixCount = $hotfixes.Count
        LatestHotfix = ($hotfixes | Sort-Object InstalledOn -Descending | Select-Object -First 1).HotFixID
        Defender = @(Invoke-ReadOnlyQuery { Get-MpComputerStatus } | Select-Object -First 1 |
            ForEach-Object {
                [ordered]@{
                    AntivirusEnabled = $_.AntivirusEnabled
                    RealTimeProtection = $_.RealTimeProtectionEnabled
                    SignatureAgeDays = $_.AntivirusSignatureAge
                }
            })
        FirewallProfiles = @(Invoke-ReadOnlyQuery { Get-NetFirewallProfile } | ForEach-Object {
            [ordered]@{ Name = $_.Name; Enabled = $_.Enabled; DefaultInbound = $_.DefaultInboundAction; DefaultOutbound = $_.DefaultOutboundAction }
        })
        BitLockerVolumes = @(Invoke-ReadOnlyQuery { Get-BitLockerVolume -ErrorAction Stop } | ForEach-Object {
            [ordered]@{ MountPoint = $_.MountPoint; VolumeStatus = $_.VolumeStatus; ProtectionStatus = $_.ProtectionStatus; EncryptionMethod = $_.EncryptionMethod }
        })
    }
}

$jsonPath = Join-Path $capturePath 'inventory.json'
$summaryPath = Join-Path $capturePath 'sanitized-summary.md'
$inventory | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8

$summary = @(
    '# Sanitized machine inventory'
    ''
    "- Collected (UTC): $($inventory.Collection.CollectedAt)"
    "- Manufacturer/model: $($inventory.Hardware.Manufacturer) / $($inventory.Hardware.Model)"
    "- Serial: $($inventory.Hardware.SerialNumber)"
    "- BIOS/UEFI: $($inventory.Hardware.BiosVersion); Secure Boot: $($inventory.Hardware.UefiSecureBoot)"
    "- TPM ready: $($inventory.Hardware.Tpm.Ready)"
    "- OS: $($inventory.OperatingSystem.Caption) ($($inventory.OperatingSystem.Build))"
    "- CPU: $($inventory.Compute.Cpu[0].Name); RAM: $($inventory.Compute.Memory.InstalledGiB) GiB"
    "- Physical disks: $($inventory.Storage.PhysicalDisks.Count); volumes: $($inventory.Storage.Volumes.Count)"
    "- Network adapters: $($inventory.Network.Count) (addresses and DNS redacted by default)"
    "- Installed software entries: $($inventory.InstalledSoftware.Count)"
    "- Hotfixes observed: $($inventory.WindowsPosture.HotfixCount)"
    ''
    'Review the JSON locally, redact any remaining identifying values, and copy only the needed facts into the Git-tracked template.'
)
$summary | Set-Content -Path $summaryPath -Encoding UTF8
Write-Output "Wrote read-only inventory to $capturePath"
