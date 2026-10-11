# 111

## C 盘文件转移到 D 盘

把 `C:\Users\Administrator` 下 桌面/文档/下载/图片/视频/音乐 里的普通文件移动到 `D:\C盘转移`，保持原来的文件夹结构。

不会移动：
- `C:\Users\Administrator\Desktop\总`（整个文件夹）
- 快捷方式、程序（.lnk .url .exe .dll .msi .bat 等）、系统文件
- AppData 等程序数据

使用：把 `move_c_to_d.ps1` 和 `一键转移.bat` 放到同一个文件夹，双击 `一键转移.bat`，先看预览，输入 Y 确认后才会真正移动。每次移动都会在 `D:\C盘转移` 里生成一份转移记录。
