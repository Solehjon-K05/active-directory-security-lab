# Kerberos Failed Login Monitor
# Checks Event ID 4771 from the last 24 hours

$Events = @(
    Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        Id = 4771
        StartTime = (Get-Date).AddHours(-24)
    } -ErrorAction SilentlyContinue
)

Write-Host "`n=== KERBEROS SECURITY REPORT ===" -ForegroundColor Cyan

Write-Host "Total failed authentications: $($Events.Count)"

$Report = @(
    foreach ($Event in $Events) {
        $XML = [xml]$Event.ToXml()
        $Fields = @{}

        foreach ($Data in $XML.Event.EventData.Data) {
            $Fields[$Data.Name] = $Data.'#text'
        }

        [PSCustomObject]@{
            Time     = $Event.TimeCreated
            Username = $Fields['TargetUserName']
            SourceIP = $Fields['IpAddress']
            Failure  = $Fields['Status']
        }
    }
)

$Report | Format-Table -AutoSize
Write-Host "`n=== FAILED LOGINS BY SOURCE IP ===" -ForegroundColor Cyan

$IPReport = $Report |
    Group-Object SourceIP |
    Sort-Object Count -Descending

$IPReport |
    Select-Object Count, Name |
    Format-Table -AutoSize

foreach ($IP in $IPReport) {
    if ($IP.Count -ge 5) {
        Write-Host "WARNING: $($IP.Count) failed logins from IP $($IP.Name)" -ForegroundColor Red
    }
}

if ($Events.Count -ge 5) {
    Write-Host "WARNING: Multiple authentication failures detected!" -ForegroundColor Red
} else {
    Write-Host "No threshold alert triggered." -ForegroundColor Green
}