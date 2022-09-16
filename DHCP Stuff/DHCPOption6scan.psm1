Function Search-DHCPScopesOption6
{
    Param(
        #IP Address of the DNS Server to look for in Option 6
        [Parameter(Mandatory=$true,
                    ValueFromPipeline=$true)]
                    [ipaddress]
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