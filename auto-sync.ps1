# Auto GitHub Sync — index.html o'zgarganda avtomatik push qiladi
# Ishlatish: PowerShell da ./auto-sync.ps1

$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$watchFile   = "index.html"
$debounceMs  = 3000   # 3 soniya kutadi (rapid save larni birlashtiradi)

Write-Host ""
Write-Host "  GitHub Auto-Sync ishga tushdi" -ForegroundColor Cyan
Write-Host "  Papka : $projectPath" -ForegroundColor Gray
Write-Host "  Fayl  : $watchFile" -ForegroundColor Gray
Write-Host "  To'xtatish: Ctrl+C" -ForegroundColor Gray
Write-Host ""

Set-Location $projectPath

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path   = $projectPath
$watcher.Filter = $watchFile
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
$watcher.EnableRaisingEvents = $true

$lastPush   = [datetime]::MinValue
$timer      = $null
$pendingPush = $false

$action = {
    $pendingPush = $true
}

$changed = Register-ObjectEvent $watcher Changed -Action $action

Write-Host "  Tayyor. $watchFile kuzatilmoqda..." -ForegroundColor Green
Write-Host ""

try {
    while ($true) {
        Start-Sleep -Milliseconds 500

        if ($pendingPush) {
            $pendingPush = $false
            $sinceLastMs = ([datetime]::Now - $lastPush).TotalMilliseconds

            if ($sinceLastMs -lt $debounceMs) {
                continue
            }

            Start-Sleep -Milliseconds 1500

            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
            Write-Host "[$timestamp] O'zgarish aniqlandi, yuklanmoqda..." -ForegroundColor Yellow

            $gitStatus = git status --porcelain 2>&1
            if (-not $gitStatus) {
                Write-Host "  Yangi o'zgarish yo'q, o'tkazildi." -ForegroundColor Gray
                continue
            }

            git add index.html 2>&1 | Out-Null

            $commitMsg = "Auto-sync: $timestamp"
            git commit -m $commitMsg 2>&1 | Out-Null

            $pushResult = git push origin main 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  GitHub'ga yuklandi!" -ForegroundColor Green
            } else {
                Write-Host "  Push xatosi: $pushResult" -ForegroundColor Red
                Write-Host "  Qayta urinilmoqda..." -ForegroundColor Yellow
                Start-Sleep -Seconds 5
                git push origin main 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  Muvaffaqiyatli yuklandi!" -ForegroundColor Green
                } else {
                    Write-Host "  Yuklash amalga oshmadi. Internet aloqasini tekshiring." -ForegroundColor Red
                }
            }

            $lastPush = [datetime]::Now
            Write-Host ""
        }
    }
} finally {
    Unregister-Event -SourceIdentifier $changed.Name
    $watcher.Dispose()
    Write-Host "Auto-sync to'xtatildi." -ForegroundColor Gray
}
