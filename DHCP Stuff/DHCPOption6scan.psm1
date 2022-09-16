<#
.Synopsis
   Searches all Active Directory authorized DHCP servers for Option 6 pointing towards one or more specified IP Adresses
.DESCRIPTION
   Searches all Active Directory authorized DHCP servers for Option 6 pointing towards one or more specified IP Adresses
.EXAMPLE
   Search-DHCPScopesOption6 -IPAddress 10.0.10.0
.EXAMPLE
   Search-DHCPScopesOption6 -IPAddress 10.0.10.0,192.168.0.1
.EXAMPLE
   Resolve-DNSName dns.server.name | Search-DHCPSCopesOption6
.INPUTS
   IP address of the DNS Server which you want to find DHCP Scopes with Option 6 pointing towards
.OUTPUTS
   Output the information from DHCP Scope options with added Properties Server and Scope in a PSCustomObject
.NOTES
   Written by tkps@github
#>
Function Search-DHCPScopesOption6
{
    Param(
        #IP Address of the DNS Server to look for in Option 6
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
                    [ipaddress[]]
                    $IPAddress
    )
    $DHCPServers = Get-DhcpServerInDC
    Foreach ($DHCPServer in $DHCPServers)
    {
        $ServerOption = $null
        $ServerOption = Get-DhcpServerv4OptionValue -OptionId 6 -ComputerName $DHCPServer.DnsName -ErrorAction SilentlyContinue
        If ($ServerOption.Value | Where-Object {$_ -in $IPAddress})
        {
            $ServerOption | Select-Object *,@{n='Server';e={$DHCPServer.dnsname}},@{n='Scope';e={"ServerOption"}}
        }
        $ServerScopes = Get-DhcpServerv4Scope -ComputerName $DHCPServer.DnsName
        Foreach ($ServerScope in $ServerScopes)
        {
            $ScopeOption = $null
            $ScopeOption = $ServerScope | Get-DhcpServerv4OptionValue -OptionId 6 -ComputerName $DHCPServer.DnsName -ErrorAction SilentlyContinue
            If ($ScopeOption.Value | Where-Object {$_ -in $IPAddress})
            {
                $ScopeOption | Select-Object *,@{n='Server';e={$DHCPServer.dnsname}},@{n='Scope';e={$ServerScope.scopeid}}
            }
        }
    }
}