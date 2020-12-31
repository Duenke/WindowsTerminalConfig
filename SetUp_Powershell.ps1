# $PROFILE | Format-List -Force

if (Get-Module -ListAvailable -Name posh-git) {
  Write-Host "posh-git already installed..."
} 
else {
    Write-Host "installing module: posh-git..."
    Install-Module posh-git -Scope CurrentUser
}
if (Get-Module -ListAvailable -Name oh-my-posh) {
    Write-Host "oh-my-posh already installed..."
} 
else {
    Write-Host "installing module: oh-my-posh..."
    Install-Module oh-my-posh -Scope CurrentUser
}
if (Get-Module -ListAvailable -Name PSReadLine) {
    Write-Host "PSReadLine already installed..."
} 
else {
    Write-Host "installing module: PSReadLine..."
    Install-Module -Name PSReadLine -AllowPrerelease -Scope CurrentUser -Force -SkipPublisherCheck
}

Write-Host "removing excess profiles..."

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

New-Item -ItemType File -Path $PROFILE.AllUsersAllHosts -Force
Set-Content -Path $PROFILE.AllUsersAllHosts -Value "
if (`$Host.Name -eq 'ConsoleHost')
{
    Import-Module posh-git
    Import-Module oh-my-posh
    Set-Theme Paradox
}
elseif (`$Host.Name -like '*ISE Host')
{
    # Start-Steroids
    # Import-Module PsIseProjectExplorer
}

function azc {
    `$AzContext = Get-AzContext;

    if ( -not `$AzContext )
    {
        Connect-AzAccount;

        `$AzContext = Get-AzContext;
    }

    `$allContexts = (Get-AzContext -List | Sort-Object Account)
    `$contextArray = @()
    `$contextCount = 0
    `$contextInput = 0

    Foreach(`$context in `$allContexts){
        if(`$context.Name.StartsWith('MSFT')){
            `$contextArray += `$context
            Write-Host ('[' + `$contextCount + '] - ' + `$context.Name)
            `$contextCount++
        }
    }

    Write-Host ''
    `$contextInput = Read-Host 'Select Context'
    
    Write-Host ''
    Set-AzContext  -Context `$contextArray[`$contextInput]
}

function ResetGitBranches {
    git checkout -q 'master' | Out-Null
    
    `$except = 'master', 'a_dud'
    `$availabeBranches = git branch | foreach {`$_.Substring(2, `$_.Length - 2)} | where {`$except -notcontains `$_}

    Write-Host 'Available branches on local machine: '
    `$index = 0
    foreach(`$branch in `$availabeBranches) {
        Write-Host [`$index] `$branch
        `$index += 1
    }

    Write-Host
    Do {
        `$saveIndex = Read-Host -Prompt 'Enter branch # to save'
        `$saveBranch = `$availabeBranches[`$saveIndex]
        `$except += `$saveBranch
    } While(`$saveIndex -ne '')

    `$branchesToDelete = git branch | foreach {`$_.Substring(2, `$_.Length - 2)} | where {`$except -notcontains `$_}

    foreach(`$branch in `$branchesToDelete) {
        Write-Host('Deleting branch: ' + `$branch)
        git branch -d -f `$branch
    }

    Write-Host('Pulling branch: master')
    git pull
}
"