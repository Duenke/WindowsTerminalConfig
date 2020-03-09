# $PROFILE | Format-List -Force

Write-Host "removing excess profiles..."

if ((Test-Path -Path $PROFILE.AllUsersAllHosts)) {
  Remove-Item -Path $PROFILE.AllUsersAllHosts
}
if ((Test-Path -Path $PROFILE.CurrentUserAllHosts)) {
  Remove-Item -Path $PROFILE.CurrentUserAllHosts
}
if ((Test-Path -Path $PROFILE.CurrentUserCurrentHost)) {
  Remove-Item -Path $PROFILE.CurrentUserCurrentHost
}
if ((Test-Path -Path $PROFILE.AllUsersCurrentHost)) {
  Remove-Item -Path $PROFILE.AllUsersCurrentHost
}

Write-Host "creating new profile..."

New-Item -ItemType File -Path $PROFILE.AllUsersCurrentHost -Force
Set-Content -Path $PROFILE.AllUsersCurrentHost -Value "
Import-Module posh-git
Import-Module oh-my-posh
Set-Theme Paradox"

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
