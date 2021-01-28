$global:BaseFolder = Get-Location
$global:ScriptName = "InstallationScript.ps1"
$global:Restarted = $args[0] -eq '-r'
$global:VolumesFolder = "$BaseFolder/docker_volumes"
$global:ProjectRepoFolder = "$BaseFolder/project_folder"
$global:ConfigResourcesFolder = "$BaseFolder/config_resources"
$global:InstallationFolder = "$BaseFolder/devops-repository"
$global:ConfigurationFile = "$ConfigResourcesFolder/installation.config"

function Refresh-Paths {
    param ($NewBaseFolder)
    Set-Variable -Name "BaseFolder" -Value $NewBaseFolder -Scope Global
    Set-Variable -Name "VolumesFolder" -Value "$BaseFolder/docker_volumes" -Scope Global
    Set-Variable -Name "ProjectRepoFolder" -Value "$BaseFolder/project_folder" -Scope Global
    Set-Variable -Name "ConfigResourcesFolder" -Value "$BaseFolder/config_resources" -Scope Global
    Set-Variable -Name "ConfigurationFile" -Value "$ConfigResourcesFolder/installation.config" -Scope Global
}

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
        Refresh-Paths $InstallationFolder 
		Set-Location $InstallationFolder
		git init
		git pull https://github.com/JSGitHubbing/DevopsChallenge
		Print-Block
	}

	Get-Content $ConfigurationFile | Foreach-Object{
		$var = $_.Split('=')
		try {
			$TestVariable = Get-Variable -Scope Global -Name $var[0] -ErrorAction Stop
			if(-not($TestVariable)) {
				New-Variable -Name $var[0] -Value $var[1] -Scope Global
			} else {
				Set-Variable -Name $var[0] -Value $var[1] -Scope Global
			}
		} catch {
				Set-Variable -Name $var[0] -Value $var[1] -Scope Global
		}
	}
}

function Restart-Machine {
	 ## Restart required to ensure the new installations work properly
	Refresh-Environment-Variables
	$Command = "powershell Set-Location $BaseFolder; $BaseFolder\$ScriptName -r"
	Set-Location HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce
	New-Itemproperty . RunItOnce_DockerInstallationScript -propertytype ExpandString -value $Command

	Write-Host "Restart is required. The script will continue after the restarting..." -ForegroundColor Magenta
	
	Write-Host "Do you want to restart now? [y/n]"
	$SelectedOption = Read-Host
	
	if($SelectedOption -eq 'y') {
		shutdown /r
		Write-Host "The script will continue after the restarting..." -ForegroundColor Magenta
	} else {
		Write-Host "The script will continue when you restart the computer" -ForegroundColor Magenta
	}
}

function Wait-DockerUp {
	param ($SecondsToWait, $MaxTries)

	$Tries = 1
	DO {
		
		Write-Host "`rChecking if docker is up ($Tries out $MaxTries attempts)" -ForegroundColor Yellow -NoNewLine 
		$IsDockerUp = powershell docker ps
		Start-Sleep -Seconds $SecondsToWait
		$Tries++
	} WHILE (-not($IsDockerUp) -and($Tries -le ($MaxTries+1)))

	if($Tries -gt $MaxTries+1) {
		Write-Host "ERROR: Docker was not running in the expected time" -ForegroundColor Red
		Write-Host "Try modifying the DockerTimeBetweenTries and DockerStartCheckMaxTries in the installation.config file"
		pause
		exit -1
	} else {
		Write-Host "`nDocker is up and running" -ForegroundColor Green
		Print-Block
	}
}

function Wait-JenkinsUp {
	param ($SecondsToWait, $MaxTries)

	$Combination = "$($JenkinsUser):$($JenkinsPassword)"
	$EncodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Combination))
	$BasicAuthValue = "Basic $EncodedCredentials"

	$Headers = @{
		Authorization = $BasicAuthValue
	}

	$Tries = 1
	$IsJenkinsUp = $false
	DO {
		Start-Sleep -Seconds $SecondsToWait
		Write-Host "`rChecking if Jenkins is up ($Tries out $MaxTries attempts)" -ForegroundColor Yellow -NoNewLine 
		try {
			$Response = Invoke-WebRequest -Uri $JenkinsUrl -Headers $Headers
			$StatusCode = $Response.StatusCode
            $IsJenkinsUp = $Response.StatusCode -eq "200"
		}
		catch {
			$StatusCode = $_.Exception.Response.StatusCode.value__
		}
		$Tries++
	} WHILE (-not($IsJenkinsUp) -and($Tries -le ($MaxTries+1)))

	if($Tries -gt $MaxTries+1) {
		Write-Host "ERROR: Jenkins was not running in the expected time" -ForegroundColor Red
		pause
		exit -1
	} else {
		Write-Host "`nJenkins is up and running" -ForegroundColor Green
		Print-Block
	}
}

