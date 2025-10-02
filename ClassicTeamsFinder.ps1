# PowerShell script to check for the presence of Classic Teams and New Teams applications

function WriteTrace {
    param ([string]$message)
    Write-Host "[TRACE] $message"
}

function GetProductsKey {
    $ProductsRegLM = Get-ChildItem -Path HKLM:\SOFTWARE\Classes\Installer\Products -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_ -match 'Teams Machine-Wide Installer' }
    $ProductsRegCU = Get-ChildItem -Path HKCU:\SOFTWARE\Microsoft\Installer\Products -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_ -match 'Teams Machine-Wide Installer' }

    WriteTrace("ProductsRegLM: $($ProductsRegLM.PSChildName)")
    WriteTrace("ProductsRegCU: $($ProductsRegCU.PSChildName)")

    $result = @()
    if ($ProductsRegLM) { $result += $ProductsRegLM }
    if ($ProductsRegCU) { $result += $ProductsRegCU }
    return $result
}


# Function to find classic Teams using application definitions and common registry paths
function Find-ClassicTeams {
    $regKeyError = $false

    $applicationDefinitions = @{
        Name = "Teams"
        DisplayName = "Teams"
        Publisher = "Microsoft"
        Exe = "teams"
        IDs = @(
            "731F6BAA-A986-45A4-8936-7C3AAAAA760B",
            "{731F6BAA-A986-45A4-8936-7C3AAAAA760B}",
            "39AF0813-FA7B-4860-ADBE-93B9B214B914",
            "{39AF0813-FA7B-4860-ADBE-93B9B214B914}"
        )
        RegistryKeys = @(
            "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Teams",
            "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
        )
    }

    # Check for Teams using specific registry keys in HKLM
    foreach ($regKey in $applicationDefinitions.RegistryKeys) {
        $fullRegKey = "HKLM:\" + $regKey
        try {
            if (Test-Path $fullRegKey) {
                $installedApps = Get-ChildItem -Path $fullRegKey | ForEach-Object {
                    Get-ItemProperty -Path $_.PSPath
                }

                foreach ($app in $installedApps) {
                    if ($app.DisplayName -like "*Teams*" -and $app.DisplayName -notlike "*Meeting Add-in*") {
                        return @{ClassicTeams = $true; RegKeyError = $regKeyError}
                    }
                }
            }
        } catch {
            Write-Warning "Failed to access registry key: $fullRegKey. Error: $_"
            $regKeyError = $true
        }
    }

    # Check for Teams using specific GUIDs in HKLM
    foreach ($guid in $applicationDefinitions.IDs) {
        $guidRegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$guid"
        try {
            if (Test-Path $guidRegKey) {
                return @{ClassicTeams = $true; RegKeyError = $regKeyError}
            }
        } catch {
            Write-Warning "Failed to access registry key: $guidRegKey. Error: $_"
            $regKeyError = $true
        }
    }

    # Check common registry paths in HKLM and HKCU
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    foreach ($path in $registryPaths) {
        try {
            if (Test-Path $path) {
                $installedApps = Get-ChildItem -Path $path | ForEach-Object {
                    Get-ItemProperty -Path $_.PSPath
                }

                foreach ($app in $installedApps) {
                    if ($app.DisplayName -like "*Teams*" -and $app.DisplayName -notlike "*Meeting Add-in*") {
                        return @{ClassicTeams = $true; RegKeyError = $regKeyError}
                    }
                }
            }
        } catch {
            Write-Warning "Could not access registry path: $path. Error: $_"
            $regKeyError = $true
        }
    }

    # Check each user profile for Classic Teams
    foreach ($userDirectory in Get-ChildItem "$($ENV:SystemDrive)\Users") {
        # Skip system profiles
        if ($userDirectory.Name -in @("Public", "Default", "Default User")) {
            continue
        }
        $ntUserDatPath = Join-Path $userDirectory.FullName "NTUSER.DAT"
        if (Test-Path $ntUserDatPath) {
            $userName = $userDirectory.Name.ToLower()

            try {
                $regKey = "HKLM\$userName"
                $loadCmd = "REG LOAD `"$regKey`" `"$ntUserDatPath`""
                $process = Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c", $loadCmd -Wait -WindowStyle Hidden -PassThru
                if ($process.ExitCode -ne 0) {
                    Write-Warning "Failed to load registry hive for user $userName"
                    continue
                }

                $uninstallPaths = @(
                    "HKLM:\$userName\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                    "HKLM:\$userName\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
                )

                foreach ($path in $uninstallPaths) {
                    try {
                        if (Test-Path $path) {
                            $apps = Get-ChildItem $path | ForEach-Object {
                                Get-ItemProperty $_.PSPath
                            }

                            foreach ($app in $apps) {
                                if ($app.DisplayName -like "*Teams*" -and $app.DisplayName -notlike "*Meeting Add-in*") {
                                    Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c", "REG UNLOAD "$regKey"" -Wait -WindowStyle Hidden | Out-Null
                                    return @{ClassicTeams = $true; RegKeyError = $regKeyError}
                                }
                            }
                        }
                    } catch {
                        Write-Warning "Could not access path $path in loaded hive for user $userName. Error: $_"
                        $regKeyError = $true
                    }
                }

                Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c", "REG UNLOAD "$regKey"" -Wait -WindowStyle Hidden | Out-Null
            } catch {
                Write-Warning "Unexpected error while processing user $userName"
                $regKeyError = $true
            }
        }
    }

    # Check MSI Installer Products for Teams Machine-Wide Installer
    try {
        $msiProducts = GetProductsKey
        if ($msiProducts.Count -gt 0) {
            return @{ClassicTeams = $true; RegKeyError = $regKeyError}
        }
    } catch {
        Write-Warning "Failed to check MSI installer products. Error: $_"
        $regKeyError = $true
    }

    return @{ClassicTeams = $false; RegKeyError = $regKeyError}
}

