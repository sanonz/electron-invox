@echo off
setlocal enabledelayedexpansion

:: 获取项目根目录
set ROOT_DIR=%~dp0
cd /d "%ROOT_DIR%"

:: 提取 electron-builder.yml 中的 appId 并生成 UUID
echo Extracting appId from electron-builder.yml...
for /f "tokens=2 delims=: " %%a in ('findstr /r "^appId:" electron-builder.yml') do (
    set APP_ID=%%a
)
:: 移除可能的空格
set APP_ID=%APP_ID: =%

echo Found appId: %APP_ID%

:: 运行 Node.js 脚本生成 UUID
echo Generating UUID for registry keys...
:: 对应的 ELECTRON_BUILDER_NS_UUID 为: https://github.com/electron-userland/electron-builder/blob/144c5ed2f9bdc9a811828a7be8f06658e1c28702/packages/app-builder-lib/src/targets/nsis/NsisTarget.ts#L45C46-L45C82
for /f "delims=" %%a in ('node -e "const { UUID } = require('builder-util-runtime'); console.log(UUID.v5('%APP_ID%', UUID.parse('50e065bc-3134-11e6-9bab-38c9862bdaf3')));"') do (
    set REGISTRY_UUID=%%a
)

echo Generated UUID: %REGISTRY_UUID%

:: 读取 package.json 中的 version
for /f "tokens=2 delims=:, " %%a in ('findstr /r "\"version\"" package.json') do (
    set VERSION=%%a
)
:: 移除引号
set VERSION=%VERSION:"=%

:: 解析版本号 (例如: 1.0.0 -> MAJOR=1, MINOR=0, BUILD=0)
for /f "tokens=1,2,3 delims=." %%a in ("%VERSION%") do (
    set VERSION_MAJOR=%%a
    set VERSION_MINOR=%%b
    set VERSION_BUILD=%%c
)

echo Building Invox Installer...
echo Version: %VERSION% (MAJOR=%VERSION_MAJOR%, MINOR=%VERSION_MINOR%, BUILD=%VERSION_BUILD%)
echo.

:: 备份并更新 Config.h 中的版本号
set CONFIG_FILE=invox\Common\Config.h
set CONFIG_BACKUP=%CONFIG_FILE%.backup

if exist "%CONFIG_FILE%" (
    echo Backing up Config.h...
    copy /y "%CONFIG_FILE%" "%CONFIG_BACKUP%" >nul
    if errorlevel 1 (
        echo Error: Failed to backup Config.h
        call :restore_config
        exit /b 1
    )
    echo Config.h backed up to %CONFIG_BACKUP%
    
    echo Updating Config.h with version %VERSION%...
    powershell -Command "$content = Get-Content '%CONFIG_FILE%' -Raw -Encoding UTF8; $content = $content -replace '#define APP_VERSION_MAJOR\s+\d+', '#define APP_VERSION_MAJOR   %VERSION_MAJOR%'; $content = $content -replace '#define APP_VERSION_MINOR\s+\d+', '#define APP_VERSION_MINOR   %VERSION_MINOR%'; $content = $content -replace '#define APP_VERSION_BUILD\s+\d+', '#define APP_VERSION_BUILD   %VERSION_BUILD%'; $content = $content -replace '#define APP_REGISTRY_KEYS\s+L\".+?\"', '#define APP_REGISTRY_KEYS  L\"%REGISTRY_UUID%\"'; [System.IO.File]::WriteAllText('%CD%\%CONFIG_FILE%', $content, [System.Text.UTF8Encoding]::new($true))"
    echo Config.h updated successfully.
) else (
    echo Warning: Config.h not found at %CONFIG_FILE%
)
echo.

:: 1. 检查并构建 Uninstaller.exe
echo [Step 1] Building Uninstaller.exe...
cd /d "%ROOT_DIR%invox\Uninstaller\Res"
if exist "resources.zip" del /f /q "resources.zip"
7z a resources.zip images\* resources\* *.xml
if errorlevel 1 (
    echo Error: Failed to create resources.zip
    call :restore_config
    exit /b 1
)
cd /d "%ROOT_DIR%invox"
msbuild InvoxSetup.sln /t:Uninstaller /p:Configuration=Release /p:Platform=x64 /v:minimal /nologo
if errorlevel 1 (
    echo Error: Failed to build Uninstaller.exe
    call :restore_config
    exit /b 1
)
cd /d "%ROOT_DIR%"

:: 2. 复制 Uninstaller.exe 到 dist/win-unpacked
echo [Step 2] Copying Uninstaller.exe to dist/win-unpacked...
if not exist "dist\win-unpacked" mkdir "dist\win-unpacked"
copy /y "invox\bin\Uninstaller.exe" "dist\win-unpacked\Uninstaller.exe"
if errorlevel 1 (
    echo Error: Failed to copy Uninstaller.exe
    call :restore_config
    exit /b 1
)

:: 3. 打包 dist/win-unpacked 为 app.7z
echo [Step 3] Creating app.7z from dist/win-unpacked...
cd /d "%ROOT_DIR%dist"
if exist "app.7z" del /f /q "app.7z"
7z a app.7z ".\win-unpacked\*" -t7z -m0=lzma2 -mx=7 -md=32m -mmt=on -ms=on
if errorlevel 1 (
    echo Error: Failed to create app.7z
    call :restore_config
    exit /b 1
)
cd /d "%ROOT_DIR%"

:: 4. 把 app.7z 文件放到 invox/bin/app.7z
echo [Step 4] Moving app.7z to invox/bin...
if not exist "invox\bin" mkdir "invox\bin"
move /y "dist\app.7z" "invox\bin\app.7z"
if errorlevel 1 (
    echo Error: Failed to move app.7z
    call :restore_config
    exit /b 1
)

:: 5. 构建 Installer.exe
echo [Step 5] Building Installer.exe...
cd /d "%ROOT_DIR%invox\Installer\Res"
if exist "resources.zip" del /f /q "resources.zip"
7z a resources.zip images\* resources\* *.xml
if errorlevel 1 (
    echo Error: Failed to create resources.zip
    call :restore_config
    exit /b 1
)
cd /d "%ROOT_DIR%invox"
msbuild InvoxSetup.sln /t:Installer /p:Configuration=Release /p:Platform=x64 /v:minimal /nologo
if errorlevel 1 (
    echo Error: Failed to build Installer.exe
    call :restore_config
    exit /b 1
)
cd /d "%ROOT_DIR%"

:: 6. 复制 Installer.exe 到 dist 目录并重命名
echo [Step 6] Copying Installer.exe to dist/InvoxSetup-%VERSION%.exe...
if not exist "dist" mkdir "dist"
copy /y "invox\bin\Installer.exe" "dist\InvoxSetup-%VERSION%.exe"
if errorlevel 1 (
    echo Error: Failed to copy Installer.exe
    call :restore_config
    exit /b 1
)

echo.
echo ==========================================
echo Build completed successfully!
echo Output: dist\InvoxSetup-%VERSION%.exe
echo ==========================================

:: 还原 Config.h
call :restore_config

endlocal

goto :eof

:: 还原 Config.h 函数
:restore_config
if exist "%CONFIG_BACKUP%" (
    echo Restoring Config.h from backup...
    copy /y "%CONFIG_BACKUP%" "%CONFIG_FILE%" >nul
    if errorlevel 1 (
        echo Warning: Failed to restore Config.h from backup
    ) else (
        echo Config.h restored successfully
    )
    del /f /q "%CONFIG_BACKUP%" >nul
    echo Backup file removed
) else (
    echo No Config.h backup found to restore
)
exit /b 0
