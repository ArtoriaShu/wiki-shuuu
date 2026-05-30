<# ::
@echo off
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~f0""' -Verb RunAs"
exit /b
#>

#Requires -RunAsAdministrator
<#
.SYNOPSIS
    一键下载并安装/卸载常用工具：PixPin、EcoPaste、Pot、Everything、InputTips
.PARAMETER DownloadDir
    安装包临时存放目录，默认 %TEMP%\ToolInstaller
.PARAMETER KeepInstallers
    安装完成后保留安装包
.PARAMETER GitHubToken
    GitHub Personal Access Token，用于提高 API 速率限制（未认证限 60 次/小时）
    也可通过环境变量 GITHUB_TOKEN 传入
.EXAMPLE
    .\install.ps1
    .\install.ps1 -DownloadDir "D:\Downloads"
    .\install.ps1 -KeepInstallers
    .\install.ps1 -GitHubToken "ghp_xxxx"
#>
param(
    [string]$DownloadDir = "",
    [switch]$KeepInstallers,
    [string]$GitHubToken = $env:GITHUB_TOKEN
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ── 工具列表 ──────────────────────────────────────────────────────────────────

$AllTools = @("PixPin", "EcoPaste", "Pot", "Everything", "InputTips")

$UninstallArgs = @{
    "EcoPaste"   = "/S"
    "Pot"        = "/S"
    "Everything" = "/S"
    "PixPin"     = "/S"
}

# ── 输出辅助 ──────────────────────────────────────────────────────────────────

function Write-Step { param([string]$m) Write-Host "`n>>> $m" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "    [OK] $m" -ForegroundColor Green }
function Write-Err  { param([string]$m) Write-Host "    [FAIL] $m" -ForegroundColor Red }
function Write-Info { param([string]$m) Write-Host "    $m" -ForegroundColor Gray }

# ── 菜单辅助 ──────────────────────────────────────────────────────────────────

function Show-MainMenu {
    Write-Host ""
    Write-Host "========== 工具管理器 ==========" -ForegroundColor Cyan
    Write-Host "  1. 安装工具"
    Write-Host "  2. 卸载工具"
    Write-Host "  0. 退出"
    Write-Host "================================" -ForegroundColor Cyan
}

function Show-ToolMenu {
    param([string]$Action)
    Write-Host ""
    Write-Host "--- 选择要${Action}的工具 ---" -ForegroundColor Cyan
    for ($i = 0; $i -lt $AllTools.Count; $i++) {
        Write-Host "  $($i+1). $($AllTools[$i])"
    }
    Write-Host "  A. 全部"
    Write-Host "  0. 返回"
    Write-Host ""
}

function Read-ToolSelection {
    param([string]$Action)
    Show-ToolMenu $Action
    $userInput = (Read-Host "请输入编号（多选用逗号分隔，如 1,3,5）").Trim()
    if ($userInput -eq "0") { return $null }
    if ($userInput -match '^[Aa]$') { return $AllTools }
    $selected = @()
    foreach ($part in ($userInput -split ',')) {
        $n = $part.Trim()
        if ($n -match '^\d+$') {
            $idx = [int]$n - 1
            if ($idx -ge 0 -and $idx -lt $AllTools.Count) {
                $selected += $AllTools[$idx]
            } else {
                Write-Host "  无效编号: $n，已跳过" -ForegroundColor Yellow
            }
        }
    }
    if ($selected.Count -eq 0) {
        Write-Host "  未选择任何工具" -ForegroundColor Yellow
        return $null
    }
    return $selected
}

# ── 下载辅助 ──────────────────────────────────────────────────────────────────

function Get-GitHubLatestAsset {
    param([string]$Repo, [string]$Pattern)
    Write-Info "查询 GitHub 最新版本: $Repo"
    $headers = @{ "User-Agent" = "ToolInstaller/1.0" }
    if ($GitHubToken) { $headers["Authorization"] = "Bearer $GitHubToken" }
    try {
        $release = Invoke-RestMethod `
            -Uri "https://api.github.com/repos/$Repo/releases/latest" `
            -Headers $headers `
            -TimeoutSec 30
    } catch {
        if ($_.Exception.Response.StatusCode -eq 403) {
            throw "GitHub API 速率限制已触发。请通过 -GitHubToken 参数或设置环境变量 GITHUB_TOKEN 来提高限制。"
        }
        throw
    }
    $asset = $release.assets | Where-Object { $_.name -match $Pattern } | Select-Object -First 1
    if (-not $asset) { throw "在 $Repo 中未找到匹配 '$Pattern' 的资产" }
    Write-Info "最新版本: $($release.tag_name)  文件: $($asset.name)"
    return $asset.browser_download_url
}

function Get-EverythingDownloadUrl {
    Write-Info "查询 Everything 最新版本..."
    $page  = Invoke-WebRequest "https://www.voidtools.com/downloads/" -UseBasicParsing -TimeoutSec 30
    $match = [regex]::Match($page.Content, '/Everything-\d+\.\d+\.\d+\.\d+\.x64-Setup\.exe')
    if (-not $match.Success) { throw "无法从 voidtools.com 获取下载链接" }
    return "https://www.voidtools.com$($match.Value)"
}

function Get-PixPinDownloadUrl {
    Write-Info "查询 PixPin 最新版本..."
    $pattern = 'https://[^"'']+/PixPin[_-][\d.]+[^"'']*\.exe'
    foreach ($site in @("https://pixpinapp.com/", "https://pixpin.cn/")) {
        try {
            $page  = Invoke-WebRequest $site -UseBasicParsing -TimeoutSec 15
            $match = [regex]::Match($page.Content, $pattern)
            if ($match.Success) { return $match.Value }
        } catch {
            Write-Info "访问 $site 失败，尝试下一个..."
        }
    }
    throw "无法自动获取 PixPin 下载链接，请手动前往 https://pixpinapp.com 下载"
}

function Save-File {
    param([string]$Url, [string]$Dest)
    $fileName = [System.IO.Path]::GetFileName($Dest)
    Write-Info "下载: $fileName"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing -TimeoutSec 300
    } catch {
        throw "下载失败 ($fileName): $_"
    }
}

function Invoke-NsisInstaller {
    param([string]$Path)
    $p = Start-Process -FilePath $Path -ArgumentList "/S" -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "安装程序退出码: $($p.ExitCode)" }
}

# ── 卸载辅助 ──────────────────────────────────────────────────────────────────

function Get-UninstallEntry {
    param([string]$DisplayNamePattern)
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($path in $paths) {
        $entry = Get-ItemProperty $path -ErrorAction SilentlyContinue |
                 Where-Object { $_.DisplayName -match $DisplayNamePattern } |
                 Select-Object -First 1
        if ($entry) { return $entry }
    }
    return $null
}

function Invoke-UninstallEntry {
    param(
        [string]$DisplayNamePattern,
        [string]$ExtraArgs = ""
    )
    $entry = Get-UninstallEntry $DisplayNamePattern
    if (-not $entry) { throw "未在注册表中找到已安装的程序（匹配: $DisplayNamePattern）" }
    Write-Info "找到: $($entry.DisplayName)"
    $uninstStr = $entry.UninstallString
    if ($uninstStr -match '^"?(.+?\.exe)"?\s*(.*)$') {
        $exe      = $Matches[1]
        $baseArgs = $Matches[2].Trim()
        $allArgs  = (@($baseArgs, $ExtraArgs) | Where-Object { $_ -ne "" }) -join " "
        $p = Start-Process -FilePath $exe -ArgumentList $allArgs -Wait -PassThru
        if ($p.ExitCode -ne 0) { throw "卸载程序退出码: $($p.ExitCode)" }
    } else {
        throw "无法解析卸载命令: $uninstStr"
    }
}

function Remove-InputTips {
    $dest = "$env:LOCALAPPDATA\InputTip"
    $lnk  = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\InputTip.lnk"
    Get-Process -Name "InputTip" -ErrorAction SilentlyContinue | Stop-Process -Force
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    if (Test-Path $lnk)  { Remove-Item -Force $lnk }
    Write-Info "已删除 $dest 及快捷方式"
}

# ── 安装检测 ──────────────────────────────────────────────────────────────────

function Test-IsInstalled {
    param([string]$Tool)
    switch ($Tool) {
        "InputTips"  { return Test-Path "$env:LOCALAPPDATA\InputTip\InputTip.exe" }
        "EcoPaste"   { return $null -ne (Get-UninstallEntry "EcoPaste") }
        "Pot"        { return $null -ne (Get-UninstallEntry "pot") }
        "Everything" { return $null -ne (Get-UninstallEntry "Everything") }
        "PixPin"     { return $null -ne (Get-UninstallEntry "PixPin") }
    }
    return $false
}

# ── 安装执行 ──────────────────────────────────────────────────────────────────

function Invoke-Install {
    param([string[]]$Tools)

    if (-not $DownloadDir) {
        $script:DownloadDir = "$env:TEMP\ToolInstaller"
    }
    New-Item -ItemType Directory -Force -Path $script:DownloadDir | Out-Null
    Write-Host "  临时目录: $script:DownloadDir" -ForegroundColor DarkGray

    $results = @{}
    foreach ($tool in $Tools) {
        Write-Step "[$tool] 安装"
        if (Test-IsInstalled $tool) {
            Write-Host "    [跳过] $tool 已安装" -ForegroundColor Yellow
            $results[$tool] = "已安装（跳过）"
            continue
        }
        try {
            switch ($tool) {
                "EcoPaste" {
                    $url  = Get-GitHubLatestAsset "EcoPasteHub/EcoPaste" "x64-setup\.exe$"
                    $file = "$script:DownloadDir\EcoPaste-setup.exe"
                    Save-File $url $file; Invoke-NsisInstaller $file
                }
                "Pot" {
                    $url  = Get-GitHubLatestAsset "pot-app/pot-desktop" "_x64-setup\.exe$"
                    $file = "$script:DownloadDir\pot-setup.exe"
                    Save-File $url $file; Invoke-NsisInstaller $file
                }
                "InputTips" {
                    $url  = Get-GitHubLatestAsset "abgox/InputTip" "^InputTip\.exe$"
                    $dest = "$env:LOCALAPPDATA\InputTip\InputTip.exe"
                    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
                    Save-File $url $dest
                    $shell = New-Object -ComObject WScript.Shell
                    $lnk   = $shell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\InputTip.lnk")
                    $lnk.TargetPath = $dest; $lnk.Save()
                    Write-Info "已安装到 $dest"
                }
                "Everything" {
                    $url  = Get-EverythingDownloadUrl
                    $file = "$script:DownloadDir\Everything-setup.exe"
                    Save-File $url $file; Invoke-NsisInstaller $file
                }
                "PixPin" {
                    $url  = Get-PixPinDownloadUrl
                    $file = "$script:DownloadDir\PixPin-setup.exe"
                    Save-File $url $file; Invoke-NsisInstaller $file
                }
            }
            Write-Ok "$tool 安装成功"
            $results[$tool] = "成功"
        } catch {
            Write-Err "$tool 安装失败: $_"
            $results[$tool] = "失败: $_"
        }
    }

    if (-not $KeepInstallers) {
        Remove-Item -Recurse -Force $script:DownloadDir -ErrorAction SilentlyContinue
    }
    return $results
}

# ── 卸载执行 ──────────────────────────────────────────────────────────────────

function Invoke-Uninstall {
    param([string[]]$Tools)
    $results = @{}
    foreach ($tool in $Tools) {
        Write-Step "[$tool] 卸载"
        if (-not (Test-IsInstalled $tool)) {
            Write-Host "    [跳过] $tool 未检测到安装" -ForegroundColor Yellow
            $results[$tool] = "未安装（跳过）"
            continue
        }
        try {
            switch ($tool) {
                "EcoPaste"   { Invoke-UninstallEntry "EcoPaste"   $UninstallArgs["EcoPaste"] }
                "Pot"        { Invoke-UninstallEntry "pot"        $UninstallArgs["Pot"] }
                "Everything" { Invoke-UninstallEntry "Everything" $UninstallArgs["Everything"] }
                "PixPin"     { Invoke-UninstallEntry "PixPin"     $UninstallArgs["PixPin"] }
                "InputTips"  { Remove-InputTips }
            }
            Write-Ok "$tool 卸载成功"
            $results[$tool] = "成功"
        } catch {
            Write-Err "$tool 卸载失败: $_"
            $results[$tool] = "失败: $_"
        }
    }
    return $results
}

# ── 主菜单循环 ────────────────────────────────────────────────────────────────

while ($true) {
    Show-MainMenu
    $choice = Read-Host "请选择操作"
    switch ($choice.Trim()) {
        "1" {
            $tools = Read-ToolSelection "安装"
            if ($tools) {
                $results = Invoke-Install $tools
                Write-Host "`n========== 安装结果 ==========" -ForegroundColor Cyan
                foreach ($kv in $results.GetEnumerator()) {
                    $color = if ($kv.Value -eq "成功") { "Green" } elseif ($kv.Value -like "已安装*") { "Yellow" } else { "Red" }
                    Write-Host ("  {0,-12} {1}" -f $kv.Key, $kv.Value) -ForegroundColor $color
                }
                Write-Host "==============================`n" -ForegroundColor Cyan
            }
        }
        "2" {
            $tools = Read-ToolSelection "卸载"
            if ($tools) {
                $results = Invoke-Uninstall $tools
                Write-Host "`n========== 卸载结果 ==========" -ForegroundColor Cyan
                foreach ($kv in $results.GetEnumerator()) {
                    $color = if ($kv.Value -eq "成功") { "Green" } elseif ($kv.Value -like "未安装*") { "Yellow" } else { "Red" }
                    Write-Host ("  {0,-12} {1}" -f $kv.Key, $kv.Value) -ForegroundColor $color
                }
                Write-Host "==============================`n" -ForegroundColor Cyan
            }
        }
        "0" { Write-Host "再见！" -ForegroundColor Cyan; exit 0 }
        default { Write-Host "  无效选项，请重新输入" -ForegroundColor Yellow }
    }
}