# Check for NewTeams using Get-AppxPackage
$NewTeamsPackage = Get-AppxPackage | Where-Object { $_.Name -match "MSTeams" }

$NewTeamsPresent = $NewTeamsPackage -ne $null


# Check for Classic Teams using the Find-ClassicTeams function
$Presence = Find-ClassicTeams

$ClassicTeamsPresent = $Presence.ClassicTeams
$RegKeyError = $Presence.regKeyError

function Log-Message {
    param (
        [string]$message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "$timestamp - $message"
    Write-Host $logMessage
}

function Report-TeamsPresence {
    param (
        [bool]$ClassicTeamsPresent,
        [bool]$NewTeamsPresent,
        [bool]$RegKeyError
    )
    $Url = "";
    if ($NewTeamsPresent -and $ClassicTeamsPresent) {
        $Url = "https://teams.microsoft.com/appdiag/WinClassicAndNewTeamsPresent"
        Log-Message "Both Classic Teams and New Teams are present"
    } elseif ($NewTeamsPresent -and $RegKeyError) {
        $Url = "https://teams.microsoft.com/appdiag/WinNewTeamsPresentClassicNotDetermined"
        Log-Message "New Teams is present, Classic Teams presence not determined"
    } elseif ($NewTeamsPresent -and -not $RegKeyError) {
        $Url = "https://teams.microsoft.com/appdiag/WinNewTeamsPresent"
        Log-Message "Only New Teams is present"
    } elseif ($ClassicTeamsPresent) {
        $Url = "https://teams.microsoft.com/appdiag/WinClassicTeamsPresent"
        Log-Message "Only Classic Teams is present"
    } elseif ($RegKeyError) {
        $Url = "https://teams.microsoft.com/appdiag/WinNoNewTeamsClassicNotDetermined"
        Log-Message "New Teams is not present, Classic Teams presence not determined"
    } else {
        $Url = "https://teams.microsoft.com/appdiag/WinNoTeamsPresent"
        Log-Message "Neither Classic Teams nor New Teams is present"
    }
    try {
        Invoke-WebRequest -Uri $Url
    } catch {
        Write-Warning "Failed to invoke web request to $Url. Error: $_"
    }
    
}

Report-TeamsPresence -ClassicTeamsPresent $ClassicTeamsPresent -NewTeamsPresent $NewTeamsPresent -RegKeyError $RegKeyError

# SIG # Begin signature block
# MIIoQQYJKoZIhvcNAQcCoIIoMjCCKC4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBfb561GAZwolYW
# 0t6H9tV3dYuVbJr8NkDgboNmZcCGsaCCDXYwggX0MIID3KADAgECAhMzAAAEBGx0
# Bv9XKydyAAAAAAQEMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjQwOTEyMjAxMTE0WhcNMjUwOTExMjAxMTE0WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQC0KDfaY50MDqsEGdlIzDHBd6CqIMRQWW9Af1LHDDTuFjfDsvna0nEuDSYJmNyz
# NB10jpbg0lhvkT1AzfX2TLITSXwS8D+mBzGCWMM/wTpciWBV/pbjSazbzoKvRrNo
# DV/u9omOM2Eawyo5JJJdNkM2d8qzkQ0bRuRd4HarmGunSouyb9NY7egWN5E5lUc3
# a2AROzAdHdYpObpCOdeAY2P5XqtJkk79aROpzw16wCjdSn8qMzCBzR7rvH2WVkvF
# HLIxZQET1yhPb6lRmpgBQNnzidHV2Ocxjc8wNiIDzgbDkmlx54QPfw7RwQi8p1fy
# 4byhBrTjv568x8NGv3gwb0RbAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQU8huhNbETDU+ZWllL4DNMPCijEU4w
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzUwMjkyMzAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAIjmD9IpQVvfB1QehvpC
# Ge7QeTQkKQ7j3bmDMjwSqFL4ri6ae9IFTdpywn5smmtSIyKYDn3/nHtaEn0X1NBj
# L5oP0BjAy1sqxD+uy35B+V8wv5GrxhMDJP8l2QjLtH/UglSTIhLqyt8bUAqVfyfp
# h4COMRvwwjTvChtCnUXXACuCXYHWalOoc0OU2oGN+mPJIJJxaNQc1sjBsMbGIWv3
# cmgSHkCEmrMv7yaidpePt6V+yPMik+eXw3IfZ5eNOiNgL1rZzgSJfTnvUqiaEQ0X
# dG1HbkDv9fv6CTq6m4Ty3IzLiwGSXYxRIXTxT4TYs5VxHy2uFjFXWVSL0J2ARTYL
# E4Oyl1wXDF1PX4bxg1yDMfKPHcE1Ijic5lx1KdK1SkaEJdto4hd++05J9Bf9TAmi
# u6EK6C9Oe5vRadroJCK26uCUI4zIjL/qG7mswW+qT0CW0gnR9JHkXCWNbo8ccMk1
# sJatmRoSAifbgzaYbUz8+lv+IXy5GFuAmLnNbGjacB3IMGpa+lbFgih57/fIhamq
# 5VhxgaEmn/UjWyr+cPiAFWuTVIpfsOjbEAww75wURNM1Imp9NJKye1O24EspEHmb
# DmqCUcq7NqkOKIG4PVm3hDDED/WQpzJDkvu4FrIbvyTGVU01vKsg4UfcdiZ0fQ+/
# V0hf8yrtq9CkB8iIuk5bBxuPMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGiEwghodAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAQEbHQG/1crJ3IAAAAABAQwDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBjLneJlQBeFtwwUGNYYvQLn
# /Qvn2sXidvewjlXI4AStMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAWWIe8SAcBjUwgzXDP8eIQrWDrFhtspYTHQOmIbCwIxebT1yEngv/qEX1
# x5mEQW17coqyIDc5vAJk9VaCUOVjOsL/e4l5lryR5Kiib4tlMj/EssBrK9sruuxG
# Akrgojqc0X01u0G1wCY/xDlj4Bmn0+gKvsdis+yF/c7De8yTMSxmEdmOLerfj2Gm
# NIoaZBYzB2a3DBstmPOiH+du8h2GFALGqNfvE++jXu4mq17mKTb1h8VkG7YdnOsJ
# hLM7s5ZBNkv+zovXtFkgaotUTpxk47ftVekARDDvCjReMUH9HuDdkYC1ibQUmIaI
# V//fmpJkyKBNTMpZwQ1dMH1qFr0ZP6GCF6swghenBgorBgEEAYI3AwMBMYIXlzCC
# F5MGCSqGSIb3DQEHAqCCF4QwgheAAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFYBgsq
# hkiG9w0BCRABBKCCAUcEggFDMIIBPwIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCAedPKMatZBO+tY8s2+LYpO3otcPebRi+uZMZNqf6uZqgIGaFmRIKDR
# GBEyMDI1MDcxMjAzNTc0My43WjAEgAIB9KCB2aSB1jCB0zELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxh
# bmQgT3BlcmF0aW9ucyBMaW1pdGVkMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046
# NjUxQS0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNl
# cnZpY2WgghH7MIIHKDCCBRCgAwIBAgITMwAAAfWZCZS88cZQjAABAAAB9TANBgkq
# hkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yNDA3
# MjUxODMxMDFaFw0yNTEwMjIxODMxMDFaMIHTMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVy
# YXRpb25zIExpbWl0ZWQxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo2NTFBLTA1
# RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMzvdHBUE1nf1j/OCE+yTCFt
# X0C+tbHX4JoZX09J72BG9pL5DRdO92cI73rklqLd/Oy4xNEwohvd3uiNB8yBUAZ2
# 8Rj/1jwVIqxau1hOUQLLoTX2FC/jyG/YyatwsFsSAn8Obf6U8iDh4yr6NZUDk1mc
# qYq/6bGcBBO8trlgD22SUxaynp+Ue98dh28cuHltQ3Jl48ptsBVr9dLAR+NGoyX3
# vjpMHE3aGK2NypKTf0UEo3snCtG4Y6NAhmCGGvmTAGqNEjUf0dSdWOrC5IgiTt2k
# K20tUs+5fv6iYMvH8hGTDQ+TLOwtLBGjr6AR4lkqUzOL3NMQywpnOjxr9NwrVrti
# osqqy/AQAdRGMjkoSNyE+/WqwyA6y/nXvdRX45kmwWOY/h70tJd3V5Iz9x6J/G++
# JVsIpBdK8xKxdJ95IVQLrMe0ptaBhvtOoc/VwMt1qLvk+knuqGuSw4kID031kf4/
# RTZPCbtOqEn04enNN1dLpZWtCMMvh81JflpmMRS1ND4ml7JoLnTcFap+dc6/gYt1
# zyfOcFrsuhhk+5wQ5lzc0zZMyvfAwUI0zmm0F1GfPOGG/QxTXIoJnlU2JMlF2eob
# HHfDcquOQNw925Pp157KICtWe82Y+l2xn7e8YDmL73lOqdPn67YWxezF7/ouanA/
# R3xZjquFWB3r1XrGG+j9AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUVeB8W/VKNKBw
# 8CWSXttosXtgdQEwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYD
# VR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwG
# CCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIw
# MjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBAHMMZlT2gPcR337q
# JtEzkqdobKbn9RtHB1vylxwLoZ6VvP0r5auY/WiiP/PxunxiEDK9M5aWrvI8vNyO
# M3JRnSY5eUtNksQ5VCmsLVr4H+4nWtOj4I3kDNXl+C7reG2z309BRKe+xu+oYcrF
# 8UyTR7+cvn8E4VHoonJYoWcKnGTKWuOpvqFeooE1OiNBJ53qLTKhbNEN8x4FVa+F
# l45xtgXJ5IqeNnncoP/Yl3M6kwaxJL089FJZbaRRmkJy86vjaPFRIKtFBu1tRC2R
# oZpsRZhwAcE0+rDyRVevA3y6AtIgfUG2/VWfJr201eSbSEgZJU7lQJRJM14vSyIz
# ZsfpJ3QXyj/HcRv8W0V6bUA0A2grEuqIC5MC4B+s0rPrpfVpsyNBfMyJm4Z2YVM4
# iB4XhaOB/maKIz2HIEyuv925Emzmm5kBX/eQfAenuVql20ubPTnTHVJVtYEyNa+b
# vlgMB9ihu3cZ3qE23/42Jd01LT+wB6cnJNnNJ7p/0NAsnKWvUFB/w8tNZOrUKJjV
# xo4r4NvwRnIGSdB8PAuilXpRCd9cS6BNtZvfjRIEigkaBRNS5Jmt9UsiGsp23WBG
# /LDpWcpzHZvMj5XQ8LheeLyYhAK463AzV3ugaG2VIk1kir79QyWnUdUlAjvzndtR
# oFPoWarvnSoIygGHXkyL4vUdq7S2MIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
# mQAAAAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNh
# dGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1
# WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjK
# NVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhg
# fWpSg0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJp
# rx2rrPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/d
# vI2k45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka9
# 7aSueik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKR
# Hh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9itu
# qBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyO
# ArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItb
# oKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6
# bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6t
# AgMBAAGjggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQW
# BBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacb
# UzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYz
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnku
# aHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIA
# QwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2
# VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwu
# bWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEw
# LTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYt
# MjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/q
# XBS2Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6
# U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVt
# I1TkeFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis
# 9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTp
# kbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0
# sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138e
# W0QBjloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJ
# sWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7
# Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0
# dFtq0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQ
# tB1VM1izoXBm8qGCA1YwggI+AgEBMIIBAaGB2aSB1jCB0zELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxh
# bmQgT3BlcmF0aW9ucyBMaW1pdGVkMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046
# NjUxQS0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNl
# cnZpY2WiIwoBATAHBgUrDgMCGgMVACbACruPDW0eWEYN1kgUAso83ZL2oIGDMIGA
# pH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQAC
# BQDsG8lIMCIYDzIwMjUwNzExMTczMjU2WhgPMjAyNTA3MTIxNzMyNTZaMHQwOgYK
# KwYBBAGEWQoEATEsMCowCgIFAOwbyUgCAQAwBwIBAAICPV8wBwIBAAICE0EwCgIF
# AOwdGsgCAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQAC
# AwehIKEKMAgCAQACAwGGoDANBgkqhkiG9w0BAQsFAAOCAQEAiLpo13/iaKRK6x7+
# bjjalUz7XPUGEx2uOcpWTz9xUlsajvftCnIrU54A/8YZTr8MYO8Gpzhwmruc+YYT
# GEN7NXPKt6DpiEm1Sxkypc+kI++tiBJTTb090eAcdy+6Z2T/aI2vM8PFGz7ar4kv
# hPfU0sHb1MGe5CmtXYIeggX6p0DKMyidM++hkzGF/Q7Q3c2JulMSCxMoXaGukjSM
# rYJoAklKxh3+BY1jkHm2Rv32IjSKRff2medBVZIVo+vF7iO4GajUAxgAvYeJgBfj
# Te5RAYyrcbl1Qv3AA16OahhweTyH18ahM4zYNwJW2dMCreGyF0WiF9eXnRKl/+X0
# x9YOeTGCBA0wggQJAgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# AhMzAAAB9ZkJlLzxxlCMAAEAAAH1MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG
# 9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIN0CSIx+tSgsQEy+
# TCn8ojQnoiOj/MHaplOW48/MZVglMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCB
# vQQgwdby0hcIdPSEruJHRL+P7YPXkdWJPMOce4+Rk4amjzUwgZgwgYCkfjB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAfWZCZS88cZQjAABAAAB9TAi
# BCBds2nLIrYT7bN07R97CwesbhzCPdtOxDl4mYjqU7djpjANBgkqhkiG9w0BAQsF
# AASCAgCxJXPmx2I+uAzQCYuYH7tQauwDYJHf8vx8h20SmKqycrUzFQnD8v6uE4uc
# 4vLp1Axdx2EsLzIWHNaleGtbbRhtqq0QNz9aTGUSZa4z7mUfI4MdkiNVO9dxd5fR
# SL5Bt7lCmEGI/qgqcMv2S5OLmtPEGQx3U29Ru+foxiIg7OhDKgS3DqqHEvhm7r+4
# BInLb+vezy294gAHQ+0w19oDQ050KxTTxPBWlGM3mXKUNai67S9Oi7EdVLaCZbtJ
# UZ8F5jL40FcguZn5X8QtcBo5FuxqR8rLi5plEQuUKyLEfJ0lsQ+ltB1OONtvkYqh
# 7gLX8ibtHVS//N7JnpWHqRARmQ/b773AifOvrk3I5tsvQhTzJkStZ2Bppk2/BROQ
# zEurccJBktlZirBOYbr9fsisFcv/xlxiBT05UIkCkkmr+FXTH9OJxT65HzJg92L2
# PG2oMu2n8Fmn4mpCa5ArLBx4+quuNFeLQQMb/UCHJf9n+wPQS2tGFvSwlg2hCwuS
# 3lVCIU3DM7QqnwQZ/5uDRyPl6GmF4HqYrWE6T9uRIg2gkyw3v1aa9PB1abfKvHEP
# g7f+BOxGJz+T9LxdYWO0GE1QgPoEZ8iOW99YUK0DXMIdEKqEgHyG5GsubHsg0jC2
# x6DzoreJdb283n2gjJNgpz1QAhp1MP0MxPsALYlM+ZK69mFPUg==
# SIG # End signature block
