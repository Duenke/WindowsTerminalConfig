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
    `$allContexts = (Get-AzContext -List | Sort-Object Account)
    `$contextArray = @()
    `$contextEmailArray = @()
    `$contextCount = 0

    Write-Host ''
    Foreach(`$context in `$allContexts){
        if(!`$contextEmailArray.Contains(`$context.Account.Id)){
            `$contextArray += `$context
            `$contextEmailArray += `$context.Account.Id
            Write-Host ('[' + `$contextCount + '] - ' + `$context.Account)
            `$contextCount++
        }
    }

    if (!(`$contextInput = Read-Host 'Select Context')) { `$contextInput = 0 }
    `$setContext = Set-AzContext  -Context `$contextArray[`$contextInput]

    `$allSubscriptions = (Get-AzSubscription | Where-Object {`$_.State -eq 'Enabled'} | Sort-Object Name)
    `$subscriptionArray = @()
    `$subscriptionCount = 0

    foreach(`$subscription in `$allSubscriptions){
        `$subscriptionArray += `$subscription.Id
        Write-Host ('[' + `$subscriptionCount + '] - ' + `$subscription.Name + ' - ' + `$subscription.Id)
        `$subscriptionCount++
    }

    if(`$subscriptionArray.Count -gt 1) {
        if (!(`$subscriptionInput = Read-Host 'Select Subscription')) { `$subscriptionInput = 0 }
    } else {
        `$subscriptionInput = 0
    }
    
    Set-AzContext -SubscriptionId `$subscriptionArray[`$subscriptionInput]
}
"