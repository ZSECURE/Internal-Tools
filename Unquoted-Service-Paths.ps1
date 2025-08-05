Get-WmiObject -Class Win32_Service |
    Select-Object Name, PathName, DisplayName, StartMode |
    Where-Object {
        $_.Name -notmatch 'windows' -and
        $_.PathName -notmatch 'windows' -and
        $_.DisplayName -notmatch 'windows' -and
        $_.StartMode -notmatch 'windows' -and
        $_.Name -notmatch 'system32' -and
        $_.PathName -notmatch 'system32' -and
        $_.DisplayName -notmatch 'system32' -and
        $_.StartMode -notmatch 'system32' -and
        $_.Name -notmatch '"' -and
        $_.PathName -notmatch '"' -and
        $_.DisplayName -notmatch '"' -and
        $_.StartMode -notmatch '"'
    } |
    Format-Table Name, DisplayName, StartMode, PathName -AutoSize

#OneLiner
#Get-WmiObject -Class Win32_Service | Select-Object Name, PathName, DisplayName, StartMode | Where-Object {($_.Name -notmatch 'windows') -and ($_.PathName -notmatch 'windows') -and ($_.DisplayName -notmatch 'windows') -and ($_.StartMode -notmatch 'windows') -and ($_.Name -notmatch 'system32') -and ($_.PathName -notmatch 'system32') -and ($_.DisplayName -notmatch 'system32') -and ($_.StartMode -notmatch 'system32') -and ($_.Name -notmatch '"') -and ($_.PathName -notmatch '"') -and ($_.DisplayName -notmatch '"') -and ($_.StartMode -notmatch '"')} | Format-Table Name, DisplayName, StartMode, PathName -AutoSize
