#written by tkps@github
Function Get-GPOOrphans
{
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({$_ -in (Get-ADForest | Select-Object -ExpandProperty Domains)})]
        [string]
        $Domain
    )
    Process
    {
        $GPOs = Get-GPO -All -Domain $Domain

        $OUs = Get-ADOrganizationalUnit -Filter * | Select-Object -ExpandProperty DistinguishedName
        $OUs += Get-ADDomain -Identity $Domain | Select-Object -ExpandProperty DistinguishedName

        $GPLinks = $OUs | ForEach-Object {Get-GPInheritance $_ -Domain $Domain}

        $UniqueLinkedGPOs = Sort-Object -Unique -InputObject $GPLinks.gpolinks.displayname
        Where-Object -InputObject $GPOs -FilterScript {$PSItem.DisplayName -notin $UniqueLinkedGPOs}
    }
}