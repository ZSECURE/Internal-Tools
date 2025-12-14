<#
    zAD-GenerateADUserReportWComputers.ps1

    - User statistics (with per-category CSVs + summary)
    - Privileged group statistics (per-group CSVs + summary)
    - Computer statistics:
        * OS summary (per-OS counts)
        * Last logon buckets (<=30d, 31–90d, >90d/never)
        * Separate CSVs for each dataset

    Requires: RSAT ActiveDirectory module.
#>

param(
    [string]$OutputFolder = "C:\AD_Report"
)

Import-Module ActiveDirectory

if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory | Out-Null
}

# ---------------------------
# Helper: percentage function
# ---------------------------
function Get-Percent {
    param(
        [int]$Count,
        [int]$Total
    )
    if ($Total -eq 0) { return 0 }
    return [math]::Round(($Count / $Total) * 100, 0)
}

# =====================================================
# 1. USER STATISTICS
# =====================================================

$allUsers = Get-ADUser -Filter * -Properties `
    Enabled,
    PasswordLastSet,
    PasswordNeverExpires,
    LastLogonDate,
    AccountNotDelegated,
    PasswordNotRequired,
    AllowReversiblePasswordEncryption,
    DoesNotRequirePreAuth

$allUsers | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "AllUsers.csv")

$totalUsers = $allUsers.Count

$activeUsers   = $allUsers | Where-Object { $_.Enabled -eq $true }
$inactiveUsers = $allUsers | Where-Object { $_.Enabled -eq $false }

$activeUsers   | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "ActiveUsers.csv")
$inactiveUsers | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "InactiveUsers.csv")

$cutoff1Yr  = (Get-Date).AddYears(-1)
$pw1YearOld = $allUsers | Where-Object {
    $_.PasswordLastSet -and $_.PasswordLastSet -lt $cutoff1Yr
}
$pw1YearOld | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "PasswordOlderThan1Year.csv")

$cutoff5Yr  = (Get-Date).AddYears(-5)
$pw5YearOld = $allUsers | Where-Object {
    $_.PasswordLastSet -and $_.PasswordLastSet -lt $cutoff5Yr
}
$pw5YearOld | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "PasswordOlderThan5Years.csv")

$pwNeverExpires = $allUsers | Where-Object { $_.PasswordNeverExpires -eq $true }
$pwNeverExpires | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "PasswordNeverExpires.csv")

$activeNeverLoggedOn = $activeUsers | Where-Object { -not $_.LastLogonDate }
$activeNeverLoggedOn | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "ActiveUsersNeverLoggedOn.csv")

$userDelegationAllowed = $allUsers | Where-Object { $_.AccountNotDelegated -eq $false }
$userDelegationAllowed | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "UserDelegationAllowed.csv")

$pwNotRequired = $allUsers | Where-Object { $_.PasswordNotRequired -eq $true }
$pwNotRequired | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "PasswordNotRequired.csv")

$pwReversible = $allUsers | Where-Object { $_.AllowReversiblePasswordEncryption -eq $true }
$pwReversible | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "PasswordReversibleEncryption.csv")

$noKrbPreAuth = $allUsers | Where-Object { $_.DoesNotRequirePreAuth -eq $true }
$noKrbPreAuth | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "KerberosPreAuthDisabled.csv")

$userStats = @()
$userStats += [PSCustomObject]@{
    Description = "Active Users"
    Number      = $activeUsers.Count
    Percent     = "$(Get-Percent -Count $activeUsers.Count -Total $totalUsers)%"
}
$userStats += [PSCustomObject]@{
    Description = "Inactive Users"
    Number      = $inactiveUsers.Count
    Percent     = "$(Get-Percent -Count $inactiveUsers.Count -Total $totalUsers)%"
}
$userStats += [PSCustomObject]@{
    Description = "Password changed more than 1 year ago"
    Number      = $pw1YearOld.Count
    Percent     = "$(Get-Percent -Count $pw1YearOld.Count -Total $totalUsers)%"
}
$userStats += [PSCustomObject]@{
    Description = "Password changed more than 5 years ago"
    Number      = $pw5YearOld.Count
    Percent     = "$(Get-Percent -Count $pw5YearOld.Count -Total $totalUsers)%"
}
$userStats += [PSCustomObject]@{
    Description = "Password never expires"
    Number      = $pwNeverExpires.Count
    Percent     = "$(Get-Percent -Count $pwNeverExpires.Count -Total $totalUsers)%"
}
$userStats += [PSCustomObject]@{
    Description = "Active users who have never logged in"
    Number      = $activeNeverLoggedOn.Count
    Percent     = "$(Get-Percent -Count $activeNeverLoggedOn.Count -Total $totalUsers)%"
}
$userStats += [PSCustomObject]@{
    Description = "User delegation allowed"
    Number      = $userDelegationAllowed.Count
    Percent     = "$(Get-Percent -Count $userDelegationAllowed.Count -Total $totalUsers)%"
}
$userStats += [PSCustomObject]@{
    Description = "Password not required"
    Number      = $pwNotRequired.Count
    Percent     = "$(Get-Percent -Count $pwNotRequired.Count -Total $totalUsers)%"
}
$userStats += [PSCustomObject]@{
    Description = "Passwords stored with reversible encryption"
    Number      = $pwReversible.Count
    Percent     = "$(Get-Percent -Count $pwReversible.Count -Total $totalUsers)%"
}
$userStats += [PSCustomObject]@{
    Description = "Users with Kerberos Pre-Authentication disabled"
    Number      = $noKrbPreAuth.Count
    Percent     = "$(Get-Percent -Count $noKrbPreAuth.Count -Total $totalUsers)%"
}

$userStats | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "UserStatisticsSummary.csv")

# =====================================================
# 2. PRIVILEGED GROUP STATISTICS
# =====================================================

$domainName = (Get-ADDomain).DNSRoot

$privilegedGroups = @(
    'Administrators',
    'Domain Admins',
    'Enterprise Admins',
    'Schema Admins',
    'Server Operators',
    'Account Operators',
    'Backup Operators',
    'Print Operators',
    'Cert Publishers',
    'DnsAdmins'
)

$privStats = @()

foreach ($grpName in $privilegedGroups) {
    $group = Get-ADGroup -Identity $grpName -ErrorAction SilentlyContinue
    if (-not $group) { continue }

    $members = Get-ADGroupMember -Identity $group.DistinguishedName -Recursive |
               Where-Object { $_.ObjectClass -eq 'user' }

    $members | Select-Object Name,SamAccountName,DistinguishedName |
        Export-Csv -NoTypeInformation -Encoding UTF8 `
        -Path (Join-Path $OutputFolder ("GroupMembers_{0}.csv" -f $group.SamAccountName))

    $privStats += [PSCustomObject]@{
        'Group name'              = ("{0}@{1}" -f $group.SamAccountName, $domainName)
        'Number of group members' = $members.Count
    }
}

