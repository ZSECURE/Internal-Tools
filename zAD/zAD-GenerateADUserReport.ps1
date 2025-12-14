<# 
    Generate-AdUserReport.ps1

    - Creates a user statistics table similar to the screenshot
    - Creates a privileged group statistics table
    - Saves the output of each command / dataset to a separate file
#>

param(
    # Where all CSV/TXT files will be written
    [string]$OutputFolder = "C:\AD_Report"
)

Import-Module ActiveDirectory

# Make sure the output folder exists
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory | Out-Null
}

# -------------------------------------------------------------------
# 1. Collect all users and common properties (SINGLE directory query)
# -------------------------------------------------------------------
$allUsers = Get-ADUser -Filter * -Properties `
    Enabled,
    PasswordLastSet,
    PasswordNeverExpires,
    LastLogonDate,
    AccountNotDelegated,
    PasswordNotRequired,
    AllowReversiblePasswordEncryption,
    DoesNotRequirePreAuth

# Save raw list of all users
$allUsers | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "AllUsers.csv")

$totalUsers = $allUsers.Count

# Helper function to compute percentage
function Get-Percent {
    param(
        [int]$Count,
        [int]$Total
    )
    if ($Total -eq 0) { return 0 }
    return [math]::Round(($Count / $Total) * 100, 0)
}

# -------------------------------------------------------------------
# 2. Compute each statistic + save each dataset to its own file
# -------------------------------------------------------------------

# Active vs inactive
$activeUsers   = $allUsers | Where-Object { $_.Enabled -eq $true }
$inactiveUsers = $allUsers | Where-Object { $_.Enabled -eq $false }

$activeUsers   | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "ActiveUsers.csv")
$inactiveUsers | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "InactiveUsers.csv")

# Password changed more than 1 year ago
$cutoff1Yr  = (Get-Date).AddYears(-1)
$pw1YearOld = $allUsers | Where-Object {
    $_.PasswordLastSet -and $_.PasswordLastSet -lt $cutoff1Yr
}
$pw1YearOld | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "PasswordOlderThan1Year.csv")

# Password changed more than 5 years ago
$cutoff5Yr  = (Get-Date).AddYears(-5)
$pw5YearOld = $allUsers | Where-Object {
    $_.PasswordLastSet -and $_.PasswordLastSet -lt $cutoff5Yr
}
$pw5YearOld | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "PasswordOlderThan5Years.csv")

# Password never expires
$pwNeverExpires = $allUsers | Where-Object { $_.PasswordNeverExpires -eq $true }
$pwNeverExpires | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "PasswordNeverExpires.csv")

# Active users who have never logged in (no LastLogonDate)
$activeNeverLoggedOn = $activeUsers | Where-Object { -not $_.LastLogonDate }
$activeNeverLoggedOn | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "ActiveUsersNeverLoggedOn.csv")

# User delegation allowed
# (accounts that are NOT marked "Account is sensitive and cannot be delegated")
$userDelegationAllowed = $allUsers | Where-Object { $_.AccountNotDelegated -eq $false }
$userDelegationAllowed | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "UserDelegationAllowed.csv")

# Password not required
$pwNotRequired = $allUsers | Where-Object { $_.PasswordNotRequired -eq $true }
$pwNotRequired | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "PasswordNotRequired.csv")

# Passwords stored with reversible encryption
$pwReversible = $allUsers | Where-Object { $_.AllowReversiblePasswordEncryption -eq $true }
$pwReversible | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "PasswordReversibleEncryption.csv")

# Kerberos pre-authentication disabled
$noKrbPreAuth = $allUsers | Where-Object { $_.DoesNotRequirePreAuth -eq $true }
$noKrbPreAuth | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "KerberosPreAuthDisabled.csv")

# -------------------------------------------------------------------
# 3. Build the "User statistics" table (like the screenshot)
# -------------------------------------------------------------------
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

# Save the summary table
$userStats | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "UserStatisticsSummary.csv")

# -------------------------------------------------------------------
# 4. Privileged group statistics table
# -------------------------------------------------------------------
$domainName = (Get-ADDomain).DNSRoot

# Adjust this list to match your environment / report
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

    # Get all *user* members (recursive)
    $members = Get-ADGroupMember -Identity $group.DistinguishedName -Recursive `
               | Where-Object { $_.ObjectClass -eq 'user' }

    # Save full member list to its own file
    $members | Select-Object Name,SamAccountName,DistinguishedName `
        | Export-Csv -NoTypeInformation -Encoding UTF8 `
        -Path (Join-Path $OutputFolder ("GroupMembers_{0}.csv" -f $group.SamAccountName))

    $privStats += [PSCustomObject]@{
        'Group name'             = ("{0}@{1}" -f $group.SamAccountName, $domainName)
        'Number of group members' = $members.Count
    }
}

# Save privileged group summary table
$privStats | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path (Join-Path $OutputFolder "PrivilegedGroupStatisticsSummary.csv")

# -------------------------------------------------------------------
# 5. Show the two tables on screen, formatted
# -------------------------------------------------------------------
Write-Host "`nUser statistics`n--------------"
$userStats | Format-Table -AutoSize

Write-Host "`nPrivileged group statistics`n---------------------------"
$privStats | Format-Table -AutoSize
