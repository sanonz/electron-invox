@echo off
setlocal enabledelayedexpansion

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

:: 获取项目根目录
set ROOT_DIR=%~dp0
cd /d "%ROOT_DIR%"

:: 读取 package.json 中的 version
for /f "tokens=2 delims=:, " %%a in ('findstr /r "\"version\"" package.json') do (
    set VERSION=%%a
)
:: 移除引号
set VERSION=%VERSION:"=%

echo Building Invox Installer...
echo Version: %VERSION%
echo.

:: 1. 检查并构建 Uninstaller.exe
if not exist "dist\Uninstaller.exe" (
    echo          Building Uninstaller.exe...
    if not exist "invox\Uninstaller\Res\resources.zip" (
        echo [Step 0] Creating resources.zip...
        cd /d "%ROOT_DIR%invox\Uninstaller\Res"
        7z a resources.zip images\* resources\* uninstaller.xml
        if errorlevel 1 (
            echo Error: Failed to create resources.zip
            exit /b 1
        )
        cd /d "%ROOT_DIR%"
    )
    cd /d "%ROOT_DIR%invox"
    msbuild InvoxSetup.sln /t:Uninstaller /p:Configuration=Release /p:Platform=x64 /v:minimal /nologo
    if errorlevel 1 (
        echo Error: Failed to build Uninstaller.exe
        exit /b 1
    )
    cd /d "%ROOT_DIR%"
    copy /y "invox\bin\Uninstaller.exe" "dist\Uninstaller.exe"
) else (
    echo [Step 1] Uninstaller.exe already exists, skipping build
)

:: 2. 复制 Uninstaller.exe 到 dist/win-unpacked
echo [Step 2] Copying Uninstaller.exe to dist/win-unpacked...
if not exist "dist\win-unpacked" mkdir "dist\win-unpacked"
copy /y "dist\Uninstaller.exe" "dist\win-unpacked\Uninstaller.exe"
if errorlevel 1 (
    echo Error: Failed to copy Uninstaller.exe
    exit /b 1
)

:: 3. 打包 dist/win-unpacked 为 app.7z
echo [Step 3] Creating app.7z from dist/win-unpacked...
cd /d "%ROOT_DIR%dist"
if exist "app.7z" del /f /q "app.7z"
7z a app.7z ".\win-unpacked\*" -t7z -m0=lzma2 -mx=7 -md=32m -mmt=on -ms=on
if errorlevel 1 (
    echo Error: Failed to create app.7z
    exit /b 1
)
cd /d "%ROOT_DIR%"

:: 4. 把 app.7z 文件放到 invox/bin/app.7z
echo [Step 4] Moving app.7z to invox/bin...
if not exist "invox\bin" mkdir "invox\bin"
move /y "dist\app.7z" "invox\bin\app.7z"
if errorlevel 1 (
    echo Error: Failed to move app.7z
    exit /b 1
)

:: 5. 构建 Installer.exe
echo [Step 5] Building Installer.exe...
if not exist "invox\Installer\Res\resources.zip" (
    echo          Creating resources.zip...
    cd /d "%ROOT_DIR%invox\Installer\Res"
    7z a resources.zip images\* resources\* installer.xml
    if errorlevel 1 (
        echo Error: Failed to create resources.zip
        exit /b 1
    )
    cd /d "%ROOT_DIR%"
)
cd /d "%ROOT_DIR%invox"
msbuild InvoxSetup.sln /t:Installer /p:Configuration=Release /p:Platform=x64 /v:minimal /nologo
if errorlevel 1 (
    echo Error: Failed to build Installer.exe
    exit /b 1
)
cd /d "%ROOT_DIR%"

:: 6. 复制 Installer.exe 到 dist 目录并重命名
echo [Step 6] Copying Installer.exe to dist/Installer-%VERSION%.exe...
if not exist "dist" mkdir "dist"
copy /y "invox\bin\Installer.exe" "dist\InvoxSetup-%VERSION%.exe"
if errorlevel 1 (
    echo Error: Failed to copy Installer.exe
    exit /b 1
)

echo.
echo ==========================================
echo Build completed successfully!
echo Output: dist\Installer-%VERSION%.exe
echo ==========================================

endlocal