$privStats | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "PrivilegedGroupStatisticsSummary.csv")

# =====================================================
# 3. COMPUTER STATISTICS
# =====================================================

# Include LastLogonDate so we can bucket by last logon time.
$allComputers = Get-ADComputer -Filter * -Properties `
    OperatingSystem,
    OperatingSystemServicePack,
    OperatingSystemVersion,
    LastLogonDate

$allComputers |
    Select-Object Name,
                  OperatingSystem,
                  OperatingSystemServicePack,
                  OperatingSystemVersion,
                  LastLogonDate |
    Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "AllComputers.csv")

$totalComputers = $allComputers.Count

# Time cutoffs for buckets
$now      = Get-Date
$cutoff30 = $now.AddDays(-30)
$cutoff90 = $now.AddDays(-90)

# Build OS display + keep LastLogonDate
$computerOsInfo = $allComputers | Select-Object Name,
    OperatingSystem,
    OperatingSystemServicePack,
    OperatingSystemVersion,
    LastLogonDate,
    @{
        Name       = 'OperatingSystemDisplay'
        Expression = {
            ($_.OperatingSystem, $_.OperatingSystemServicePack) -join " " `
                -replace '\s+$',''
        }
    }

$computerOsInfo | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "ComputerOSDisplay.csv")

# ---- Last logon buckets (three separate CSVs) ----