if(-not($restarted)){
	Write-Host "Installing Chocolatey" -ForegroundColor Magenta
	Write-Host "TESTING Chocolatey installation" -ForegroundColor Magenta
	$TestChoco = powershell choco -v
	if(-not($TestChoco)) {
        Write-Host "NOT EXIST Chocolatey installation" -ForegroundColor Magenta
        Write-Host "Installing Chocolatey" -ForegroundColor Magenta
		Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
		Write-Host "Chocolatey installation finished" -ForegroundColor Magenta
	}
	else {
		Write-Host "Chocolatey is already installed" -ForegroundColor Green
	}
	Remove-Variable TestChoco
	Print-Block

	Write-Host "Installing WSL" -ForegroundColor Magenta
	$TestWsl = powershell wsl -l
	if(-not($TestWsl)) {
		
        Write-Host "NOT EXIST WSL installation" -ForegroundColor Magenta
        Write-Host "Installing WSL" -ForegroundColor Magenta
		Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -OutFile "wsl_update_x64.msi"
		Set-Location $BaseFolder

		.\wsl_update_x64.msi /quiet
		rm "$BaseFolder\wsl_update_x64.msi"
        Refresh-Environment-Variables
	    Write-Host "WSL installation finished" -ForegroundColor Magenta
	}
	else {
		Write-Host "WSL is already installed" -ForegroundColor Green
	}
	Remove-Variable TestWsl
	Print-Block

	Write-Host "Installing Docker" -ForegroundColor Magenta
	Write-Host "TESTING Docker installation" -ForegroundColor Magenta
	$TestDocker = powershell docker -v
	$TestDockerCompose = powershell docker-compose -v
	if(-not($TestDocker) -or (-not($TestDockerCompose))) {
        Write-Host "NOT EXIST Docker installation" -ForegroundColor Magenta
        Write-Host "Installing Docker" -ForegroundColor Magenta
		choco install docker-desktop -y
		Write-Host "Docker installation finished" -ForegroundColor Magenta
	}
	else {
		Write-Host "Docker-desktop is already installed" -ForegroundColor Green
	}
	
	Print-Block
	Write-Host "Installing Visual Studio Code" -ForegroundColor Magenta
	Write-Host "TESTING Visual Studio Code installation" -ForegroundColor Magenta
	$TestVSCode = powershell code -v
	if(-not($TestVSCode)) {
        Write-Host "NOT EXIST Visual Studio Code installation" -ForegroundColor Magenta
        Write-Host "Installing Visual Studio Code" -ForegroundColor Magenta
		choco install vscode -y
	}
	else { 
		Write-Host "VSCode is already installed" -ForegroundColor Green
	    Refresh-Environment-Variables
	    Write-Host "Installing Visual Studio Code *Extensions*" -ForegroundColor Magenta  
	}
	Install-VSCode-Extensions
	Write-Host "Visual Studio Code installation finished" -ForegroundColor Magenta
	Remove-Variable TestVSCode
	Print-Block

	Write-Host "Installing Git" -ForegroundColor Magenta
	Write-Host "TESTING Git installation" -ForegroundColor Magenta
	$TestGit = powershell git --version
	if(-not($TestGit)) {
        Write-Host "NOT EXIST Git installation" -ForegroundColor Magenta
        Write-Host "Installing Git" -ForegroundColor Magenta
		choco install git -y
		Refresh-Environment-Variables
		Write-Host "Git installation finished" -ForegroundColor Magenta
	}
	else {
		Write-Host "Git is already installed" -ForegroundColor Green
	}
	Remove-Variable TestGit
	Print-Block
    if(-not($TestDocker) -or (-not($TestDockerCompose))) {
	    Restart-Machine
		Remove-Variable TestDocker
		Remove-Variable TestDockerCompose
		Write-Host "Script Finished" -ForegroundColor Green
		pause
		exit 0
    }
}

Check-Installation-Folder

Write-Host "Launching Docker-Desktop" -ForegroundColor Magenta
Start-Process -FilePath $DockerDesktopPath
Wait-DockerUp $DockerTimeBetweenTries $DockerStartCheckMaxTries

## Prepare user project
Write-Host "Preparing User project repository" -ForegroundColor Magenta
Write-Host "Creating docker_volumes/project_folder folder"
## Creating folders for the repository
if (-Not (Test-Path $ProjectRepoFolder))
{	
	mkdir -p $ProjectRepoFolder
}
Set-Location $ProjectRepoFolder

## Clone repository and add Post-Commit Hook
Write-Host "Starting git"
git init
Write-Host "Pulling repository"
git pull "$ProjectRepositoryPath" > git_out.log 2>&1
Copy-Item -Path "$ConfigResourcesFolder/post-commit" -Destination "$ProjectRepoFolder/.git/hooks"
Set-Location $BaseFolder
Print-Block

## Prepare images
Write-Host "Preparing Docker images" -ForegroundColor Magenta
docker build -t devops_jenkins -f "$BaseFolder/images_dockerfiles/Dockerfile.jenkins" .
#docker build -t devops_production -f "$BaseFolder/images_dockerfiles/Dockerfile.angular" .
docker-compose -f $ProjectRepoFolder/docker-compose.yml up -d
Print-Block

## Launching containers
Write-Host "Launching Docker-Compose" -ForegroundColor Magenta
docker-compose up -d
Set-Location $BaseFolder

Print-Block

# Check if jenkins is running
Wait-JenkinsUp $JenkinsTimeBetweenTries $JenkinsStartCheckMaxTries
# Create the pipeline
Copy-Item $ConfigResourcesFolder/Jenkinsfile -Destination $ProjectRepoFolder
Set-Location  $ProjectRepoFolder
git add Jenkinsfile
git commit -m "Adding Jenkins file"
Set-Location $BaseFolder

$GitPath = where.exe git
$GitPathParent = Split-Path -Path $GitPath
$GitFolder = Split-Path -Path $GitPathParent
$GitPathSh = "$GitFolder\bin\sh.exe"

Write-Host "Creating pipeline" -ForegroundColor Magenta
& $GitPathSh $ConfigResourcesFolder/pipeline_creation.sh $JenkinsAddress $JenkinsUser $JenkinsPassword
Print-Block
Write-Host "Creating sonar project" -ForegroundColor Magenta
& $GitPathSh $ConfigResourcesFolder/sonar_project.sh $SonarAddress MyProjectKey MyProjectName $SonarUser $SonarPassword
Print-Block

Write-Host "Script Finished" -ForegroundColor Green
pause
