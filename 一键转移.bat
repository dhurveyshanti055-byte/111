@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ===== 第一步：预览将要移动的文件 =====
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0move_c_to_d.ps1"
echo.
set /p ok=确认要移动以上文件到 D 盘吗？输入 Y 回车确认：
if /i "%ok%"=="Y" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0move_c_to_d.ps1" -Execute
) else (
    echo 已取消，没有移动任何文件。
)
pause
