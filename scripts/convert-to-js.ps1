Write-Host "Starting the transition process from TypeScript to JavaScript..." -ForegroundColor Green

# Переходим в корневую директорию проекта
Set-Location $PSScriptRoot/..
$rootDir = Get-Location

# Функция для конвертирования TS в JS для указанного каталога
function ConvertTStoJS {
    param (
        [string]$sourceDir,
        [string]$backupDir,
        [string]$tempDir,
        [string]$fileExtension
    )

    Write-Host "Converting TypeScript files in: $sourceDir" -ForegroundColor Magenta

    # Создаем резервную копию
    Write-Host "Creating backup of TypeScript files..." -ForegroundColor Cyan
    if (!(Test-Path -Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }
    Copy-Item -Path $sourceDir -Destination $backupDir -Recurse -Force

    # Создаем директорию для JavaScript файлов
    if (Test-Path -Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    # Создаем структуру директорий
    Get-ChildItem -Path $sourceDir -Directory -Recurse | ForEach-Object {
        $relPath = $_.FullName.Substring((Get-Item $sourceDir).FullName.Length)
        New-Item -ItemType Directory -Path "$tempDir$relPath" -Force | Out-Null
    }

    # Конвертируем TypeScript файлы в JavaScript
    $tsFiles = Get-ChildItem -Path $sourceDir -Recurse -Filter $fileExtension
    Write-Host "Found $($tsFiles.Count) TypeScript files" -ForegroundColor Yellow

    foreach ($tsFile in $tsFiles) {
        $relPath = $tsFile.FullName.Substring((Get-Item $sourceDir).FullName.Length)
        $jsPath = "$tempDir$($relPath.Replace('.ts', '.js').Replace('.tsx', '.jsx'))"
        
        Write-Host "Converting $relPath" -ForegroundColor Cyan
        
        # Создаем пустой JavaScript файл
        New-Item -ItemType File -Path $jsPath -Force | Out-Null
        
        $lines = Get-Content -Path $tsFile.FullName
        $jsContent = @()
        
        foreach ($line in $lines) {
            # Пропускаем импорты типов
            if ($line -match '@types') {
                continue
            }
            
            # Пропускаем объявления интерфейсов и типов
            if ($line -match '^(export\s+)?(interface|type)') {
                continue
            }
            
            # Удаляем аннотации типов
            $line = $line -replace ':\s*[A-Za-z0-9_\[\]<>,\s|]+(\s*=|,|\)|{|$)', '$1'
            
            # Удаляем дженерики
            $line = $line -replace '<[^>]+>', ''
            
            $jsContent += $line
        }
        
        Set-Content -Path $jsPath -Value $jsContent
    }

    # Копируем остальные файлы
    Get-ChildItem -Path $sourceDir -Recurse -File | Where-Object { $_.Extension -ne ".ts" -and $_.Extension -ne ".tsx" } | ForEach-Object {
        $relPath = $_.FullName.Substring((Get-Item $sourceDir).FullName.Length)
        Copy-Item -Path $_.FullName -Destination "$tempDir$relPath" -Force
    }

    # Переименовываем директории
    Write-Host "Replacing TypeScript code with JavaScript..." -ForegroundColor Green
    $oldDirName = Split-Path -Leaf $sourceDir
    $oldPath = Split-Path -Parent $sourceDir
    $oldBackup = Join-Path $oldPath "${oldDirName}_old"
    
    if (Test-Path -Path $oldBackup) {
        Remove-Item -Path $oldBackup -Recurse -Force
    }
    Rename-Item -Path $sourceDir -NewName "${oldDirName}_old"
    Rename-Item -Path $tempDir -NewName $oldDirName

    Write-Host "Conversion for $sourceDir completed!" -ForegroundColor Green
}

# Конвертируем клиентский код
ConvertTStoJS -sourceDir "$rootDir\client\src" -backupDir "$rootDir\client\ts-backup" -tempDir "$rootDir\client\src_js" -fileExtension "*.ts*"

# Обновляем package.json клиента
$packageJsonPath = "$rootDir\client\package.json"
$packageJson = Get-Content -Path $packageJsonPath -Raw | ConvertFrom-Json

# Обновляем скрипты сборки
$packageJson.scripts.build = "vite build"
$packageJson.scripts.lint = "eslint . --ext js,jsx --fix"

# Удаляем TypeScript зависимости
$typescriptDevDependencies = @("@types/react", "@types/react-dom", "@typescript-eslint/eslint-plugin", "@typescript-eslint/parser", "typescript")
foreach ($dep in $typescriptDevDependencies) {
    if ($packageJson.devDependencies.PSObject.Properties.Name -contains $dep) {
        $packageJson.devDependencies.PSObject.Properties.Remove($dep)
    }
}

# Сохраняем обновленный package.json
$packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath

# Обновляем Dockerfile клиента
$dockerfilePath = "$rootDir\client\Dockerfile"
$dockerfile = Get-Content -Path $dockerfilePath
$updatedDockerfile = $dockerfile | ForEach-Object {
    if ($_ -match "TypeScript") {
        if ($_ -match "RUN npm install -g typescript") {
            return ""
        }
    } else {
        return $_
    }
}
Set-Content -Path $dockerfilePath -Value $updatedDockerfile

# Удаляем конфигурационные файлы TypeScript
Remove-Item -Path "$rootDir\client\tsconfig.json" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$rootDir\client\tsconfig.node.json" -Force -ErrorAction SilentlyContinue

# Обновляем gitignore, добавляя папки бэкапа
$gitignorePath = "$rootDir\.gitignore"
if (Test-Path -Path $gitignorePath) {
    Add-Content -Path $gitignorePath -Value "`n# TypeScript backups`nts-backup/`n*_old/`n"
}

Write-Host "All conversions completed!" -ForegroundColor Green
Write-Host "Original TypeScript files saved in backup folders" -ForegroundColor Green 