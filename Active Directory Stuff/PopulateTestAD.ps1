Import-Module .\ADDelegation.psm1

If (-not (Test-Path "C:\Temp")){New-Item -Path C:\ -Name Temp -Type Directory}
Set-Location -Path C:\Temp
Expand-Archive "Windows Server 2022 Security Baseline.zip" -DestinationPath .\
If (Get-Item "Windows Server-2022-Security-Baseline-FINAL") {Remove-Item 'Windows Server 2022 Security Baseline.zip';Set-Location 'C:\Temp\Windows Server-2022-Security-Baseline-FINAL\Scripts'}
.\Baseline-ADImport.ps1
New-GPLink -Guid (Get-GPO -DisplayName "MSFT Windows Server 2022 - Domain Controller").Id -Target (Get-ADDOmain).DomainControllersContainer

#Create an OU Structure
$Companies = "Company A","Company B"
Foreach ($Top in $Companies)
{
    $TopOU = New-ADOrganizationalUnit -Name $Top -PassThru
    Foreach ($Sub in "Servers","Users","Groups","ServiceAccounts","Clients","Admin")
    {
        $SubOU = New-ADOrganizationalUnit -Name $Sub -Path $TopOU.DistinguishedName -PassThru
        Switch ($SubOU.Name)
        {
            "Servers" {Foreach ($Sub2 in "Server 2019","Server 2022")
                        {
                            $Sub2OU = New-ADOrganizationalUnit -Name $Sub2 -Path $SubOU.DistinguishedName -PassThru
                        }}
            "Users" {Foreach ($Sub2 in "Internal","External","Disabled")
                        {
                            $Sub2OU = New-ADOrganizationalUnit -Name $Sub2 -Path $SubOU.DistinguishedName -PassThru
                        }}
            "Groups" {Foreach ($Sub2 in "File share access","Application permissions")
                        {
                            $Sub2OU = New-ADOrganizationalUnit -Name $Sub2 -Path $SubOU.DistinguishedName -PassThru
                        }}
            "Clients" {Foreach ($Sub2 in "Windows 11","Windows 10")
                        {
                            $Sub2OU = New-ADOrganizationalUnit -Name $Sub2 -Path $SubOU.DistinguishedName -PassThru
                        }}
        }
    }
}
Get-ADOrganizationalUnit -Filter {Name -eq "Server 2022"} | ForEach-Object -Process {New-GPLink -Guid (Get-GPO -DisplayName "MSFT Windows Server 2022 - Member Server").Id -Target $_.DistinguishedName}

Foreach ($Company in $Companies)
{
    $CompanyOU = Get-ADOrganizationalUnit -Filter {Name -eq $Company}
    Foreach ($Type in "Servers","Users","Groups","ServiceAccounts","Clients")
    {
        $Grp = New-ADGroup -Name "T2-$Company-$Type" -GroupScope Global -GroupCategory Security -Path (Get-ADOrganizationalUnit -Filter {Name -eq "Admin"} -SearchBase $CompanyOU.DistinguishedName) -PassThru
        Switch ($Type) {
            "Servers" {
                New-ADDelegation -DistinguishedName (Get-ADOrganizationalUnit -Filter {Name -eq $Type} -SearchBase $CompanyOU.DistinguishedName) -GroupName $Grp.Name -ObjectType Computer -AllowGpoLink -AllowSubOU
            }
            "Users" {
                New-ADDelegation -DistinguishedName (Get-ADOrganizationalUnit -Filter {Name -eq $Type} -SearchBase $CompanyOU.DistinguishedName) -GroupName $Grp.Name -ObjectType User -AllowGpoLink -AllowSubOU
            }
            "Groups" {
                New-ADDelegation -DistinguishedName (Get-ADOrganizationalUnit -Filter {Name -eq $Type} -SearchBase $CompanyOU.DistinguishedName) -GroupName $Grp.Name -ObjectType Group
            }
            "ServiceAccounts" {
                New-ADDelegation -DistinguishedName (Get-ADOrganizationalUnit -Filter {Name -eq $Type} -SearchBase $CompanyOU.DistinguishedName) -GroupName $Grp.Name -ObjectType User -AllowGpoLink -AllowSubOU
                New-ADDelegation -DistinguishedName (Get-ADOrganizationalUnit -Filter {Name -eq $Type} -SearchBase $CompanyOU.DistinguishedName) -GroupName $Grp.Name -ObjectType msDS-GroupManagedServiceAccount
                New-ADDelegation -DistinguishedName (Get-ADOrganizationalUnit -Filter {Name -eq $Type} -SearchBase $CompanyOU.DistinguishedName) -GroupName $Grp.Name -ObjectType msDS-ManagedServiceAccount
            }
            "Clients" {
                New-ADDelegation -DistinguishedName (Get-ADOrganizationalUnit -Filter {Name -eq $Type} -SearchBase $CompanyOU.DistinguishedName) -GroupName $Grp.Name -ObjectType Computer -AllowGpoLink -AllowSubOU
            }
        }

    }
}
