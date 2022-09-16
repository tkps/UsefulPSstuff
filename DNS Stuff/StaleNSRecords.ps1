#This script is intended to run on a domain controller, and runs with the assumption that all domain controllers are global catalogs, and only the domain controllers in the AD forest are acting as DNS Servers.
#written by tkps@github
$DCs = Get-ADForest | Select-Object -ExpandProperty GlobalCatalogs | ForEach-Object {"$_."}
$Zones = Get-DnsServerZone
Foreach ($Zone in $Zones){
    $Zone | Get-DnsServerResourceRecord -RRType NS | Where-Object {$_.RecordData.NameServer -notin $DCs} | Remove-DnsServerResourceRecord -ZoneName $Zone.ZoneName -Confirm:$false -Force
}