<#
  把 C 盘用户目录里的普通文件（文档、图片、视频、压缩包等）转移到 D 盘。
  - 不动：C:\Users\Administrator\Desktop\总（整个文件夹保留在原处）
  - 不动：快捷方式(.lnk/.url)、程序文件(.exe/.dll/.msi 等)、系统文件(desktop.ini)
  - 不动：AppData 等程序数据目录

  用法（在 PowerShell 里）：
    预览（只列出会移动什么，不真正移动）：
      powershell -ExecutionPolicy Bypass -File .\move_c_to_d.ps1
    真正执行：
      powershell -ExecutionPolicy Bypass -File .\move_c_to_d.ps1 -Execute
#>
param(
    [switch]$Execute,
    [string]$UserHome = 'C:\Users\Administrator',
    [string]$TargetRoot = 'D:\C盘转移'
)

# 要整理的文件夹（相对于用户目录）
$SourceFolders = @('Desktop', 'Documents', 'Downloads', 'Pictures', 'Videos', 'Music')

# 排除的路径（及其下所有内容）
$ExcludePaths = @(
    (Join-Path $UserHome 'Desktop\总')
)

# 排除的文件类型：快捷方式、程序、系统文件
$ExcludeExtensions = @('.lnk', '.url', '.exe', '.dll', '.msi', '.sys', '.bat', '.cmd', '.ps1', '.ini')

if (-not (Test-Path 'D:\')) {
    Write-Host '找不到 D 盘，已退出。' -ForegroundColor Red
    exit 1
}

$logFile = Join-Path $TargetRoot ("转移记录_{0:yyyyMMdd_HHmmss}.txt" -f (Get-Date))
if ($Execute) { New-Item -ItemType Directory -Force -Path $TargetRoot | Out-Null }

function Test-Excluded([string]$path) {
    foreach ($ex in $ExcludePaths) {
        if ($path -eq $ex -or $path.StartsWith($ex + '\', [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

# 目标已存在同名文件时，自动改名为 "名字 (1).ext"
function Get-FreePath([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return $path }
    $dir  = Split-Path $path -Parent
    $name = [IO.Path]::GetFileNameWithoutExtension($path)
    $ext  = [IO.Path]::GetExtension($path)
    $i = 1
    do { $candidate = Join-Path $dir ("{0} ({1}){2}" -f $name, $i, $ext); $i++ } while (Test-Path -LiteralPath $candidate)
    return $candidate
}

$count = 0; $bytes = 0; $failed = 0

foreach ($folder in $SourceFolders) {
    $src = Join-Path $UserHome $folder
    if (-not (Test-Path -LiteralPath $src)) { continue }

    Get-ChildItem -LiteralPath $src -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $file = $_
        if (Test-Excluded $file.FullName) { return }
        if ($ExcludeExtensions -contains $file.Extension.ToLower()) { return }
        if ($file.Attributes -band [IO.FileAttributes]::System) { return }

        $relative = $file.FullName.Substring($UserHome.Length).TrimStart('\')
        $dest = Join-Path $TargetRoot $relative

        if ($Execute) {
            try {
                New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
                $dest = Get-FreePath $dest
                Move-Item -LiteralPath $file.FullName -Destination $dest -ErrorAction Stop
                Add-Content -LiteralPath $logFile -Value "$($file.FullName) -> $dest" -Encoding UTF8
                $script:count++; $script:bytes += $file.Length
            } catch {
                Write-Host "失败: $($file.FullName)  原因: $($_.Exception.Message)" -ForegroundColor Yellow
                $script:failed++
            }
        } else {
            Write-Host "$($file.FullName)  ->  $dest"
            $script:count++; $script:bytes += $file.Length
        }
    }
}

# 执行后清理被搬空的文件夹（不碰排除目录）
if ($Execute) {
    foreach ($folder in $SourceFolders) {
        $src = Join-Path $UserHome $folder
        if (-not (Test-Path -LiteralPath $src)) { continue }
        Get-ChildItem -LiteralPath $src -Recurse -Directory -Force -ErrorAction SilentlyContinue |
            Sort-Object { $_.FullName.Length } -Descending |
            Where-Object { -not (Test-Excluded $_.FullName) } |
            Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue) } |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
    }
}

$sizeGB = [math]::Round($bytes / 1GB, 2)
if ($Execute) {
    Write-Host "`n完成：移动了 $count 个文件，共 $sizeGB GB，失败 $failed 个。" -ForegroundColor Green
    Write-Host "文件在：$TargetRoot"
    Write-Host "记录在：$logFile"
} else {
    Write-Host "`n预览：将会移动 $count 个文件，共 $sizeGB GB。" -ForegroundColor Cyan
    Write-Host '确认无误后加上 -Execute 参数再运行一次即可真正移动。'
}
