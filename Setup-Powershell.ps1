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

function Dinks-AzContext {
	[CmdletBinding()]
	param (
			
	)
	`$AzContext = Get-AzContext;

	if ( -not `$AzContext )
	{
		Connect-AzAccount;

		`$AzContext = Get-AzContext;
	}

	`$allContexts = (Get-AzContext -List | Sort-Object Account);
	`$contextArray = @();
	`$contextCount = 0;
	`$contextInput = 0;

	Foreach (`$context in `$allContexts) {
		if (`$context.Name.StartsWith('MSFT')) {
			`$contextArray += `$context;
			Write-Host -ForegroundColor Gray ('[' + `$contextCount + '] - ' + `$context.Name);
			`$contextCount++;
		}
	}

	Write-Host;
	`$contextInput = Read-Host 'Select Context'
    
	Write-Host;
	Set-AzContext  -Context `$contextArray[`$contextInput];
}

function Dinks-GitPrune {
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

function Dinks-ActivatePimRoles {
	[CmdletBinding()]
	param (
		[string]`$SubscriptionName,

		[string]`$SubscriptionId,

		[string]`$ResourceGroupName,

		[string]`$ResourcePIMID,

		[string]`$RoleName,

		[string]`$RoleDefinitionPIMID,

		[parameter(Mandatory = `$true)]
		[string]`$Justification,

		[parameter(Mandatory = `$true)]
		[int]`$DurationInHours
	)

	if ([string]::IsNullOrEmpty(`$ResourcePIMID)) {
		if (`$ResourceGroupName) {
			`$ResourcePIMID = (Get-AzureADMSPrivilegedResource -ProviderId `"AzureResources`" -Filter `"ExternalId eq '/subscriptions/`$subscriptionID/resourceGroups/`$ResourceGroupName'`").Id
		}
		else {
			`$ResourcePIMID = (Get-AzureADMSPrivilegedResource -ProviderId `"AzureResources`" -Filter `"ExternalId eq '/subscriptions/`$subscriptionID'`").Id
		}
	}

	Write-Host `"Resource PIM id        : `$ResourcePIMID`"

	if ([string]::IsNullOrEmpty(`$RoleDefinitionPIMID)) {
		`$RoleDefinitionId = Get-AzRoleDefinition -Name `$RoleName | Select-Object -ExpandProperty Id
		Write-Host `"Role definition id     : `$RoleDefinitionId`"

		`$RoleDefinitionPIMID = Get-AzureADMSPrivilegedRoleDefinition -ProviderId `"AzureResources`" -Filter `"ExternalId eq '/subscriptions/`$subscriptionID/providers/Microsoft.Authorization/roleDefinitions/`$roleDefinitionID'`" -ResourceId `$ResourcePIMID  | Select-Object -ExpandProperty Id
	}

	Write-Host `"Role definition PIM id : `$RoleDefinitionPIMID`"

	`$schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
	`$schedule.Type = `"Once`"
	`$schedule.StartDateTime = (Get-Date).ToUniversalTime()
	`$schedule.endDateTime = `$schedule.StartDateTime.AddHours(`$DurationInHours)

	Write-Debug (`$schedule)

	`$AzContext = Get-AzContext
	`$ADUserObj = Get-AzureADUser -ObjectId `$AzContext.Account.Id

	`$params = @{
		AssignmentState  = `"Active`";
		ProviderId       = `"AzureResources`";
		Reason           = `$Justification; 
		ResourceId       = `$ResourcePIMID;
		RoleDefinitionId = `$RoleDefinitionPIMID;
		Type             = `"UserAdd`";
		Schedule         = `$schedule;
		SubjectId        = `$ADUserObj.ObjectId
	}

	Open-AzureADMSPrivilegedRoleAssignmentRequest @params
}

function Dinks-ListPimRoles {
	[CmdletBinding()]
	param (
		
	)
	
	try {
		`$AzContext = Get-AzContext;
	
		if (-not `$AzContext) {
			Connect-AzAccount;
			`$AzContext = Get-AzContext;
		}
	
		Connect-AzureAD -TenantId `$AzContext.Tenant.TenantId -AccountId `$AzContext.Account.Id;
		# Get-AzureADUser;

		Write-Host -ForegroundColor Cyan `"Dinks-ActivatePimRoles -SubscriptionId 01151b44-dd2b-4585-a947-700f01bcc8d0 -RoleName Contributor -ResourceGroupName ReconPPE-SouthCentralUS-rg -Justification 'dev access' -DurationInHours 8 -ErrorAction Stop`"
		Write-Host -ForegroundColor Cyan `"Dinks-ActivatePimRoles -SubscriptionId 01151b44-dd2b-4585-a947-700f01bcc8d0 -RoleName Contributor -ResourceGroupName ReconPPE-EastUS2-rg -Justification 'dev access' -DurationInHours 8 -ErrorAction Stop`"
	}
	catch {
		`$TerminatingError = `$_;
		`$ErrorTable = @{
			LineNumber   = `$TerminatingError.InvocationInfo.ScriptLineNumber;
			ScriptName   = `$TerminatingError.InvocationInfo.ScriptName;
			LineContent  = `$TerminatingError.InvocationInfo.Line.Trim(`" `", `"`t`");
			ErrorMessage = `$TerminatingError.Exception.Message;
		}
	
		Write-Host;
		Write-Host -ForegroundColor Red `"A terminating error occured!`";
		Write-Host -ForegroundColor Red `"Details below:`";
		`$ErrorTable | Format-Table -AutoSize;
	
		Exit 1;
	}
}
"