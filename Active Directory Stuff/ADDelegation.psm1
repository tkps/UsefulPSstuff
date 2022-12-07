
Function New-ADDelegation
{
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    Param(
        #DistinguishedName of the OU which ACL should be modified
        [Parameter(Mandatory=$true)]
        [string[]]
        $DistinguishedName,

        #Name of the AD Group which will be delegated permissions
        [Parameter(Mandatory=$true)]
        $GroupName,

        #What type of object to delegate permissions for
        [Parameter()]
        [ValidateSet("User","Computer","Group","msDS-GroupManagedServiceAccount","msDS-ManagedServiceAccount")]
        [string]
        $ObjectType,
        [switch]
        $AllowGpoLink,
        [switch]
        $AllowSubOU
        )
    Begin
    {
        Try
        {
            Import-Module ActiveDirectory
        }
        Catch {
            Write-Error "Error loading Active Directory module"
            exit 3
        }
        Set-Location AD:

        $rootdse = Get-ADRootDSE 
        $guidmap = @{}
        
        $GuidMapParams = @{
         SearchBase = ($rootdse.SchemaNamingContext)
         LDAPFilter = "(schemaidguid=*)"
         Properties = ("lDAPDisplayName","schemaIDGUID")}
        
        Get-ADObject @GuidMapParams | ForEach-Object {$guidmap[$_.lDAPDisplayName]=[System.GUID]$_.schemaIDGUID} 
        
        $ExtendedMapParams = @{
         SearchBase = ($rootdse.ConfigurationNamingContext)
         LDAPFilter = "(&(objectclass=controlAccessRight)(rightsguid=*))"
         Properties = ("displayName","rightsGuid")}
        
        $extendedrightsmap = @{}
        
        Get-ADObject @ExtendedMapParams | ForEach-Object {$extendedrightsmap[$_.displayName]=[System.GUID]$_.rightsGuid}
    }
    
    Process
    {
        Foreach ($value in $DistinguishedName)
        {
            
            Try 
            { 
                $OU = Get-ADOrganizationalUnit $Value
            }
            Catch
            {
                Write-Error "Could not find OU: $Value"
                continue
            }
            Try
            {
                $ADGroup = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup $GroupName).SID
            }
            Catch
            {
                Write-Error "Could not find Group: $GroupName"
                return
            }

            $ACL = get-acl $OU
            $AllAces = New-Object System.Collections.Generic.List[System.DirectoryServices.ActiveDirectoryAccessRule]
            $GUID = $guidmap["$ObjectType"]
            
            If ($AllowSubOU.IsPresent)
            {
                $Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $ADGroup,"CreateChild","Allow",$guidmap["organizationalUnit"],"All"
                $AllAces.Add($Ace)

                $Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $ADGroup,"DeleteChild","Allow",$guidmap["organizationalUnit"],"All"
                $AllAces.Add($Ace)
            }
            If ($AllowGpoLink.IsPresent)
            {
                $Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $ADGroup,"WriteProperty","Allow",$guidmap["gpLink"],"All"
                $AllAces.Add($Ace)
                
                $Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $ADGroup,"WriteProperty","Allow",$guidmap["gpOptions"],"All"
                $AllAces.Add($Ace)
            }

            $Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $ADGroup,"CreateChild","Allow",$GUID,"All"
            $AllAces.Add($Ace)
            
            $Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $ADGroup,"DeleteChild","Allow",$GUID,"All"
            $AllAces.Add($Ace)
            
            $Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $ADGroup,"WriteProperty","Allow","Descendents",$GUID
            $AllAces.Add($Ace)
            
            switch ($ObjectType)
            {
                'User' {
                            $Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $ADGroup,"ExtendedRight","Allow",$extendedrightsmap["Reset Password"],"Descendents",$GUID
                            $AllAces.Add($Ace)
                        }
                'Computer' {
                            # $Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $ADGroup,"ExtendedRight","Allow",$extendedrightsmap["Validated write to service principal name"],"Descendents",$GUID
                            # $AllAces.Add($Ace)

                            # $Ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $ADGroup,"ExtendedRight","Allow",$extendedrightsmap["Validated write to DNS host name"],"Descendents",$GUID
                            # $AllAces.Add($Ace)  
                        }
            }
            ForEach ($Ace in $AllAces){
                $acl.AddAccessRule($Ace)
            }
            try {
                Set-Acl -aclobject $ACL -Path $OU -WhatIf:$WhatIfPreference -Confirm:$ConfirmPreference
            }
            catch {
                $_
                Write-Error "Error setting acl on $OU"
            }

            #Reset variables
            $ACL = $null
            $AllAces = $null
        }
    }
}