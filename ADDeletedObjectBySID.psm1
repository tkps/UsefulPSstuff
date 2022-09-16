Function Get-ADDeletedObjectBySID
{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [ValidatePattern("S-1-5-21-\d+-\d+-\d+-\d+$")]
        [String[]]
        $ObjectSID,
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential

        )
    Begin
    {
        $DomainsWithSID = Get-ADForest |Select-Object -exp domains | Get-ADDomain
    }
    Process
    {
        Foreach ($Value in $ObjectSID)
        {
            If ($null -ne ($DomainsWithSID | Where-Object DomainSID -eq ($Value -replace '^(S\-1\-5\-21\-\d+\-\d+\-\d+)\-\d*$','$1')))
            {
                $FilterStr = 'name -ne "Deleted Objects" -and objectSID -like "' + $Value + '"'
                get-adobject -Filter $FilterStr -IncludeDeletedObjects -Properties samaccountname,displayname,objectsid -Server ($DomainsWithSID | Where-Object DomainSID -eq ($Value -replace '^(S\-1\-5\-21\-\d+\-\d+\-\d+)\-\d*$','$1')).DNSRoot -Credential $Credential
            }else{
                Write-Warning "$Value does not match any known DomainSID"
            }
        }
    }
}
