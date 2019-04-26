Clear-Host

$CustomerName = Read-Host "`nPlease enter the Customer Name (Examples: CBS TV or Entercom) "

Clear-Host

try
{
	Get-ADOrganizationalUnit -Identity "OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=COM" | Out-Null
	Write-Host "`nLooks like OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=COM already exists.  Exiting Script.`n`n"
	exit
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{
	Write-Host "This script will move forward with the following configuration`n"
	Write-Host "        Create OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=COM"
	Write-Host "        Create OU=DR,OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=COM"
	Write-Host "        Create OU=DEV,OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=COM"
	Write-Host "        Create OU=PROD,OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=COM"
	Write-Host "        Create GPO Client - $CustomerName"
	Write-Host "        Link Client Patching - DR GPO to OU=DR,OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=COM"
	
	$input = Read-Host "`nEnter (Yes) if correct "

	if ($input -ne 'Yes'){
		Write-Host "`nYou must enter Yes to move forward. Please validate the host configuration and try again."
		exit
	}
}

Write-Host "Creating Customer OU Structure in Active Directory"
#Create OU Structure
New-ADOrganizationalUnit -Name $CustomerName -Path "OU=Clients,DC=WOCLOUD,DC=COM" -Description "Customer OU Structure" -PassThru
New-ADOrganizationalUnit -Name "DR" -Path "OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=COM" -Description "OU Structure for DR Servers" -PassThru
New-ADOrganizationalUnit -Name "PROD" -Path "OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=COM" -Description "OU Structure for Production Servers" -PassThru
New-ADOrganizationalUnit -Name "DEV" -Path "OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=COM" -Description "OU Structure for DEV Servers" -PassThru

Write-Host "Creating Client Group Policy and Linking to OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=com"
Start-Sleep -s 30

#Create Client Group Policy and Link it to new OU Structure
Get-GPStarterGPO -Name "Client-GPO" | New-GPO -Name "Client - $CustomerName" | New-GPLink -Target "OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=com"

Write-Host "Linking Client Patching - DR group policy to OU=DR,OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=com"
Start-Sleep -s 30

#Link "Client Patching - DR" Group Policy to DR OU 
New-GPLink -Name "Client Patching - DR" -Target "OU=DR,OU=$CustomerName,OU=Clients,DC=WOCLOUD,DC=com"