$computersLast30 = $computerOsInfo | Where-Object {
    $_.LastLogonDate -and $_.LastLogonDate -ge $cutoff30
}
$computers30to90 = $computerOsInfo | Where-Object {
    $_.LastLogonDate -and
    $_.LastLogonDate -lt $cutoff30 -and
    $_.LastLogonDate -ge $cutoff90
}
$computersOver90 = $computerOsInfo | Where-Object {
    -not $_.LastLogonDate -or $_.LastLogonDate -lt $cutoff90
}

$computersLast30 | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "ComputersLastLogon_0to30Days.csv")
$computers30to90 | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "ComputersLastLogon_31to90Days.csv")
$computersOver90 | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "ComputersLastLogon_Over90Days.csv")

# ---- OS summary table including last-logon columns ----

$osCounts = $computerOsInfo |
    Group-Object -Property OperatingSystemDisplay |
    Sort-Object -Property Count -Descending |
    ForEach-Object {
        $group  = $_
        $osName = if ([string]::IsNullOrWhiteSpace($group.Name)) {
                      'Unknown'
                  } else {
                      $group.Name
                  }

        $items  = $group.Group
        $total  = $items.Count
        $last30 = ($items | Where-Object { $_.LastLogonDate -ge $cutoff30 }).Count
        $d30to90 = ($items | Where-Object {
            $_.LastLogonDate -lt $cutoff30 -and $_.LastLogonDate -ge $cutoff90
        }).Count
        $over90 = $total - $last30 - $d30to90   # includes never-logged-on

        [PSCustomObject]@{
            'Operating System'                 = $osName
            'Total'                            = $total
            'Last logon <= 30 days'            = $last30
            'Last logon 31-90 days'            = $d30to90
            'Last logon > 90 days or never'    = $over90
        }
    }

$osCounts | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "ComputerStatisticsSummary.csv")

# ---- Unsupported OS list (older than Win10 / modern Server) ----
# This still treats very old versions (XP/2003/2008/7, etc.) as unsupported.
# Newer OS versions like Win10/11 and Server 2012–2025 are automatically
# included in the stats above and considered supported here.

$unsupportedPatterns = @(
    'Windows XP',
    'Windows Server 2003',
    'Windows Server 2008',
    'Windows Server 2008 R2',
    'Windows 7'
)

$unsupportedComputers = $computerOsInfo | Where-Object {
    $display = $_.OperatingSystemDisplay
    $isOld = $false
    foreach ($p in $unsupportedPatterns) {
        if ($display -like "*$p*") {
            $isOld = $true
            break
        }
    }
    $isOld
}

$unsupportedComputers | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "UnsupportedComputers.csv")

$unsupportedCount = $unsupportedComputers.Count

# =====================================================
# 4. CONSOLE OUTPUT
# =====================================================

Write-Host "`nUser statistics`n--------------"
$userStats | Format-Table -AutoSize

Write-Host "`nPrivileged group statistics`n---------------------------"
$privStats | Format-Table -AutoSize

Write-Host "`nComputer statistics`n---------------------"
Write-Host "At the time of the audit, there were $totalComputers machine accounts registered in the Active Directory domain.`n"

$osCounts | Format-Table -AutoSize

Write-Host "`nLast logon buckets (all computers):"
Write-Host ("  <= 30 days : {0}" -f $computersLast30.Count)
Write-Host ("  31–90 days : {0}" -f $computers30to90.Count)
Write-Host ("  > 90 days or never : {0}" -f $computersOver90.Count)

Write-Host "`n$unsupportedCount computers and servers are using unsupported operating systems (see UnsupportedComputers.csv)."
