function Print-Block {
    Write-Host ""
	Write-Host "********************************************************" -ForegroundColor Yellow
	Write-Host "********************************************************" -ForegroundColor Yellow
	Write-Host ""
}

Write-Host "Installing Chocolatey" -ForegroundColor Magenta
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
Write-Host "Chocolatey installation finished" -ForegroundColor Magenta
Print-Block


Write-Host "Installing Docker" -ForegroundColor Magenta
choco install docker-desktop -y
# choco install docker-cli -y
# choco install docker-compose -y
Write-Host "Docker installation finished" -ForegroundColor Magenta
Print-Block

Write-Host "Installing Visual Studio Code" -ForegroundColor Magenta
choco install vscode -y
Write-Host "Visual Studio Code installation finished" -ForegroundColor Magenta
Print-Block

Write-Host "Installing Git 2.30.0" -ForegroundColor Magenta
choco install git -y
Write-Host "Git installation finished" -ForegroundColor Magenta
Print-Block

# Refresh PATH after installation
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

if (-Not (Test-Path docker-compose.yml -PathType leaf))
{
    Write-Host "Creating and pulling config repository" -ForegroundColor Magenta
	mkdir devops-repository
	cd devops-repository
	git init
	git pull https://github.com/JSGitHubbing/DevopsChallenge
	Print-Block
} 

Write-Host "Installing WSL" -ForegroundColor Magenta
Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -OutFile "wsl_update_x64.msi"
.\wsl_update_x64.msi /quiet
rm .\wsl_update_x64.msi
Print-Block

Write-Host "Launching Docker-Desktop" -ForegroundColor Magenta
Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe"
Start-Sleep -Seconds 100
Print-Block

Write-Host "Launching Docker-Compose" -ForegroundColor Magenta
docker-compose up -d