# $PROFILE | Format-List -Force

if (Get-Module -ListAvailable -Name posh-git) {
  Write-Host -ForegroundColor Magenta "posh-git already installed..."
} 
else {
    Write-Host -ForegroundColor Magenta "Installing module: posh-git..."
    Install-Module posh-git -Scope CurrentUser
}
if (Get-Module -ListAvailable -Name oh-my-posh) {
    Write-Host -ForegroundColor Magenta "oh-my-posh already installed..."
} 
else {
    Write-Host -ForegroundColor Magenta "Installing module: oh-my-posh..."
    Install-Module oh-my-posh -Scope CurrentUser
}
if (Get-Module -ListAvailable -Name PSReadLine) {
    Write-Host -ForegroundColor Magenta "PSReadLine already installed..."
} 
else {
    Write-Host -ForegroundColor Magenta "Installing module: PSReadLine..."
    Install-Module -Name PSReadLine -AllowPrerelease -Scope CurrentUser -Force -SkipPublisherCheck
}

Write-Host -ForegroundColor Magenta "Removing excess profiles..."

if ((Test-Path -Path $PROFILE.AllUsersAllHosts)) {
  Remove-Item -Path $PROFILE.AllUsersAllHosts
}
if ((Test-Path -Path $PROFILE.AllUsersCurrentHost)) {
  Remove-Item -Path $PROFILE.AllUsersCurrentHost
}
if ((Test-Path -Path $PROFILE.CurrentUserAllHosts)) {
  Remove-Item -Path $PROFILE.CurrentUserAllHosts
}
if ((Test-Path -Path $PROFILE.CurrentUserCurrentHost)) {
  Remove-Item -Path $PROFILE.CurrentUserCurrentHost
}

Write-Host "creating new profile..."

New-Item -ItemType File -Path $PROFILE.CurrentUserCurrentHost -Force
Set-Content -Path $PROFILE.CurrentUserCurrentHost -Value "
try {
	# Set-PoshPrompt -Theme C:\GitHub\WindowsTerminalConfig\.oh-my-posh.omp.json;
	# `$env:POSH_GIT_ENABLED = `$true;
}
catch {
	Write-Host -ForegroundColor Magenta 'oh-my-posh has not been set up in this terminal. :)';
}

function Dinks-GitPrune {
	[CmdletBinding()]
	param (
		[switch]`$SafeMode
	)
	try {
		git checkout -q 'develop' | Out-Null;
	}
	catch {
		Write-Host -ForegroundColor Red 'This directory is not a git repository!';
		return;
	}

	try {
		git fetch -p | Out-Null;
	}
	catch {
		Write-Host -ForegroundColor Red 'Error fetching from remote!';
		return;
	}

	try {
		git for-each-ref --format '%(refname) %(upstream:track)' refs/heads | ForEach-Object -Process { 
			if(`$_ -like '*gone]') { 
				Write-Host -ForegroundColor DarkYellow -NoNewline Deleting branch: ;
				Write-Host -ForegroundColor Yellow `$_.substring(11);
				if(`$SafeMode) { git branch -d `$_.substring(11, `$_.length - 18); }
				else { git branch -D `$_.substring(11, `$_.length - 18); }
			}
		};	
	}
	catch {
		Write-Host -ForegroundColor Red 'Error deleting local branches!';
		return;
	}
}

function Dinks-GitDelete {
	[CmdletBinding()]
	param (
			
	)
	try {
		git checkout -q 'develop' | Out-Null;
	}
	catch {
		Write-Host -ForegroundColor Red 'This directory is not a git repository!';
		return;
	}
    
	`$except = 'master', 'main', 'develop', 'a_dud';
	`$availabeBranches = git branch | ForEach-Object { `$_.Substring(2, `$_.Length - 2) } | Where-Object { `$except -notcontains `$_ };

	Write-Host -ForegroundColor Magenta 'Available branches on local machine: ';
	`$index = -1;
	foreach (`$branch in `$availabeBranches) {
		`$index += 1;
		Write-Host -ForegroundColor Yellow [`$index] `$branch;
	}

	Write-Host;
	Do {
		`$saveIndex = Read-Host -Prompt 'Enter branch # to save';

		if (`$saveIndex -eq '') {
			break;
		}
		else {
			`$saveBranch = `$availabeBranches[`$saveIndex];
			`$except += `$saveBranch;
		}
	} While (`$true)

	`$branchesToDelete = git branch | ForEach-Object { `$_.Substring(2, `$_.Length - 2) } | Where-Object { `$except -notcontains `$_ };

	foreach (`$branch in `$branchesToDelete) {
		Write-Host -ForegroundColor Yellow 'Deleting branch: ' `$branch;
		git branch -d -f `$branch;
	}

	Write-Host -ForegroundColor Green 'Pulling branch: develop';
	git pull;
}
"