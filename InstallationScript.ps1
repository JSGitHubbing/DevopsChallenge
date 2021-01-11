Write-Host "Installing Chocolatey" -ForegroundColor Magenta
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
Write-Host "Chocolatey installation finished" -ForegroundColor Magenta

Write-Host "Installing Docker" -ForegroundColor Magenta
choco install docker-cli -y
choco install docker-compose -y
Write-Host "Docker installation finished" -ForegroundColor Magenta

Write-Host "Installing Visual Studio Code" -ForegroundColor Magenta
choco install vscode -y
Write-Host "Visual Studio Code installation finished" -ForegroundColor Magenta

Write-Host "Installing Git 2.30.0" -ForegroundColor Magenta
choco install git -y
Write-Host "Git installation finished" -ForegroundColor Magenta

