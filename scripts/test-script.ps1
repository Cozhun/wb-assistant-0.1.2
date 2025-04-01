Write-Host "Тестовый скрипт работает!"
$files = Get-ChildItem -Path ".."
foreach ($file in $files) {
    Write-Host $file.Name
}
Write-Host "Тестовый скрипт завершен!" 