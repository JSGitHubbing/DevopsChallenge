function Print-Block {
    Write-Host ""
	Write-Host "********************************************************" -ForegroundColor Yellow
	Write-Host "********************************************************" -ForegroundColor Yellow
	Write-Host ""
}

function Refresh-Environment-Variables {
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

}

$baseFolder = Get-Location
$dockerVolumesFolder = "$baseFolder/docker_volumes"
$projectRepo = "$baseFolder/docker_volumes/jenkins_git_repo"
$configResourcesFolder = "$baseFolder/config_resources"

Write-Host "Installing Chocolatey" -ForegroundColor Magenta
$testchoco = powershell choco -v
if(-not($testchoco)) {
	Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
	Write-Host "Chocolatey installation finished" -ForegroundColor Magenta
}
else {
	Write-Host "Chocolatey is already installed" -ForegroundColor Green
}
Remove-Variable testchoco
Print-Block

Write-Host "Installing Docker" -ForegroundColor Magenta
$testdocker = powershell docker -v
$testdockercompose = powershell docker-compose -v
if(-not($testdocker) -or (-not($testdockercompose))) {
	choco install docker-desktop -y
	Write-Host "Docker installation finished" -ForegroundColor Magenta
}
else {
	Write-Host "Docker-desktop is already installed" -ForegroundColor Green
}

Remove-Variable testdocker
Remove-Variable testdockercompose
Print-Block

Write-Host "Installing Visual Studio Code" -ForegroundColor Magenta
$testcode = powershell code -v
if(-not($testcode)) {
	choco install vscode -y
	Refresh-Environment-Variables
	Write-Host "Installing Visual Studio Code *Extensions*" -ForegroundColor Magenta
	code --install-extension ms-vscode-remote.vscode-remote-extensionpack
	code --install-extension ms-vscode-remote.remote-containers
	Write-Host "Visual Studio Code installation finished" -ForegroundColor Magenta
}
else {
	Write-Host "VSCode is already installed" -ForegroundColor Green
	Refresh-Environment-Variables
	Write-Host "Installing Visual Studio Code *Extensions*" -ForegroundColor Magenta
	code --install-extension ms-vscode-remote.vscode-remote-extensionpack
	code --install-extension ms-vscode-remote.remote-containers
}
Remove-Variable testcode
Print-Block

Write-Host "Installing Git" -ForegroundColor Magenta
$testgit = powershell git --version
if(-not($testgit)) {
	choco install git -y
	Refresh-Environment-Variables
	Write-Host "Git installation finished" -ForegroundColor Magenta
}
else {
	Write-Host "Git is already installed" -ForegroundColor Green
}
Remove-Variable testgit
Print-Block

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
$testwsl = powershell wsl -l
if(-not($testwsl)) {
	Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -OutFile "wsl_update_x64.msi"
	cd $baseFolder
	.\wsl_update_x64.msi /quiet
	rm "$baseFolder\wsl_update_x64.msi"
}
else {
	Write-Host "WSL is already installed" -ForegroundColor Green
}
Remove-Variable testwsl
Print-Block

Write-Host "Launching Docker-Desktop" -ForegroundColor Magenta
Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe"
Start-Sleep -Seconds 100
Print-Block

##Prepare images

Write-Host "Preparing Docker images" -ForegroundColor Magenta
#Copy-Item -Path "$baseFolder/images_dockerfiles/Dockerfile_vscode" -Destination "$baseFolder/my_visual_studio_code_project/.devcontainer/Dockerfile"

docker build -t devops_jenkins -f "$baseFolder/images_dockerfiles/Dockerfile.jenkins" .
Print-Block

## Prepare user project
Write-Host "Preparing User project repository" -ForegroundColor Magenta
Write-Host "Creating docker_volumes/jenkins_git_repo folder"

if (-Not (Test-Path $dockerVolumesFolder))
{
	mkdir $dockerVolumesFolder
}
if (-Not (Test-Path $projectRepo))
{	
	mkdir $projectRepo
}

cd $projectRepo

Write-Host "Starting git"
git init
Write-Host "Pulling repository"
git clone https://github.com/JSGitHubbing/dummy-repo.git
Copy-Item -Path "$configResourcesFolder/post-commit" -Destination "$projectRepo/.git/hooks"
Print-Block

Write-Host "Launching Docker-Compose" -ForegroundColor Magenta
docker-compose up -d
cd $baseFolder


Remove-Variable baseFolder
Remove-Variable dockerVolumesFolder
Remove-Variable projectRepo
Remove-Variable configResourcesFolder