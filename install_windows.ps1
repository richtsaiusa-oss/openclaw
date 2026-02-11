# 檢查並安裝 Node.js 和 pnpm
function Install-NodeAndPnpm {
    Write-Host "檢查 Node.js 和 pnpm 環境…"
    try {
        $nodeVersion = (node -v).Trim()
        Write-Host "已安裝 Node.js 版本: $nodeVersion"
    } catch {
        Write-Host "未偵測到 Node.js，開始安裝…"
        Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi" -OutFile "$env:TEMP\node-installer.msi"
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$env:TEMP\node-installer.msi`" /qn /norestart" -Wait
        Remove-Item "$env:TEMP\node-installer.msi"
        Write-Host "Node.js 安裝完成。"
    }
    try {
        $pnpmVersion = (pnpm -v).Trim()
        Write-Host "已安裝 pnpm 版本: $pnpmVersion"
    } catch {
        Write-Host "未偵測到 pnpm，開始安裝…"
        npm install -g pnpm
        Write-Host "pnpm 安裝完成。"
    }
}
Install-NodeAndPnpm
Write-Host "更新 OpenClaw 專案…"
$repoDir = "$PSScriptRoot"
Set-Location $repoDir
pnpm install
pnpm build
Write-Host "設定 OpenClaw 配置檔…"
$openclawConfigDir = "$env:USERPROFILE\.openclaw"
if (-not (Test-Path $openclawConfigDir)) {
    New-Item -Path $openclawConfigDir -ItemType Directory | Out-Null
}
$openclawConfigContent = @"
{
  "gateway": {
    "mode": "local",
    "port": 18789,
    "token": "mysecrettoken"
  },
  "channels": {
    "line": {
      "enabled": true,
      "channelSecret": "11fb51ed92249db32e27cf3cb816bb2b",
      "channelAccessToken": "bPWeGqEplzCspzeWsYO0IFZvr1+jK5hFOQGS03Taiyw+sPsF/Gb1X6N9iZHiz4E0XvSRnKleH60YubYeQoj15gypPS57cJ3mUvyiD5qiAy+fIzl4BSReRDP52BXDnBRhMxDQJXE0ZeQ9qK3OTdSk/QdB04t89/1O/w1cDnyilFU="
    }
  },
  "llm": {
    "openai": {
      "apiKey": "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"
    }
  }
}
"@
$openclawConfigContent | Out-File -FilePath "$openclawConfigDir\openclaw.json" -Encoding UTF8
Write-Host "下載並設定 Cloudflare Tunnel…"
$cloudflaredDir = "$env:USERPROFILE\.cloudflared"
if (-not (Test-Path $cloudflaredDir)) {
    New-Item -Path $cloudflaredDir -ItemType Directory | Out-Null
}
$cloudflaredExePath = "$cloudflaredDir\cloudflared.exe"
if (-not (Test-Path $cloudflaredExePath)) {
    Write-Host "下載 cloudflared.exe…"
    Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile $cloudflaredExePath
}
Write-Host "啟動 OpenClaw 和 Cloudflare Tunnel…"
Start-Process -FilePath "node.exe" -ArgumentList "$repoDir\dist\index.js", "gateway", "run" -WindowStyle Hidden -NoNewWindow
Start-Process -FilePath $cloudflaredExePath -ArgumentList "tunnel", "--url", "http://127.0.0.1:18789" -WindowStyle Hidden -NoNewWindow
Write-Host "OpenClaw 和 Cloudflare Tunnel 已在背景啟動。"
Write-Host "請等待約 10-20 秒，然後檢查 Cloudflare Tunnel 的公開網址。"
Write-Host "網址格式類似：https://xxxx.trycloudflare.com"
Write-Host "請將此網址加上 /line/webhook 更新到您的 LINE Developers Console 中。"
