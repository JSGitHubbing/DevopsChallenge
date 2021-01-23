$BaseFolder = Get-Location
$VolumesFolder = "$BaseFolder/docker_volumes"
$ProjectRepoFolder = "$BaseFolder/docker_volumes/jenkins_git_repo"
$ConfigResourcesFolder = "$BaseFolder/config_resources"
$InstallationFolder = "$BaseFolder/devops-repository"
$ConfigurationFile = "$ConfigResourcesFolder/installation.config"

function Print-Block {
    Write-Host ""
	Write-Host "********************************************************" -ForegroundColor Yellow
	Write-Host "********************************************************" -ForegroundColor Yellow
	Write-Host ""
}

function Refresh-Environment-Variables {
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
}

function Install-VSCode-Extensions {
	Refresh-Environment-Variables
	Write-Host "Installing Visual Studio Code *Extensions*" -ForegroundColor Magenta
	code --install-extension ms-vscode-remote.vscode-remote-extensionpack
	code --install-extension ms-vscode-remote.remote-containers
}

function Check-Installation-Folder {
	if (-Not (Test-Path docker-compose.yml -PathType leaf))
	{
		Write-Host "Creating and pulling config repository" -ForegroundColor Magenta
		mkdir $InstallationFolder
		cd $InstallationFolder
		git init
		git pull https://github.com/JSGitHubbing/DevopsChallenge
		Print-Block
	}
}




Write-Host "Installing Chocolatey" -ForegroundColor Magenta
$TestChoco = powershell choco -v
if(-not($TestChoco)) {
	Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
	Write-Host "Chocolatey installation finished" -ForegroundColor Magenta
}
else {
	Write-Host "Chocolatey is already installed" -ForegroundColor Green
}
Remove-Variable TestChoco
Print-Block

Write-Host "Installing Docker" -ForegroundColor Magenta
$TestDocker = powershell docker -v
$TestDockerCompose = powershell docker-compose -v
if(-not($TestDocker) -or (-not($TestDockerCompose))) {
	choco install docker-desktop -y
	Write-Host "Docker installation finished" -ForegroundColor Magenta
}
else {
	Write-Host "Docker-desktop is already installed" -ForegroundColor Green
}
Remove-Variable TestDocker
Remove-Variable TestDockerCompose
Print-Block

Write-Host "Installing Visual Studio Code" -ForegroundColor Magenta
$TestVSCode = powershell code -v
if(-not($TestVSCode)) {
	choco install vscode -y
}
else {
	Write-Host "VSCode is already installed" -ForegroundColor Green
}
Install-VSCode-Extensions
Write-Host "Visual Studio Code installation finished" -ForegroundColor Magenta
Remove-Variable TestVSCode
Print-Block

Write-Host "Installing Git" -ForegroundColor Magenta
$TestGit = powershell git --version
if(-not($TestGit)) {
	choco install git -y
	Refresh-Environment-Variables
	Write-Host "Git installation finished" -ForegroundColor Magenta
}
else {
	Write-Host "Git is already installed" -ForegroundColor Green
}
Remove-Variable TestGit
Print-Block

Check-Installation-Folder
Get-Content $ConfigurationFile | Foreach-Object{
	$var = $_.Split('=')
	New-Variable -Name $var[0] -Value $var[1]
}

Write-Host "Installing WSL" -ForegroundColor Magenta
$TestWsl = powershell wsl -l
if(-not($TestWsl)) {
	Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -OutFile "wsl_update_x64.msi"
	cd $BaseFolder

	.\wsl_update_x64.msi /quiet
	rm "$BaseFolder\wsl_update_x64.msi"
}
else {
	Write-Host "WSL is already installed" -ForegroundColor Green
}
Remove-Variable TestWsl
Print-Block

Write-Host "Launching Docker-Desktop" -ForegroundColor Magenta
$IsDockerRunning = powershell Get-Process 'com.docker-proxy'
Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if(-not($IsDockerRunning)) {
	$DockerStartTries = 0
	DO {
		$IsDockerRunning = powershell Get-Process 'com.docker-proxy'
		Start-Sleep -Seconds $DockerTriesSeconds
		$DockerStartTries++
	} While (-not($IsDockerRunning) -and($DockerStartTries -le $DockerStartTriesMax))

	if($DockerStartTries -gt $DockerStartTriesMax) {
		Write-Host "ERROR: Could not start Docker before the timeout $DockerStartTriesMax tries each $DockerTriesSeconds seconds waiting." -ForegroundColor Red
		Write-Host "Check $ConfigurationFile to have more information" -ForegroundColor Yellow
		exit 1
	}
}
Print-Block

## Prepare images
Write-Host "Preparing Docker images" -ForegroundColor Magenta
# Copy-Item -Path "$BaseFolder/images_dockerfiles/Dockerfile_vscode" -Destination "$BaseFolder/my_visual_studio_code_project/.devcontainer/Dockerfile"
docker build -t devops_jenkins -f "$BaseFolder/images_dockerfiles/Dockerfile.jenkins" .
Print-Block

## Prepare user project
Write-Host "Preparing User project repository" -ForegroundColor Magenta
Write-Host "Creating docker_volumes/jenkins_git_repo folder"
## Creating folders for the repository
if (-Not (Test-Path $VolumesFolder))
{
	mkdir $VolumesFolder

}
if (-Not (Test-Path $ProjectRepoFolder))
{	
	mkdir $ProjectRepoFolder
}
cd $ProjectRepoFolder

## Clone repository and add Post-Commit Hook
Write-Host "Starting git"
git init
Write-Host "Pulling repository"
git clone "$ProjectRepositoryPath"
Copy-Item -Path "$ConfigResourcesFolder/post-commit" -Destination "$ProjectRepoFolder/.git/hooks"
Print-Block

## Launching containers
Write-Host "Launching Docker-Compose" -ForegroundColor Magenta
docker-compose up -d
cd $BaseFolder


Remove-Variable BaseFolder
Remove-Variable VolumesFolder
Remove-Variable ProjectRepoFolder
Remove-Variable ConfigResourcesFolder