Import-Module .\ADDelegation.psm1

If (-not (Test-Path "C:\Temp")){New-Item -Path C:\ -Name Temp -Type Directory}
Set-Location -Path C:\Temp

#Download microsoft security baseline for server 2022 and place in C:\temp

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

#example names from mockaroo.com
[System.Collections.Generic.Stack[PSCustomObject]]$csv = @"
"firstname","lastname"
"Glenn","Cordie"
"Carline","Arpino"
"Ermina","Leband"
"Alikee","Selkirk"
"Sosanna","Ewins"
"Teresa","Dinkin"
"Vasily","Beadnall"
"Cleveland","Board"
"Franciska","Sowten"
"Korella","McVitty"
"Zora","Bembrick"
"Shane","Wych"
"Bonni","Baggs"
"Roshelle","Flaonier"
"Annabella","Muldownie"
"Margaux","Oaks"
"Jürgen","Semanoviç"
"Kylynn","Dufaire"
"Alf","Birtwisle"
"Gates","Schettini"
"Lonni","Valiant"
"Odelia","Rulten"
"Carolan","Ovenden"
"Zahara","Dobrowolny"
"Netti","Bunn"
"Arney","Żądło-Dąbrowski"
"Datha","Murty"
"Leon","Follet"
"Randi","Corless"
"Gib","Cream"
"Elvera","Dysart"
"Ode","Flecknoe"
"Kale","Naton"
"Ad","Haslewood"
"Marty","Espinha"
"Uta","Janos"
"Andi","Hurran"
"Tad","Rumble"
"Chelsie","Seward"
"Carri","Steet"
"Siouxie","St. Leger"
"Lenee","Caruth"
"Zack","Seedhouse"
"Ulrica","MacAllister"
"Kalinda","L'Estrange"
"Percy","Vasiljevic"
"Cleopatra","Van Daalen"
"Stephen","Lemary"
"Clement","McRobbie"
"Cole","Dosdale"
"Allene","Moreing"
"Gregorio","O'Neary"
"Alix","Meneo"
"Gus","Kingdon"
"Darrelle","Chimenti"
"Harwilll","Gallgher"
"Åke","Älgsmörgås"
"Ulick","Meadmore"
"Mariya","Magrannell"
"Isabeau","Danahar"
"Cy","Newcome"
"Jemie","Douthwaite"
"Angelita","Deamer"
"Jonas","Wiffen"
"Junette","Hartlebury"
"Zebadiah","Bramham"
"Willi","Drakes"
"Teressa","Sliney"
"Burtie","Brecknell"
"Melany","Payler"
"Shurwood","Josephi"
"Marcel","Loos"
"Fowler","Stelli"
"Reyna","Theobold"
"Rycca","Honniebal"
"Rosalinda","Gaine"
"Anabel","Mabson"
"Herc","Slaughter"
"Ailsun","Tristram"
"Theda","Edler"
"Eliot","Clementi"
"Hymie","Beckey"
"Kimbell","Bennie"
"Tallie","Boyford"
"Jena","Giannazzo"
"Aurore","Greenin"
"Loraine","Towey"
"Odelia","Feria"
"Vidovik","Reynish"
"Torrin","Alleyn"
"Daria","Sperski"
"Flint","Carrane"
"Estelle","Birkett"
"Krissy","Blaszczyk"
"Sherwood","Lazer"
"Mari","Sibbons"
"Alix","McChesney"
"Karoly","Rosini"
"Sidney","Disbrey"
"Bennie","Meace"
"Maia","Dalgarno"
"Chico","Surby"
"Bernete","Durban"
"Cassandry","Triggle"
"Agnesse","Feaver"
"Yancy","Josephov"
"Valerie","Convery"
"Devondra","Bernardes"
"Athena","Balasini"
"Harmonie","Slader"
"Halie","Carbert"
"Nollie","Pensom"
"Lev","Milton"
"Bink","Lakeman"
"Wrennie","Coulbeck"
"Teodor","Southan"
"Merl","Stearley"
"Susana","Hansill"
"Augy","Poge"
"Sebastian","Jeyes"
"Opal","Sidnell"
"Anthea","Jurzyk"
"Shalom","Whitworth"
"Nial","Reinbech"
"Paulo","Carter"
"Nadean","Pavie"
"Elsi","Rottenbury"
"Renell","Szymanek"
"Silvano","Handling"
"Brier","Taffee"
"Calla","Linfield"
"Rex","Stucksbury"
"Fey","Grills"
"Ynes","Casaletto"
"Hal","Strathearn"
"Leonidas","Szymonwicz"
"Lloyd","Kildea"
"Maryjo","Zarfat"
"Netty","Sorby"
"Idell","Rieflin"
"Judy","Goymer"
"Michaeline","Colson"
"Alexa","Janic"
"Zeb","Purches"
"Tymothy","Bouchier"
"Anatol","Bachman"
"Montgomery","Boecke"
"Jack","Everil"
"Kennie","Petracek"
"Stearne","Chanson"
"Victoria","Buttriss"
"Ilaire","Anmore"
"Max","Goodbody"
"Eveline","Krol"
"Alina","Klugel"
"Opal","Slocket"
"Joeann","Thackham"
"Linet","Markham"
"Cyrus","Dallewater"
"Wittie","Garnall"
"Marlo","Chainey"
"Geri","Lawrie"
"Osbert","Laverty"
"Trish","Duckinfield"
"Jessica","Coopland"
"Wright","Farrans"
"Joshua","Tofano"
"Eustace","Toupe"
"Sindee","Jendrassik"
"Meggie","Eliez"
"Corinne","Gray"
"Ariana","Haskur"
"Justina","Bonick"
"Juline","O'Kuddyhy"
"Branden","Chaffey"
"Lana","Mowett"
"Gilli","Lipsett"
"Tabby","Hasty"
"Georgie","Whapham"
"Marissa","Sizeland"
"Candide","Bartles"
"Pamela","Robjents"
"Natty","Laughren"
"Jodie","Climpson"
"Valentino","Harston"
"Olympia","Vannar"
"Paula","Doolan"
"Noel","Marrill"
"Arel","Barkes"
"Marchall","Epilet"
"Jillie","Connaughton"
"Spencer","McTrustie"
"Burk","Pacht"
"Maris","Goldsby"
"Haskel","Ahearne"
"Roseanna","Gabites"
"Papageno","Crannis"
"Caitrin","McKeachie"
"Tresa","Dyett"
"Natassia","Sebley"
"@ | COnvertfrom-csv | Sort-Object {Get-Random}
Function New-Password {
    Param(
        [int]$Length = 14
    )
    Begin
    {
        $Upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()
        $Lower = "abcdefghijklmnopqrstuvwxyz".ToCharArray()
        $Digits = "0123456789".ToCharArray()
        $Special = "!#¤%&/()=?,.-;:_'*^@+".ToCharArray()
        $All = $Upper + $Lower + $Digits + $Special
    }
    Process
    {
        $PW = $Upper | Get-Random
        $PW += $Lower | Get-Random
        $PW += $Digits | Get-Random
        $PW += $Special | Get-Random
        While ($PW.length -lt $Length)
        {
            $PW += $All | Get-Random
        }
    }
    End {
        $PW
    }
}
Function Get-NormalizedString{
    Param(
        [Parameter(Position=0,ValueFromPipeline=$true)]
        [string]$String
    )
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String)) -replace '[^a-zA-Z0-9]', ''
}
$UPNSuffix = Get-ADDomain | Select-Object -ExpandProperty DNSRoot
#Create a mock organization
Foreach ($User in $CSV)
{
    $Company = $Companies | Get-Random
    $Splat = @{
        "GivenName" = $User.firstname
        "SurName" = $User.lastname
        "Name" = "$($User.firstname) $($User.lastname)"
        "UserPrincipalName" = "$((Get-NormalizedString -String $User.firstname).tolower()).$((Get-NormalizedString -String $User.lastname).tolower())@$UPNSuffix"
        "SamAccountName" = "$((Get-NormalizedString -String $User.firstname).tolower().Substring(0,2))$((Get-NormalizedString -String $User.lastname).tolower().substring(0,3))"
        "Company" = $Company
        "Path" = (Get-ADOrganizationalUnit -Filter {Name -eq "Internal"} -SearchBase ((Get-ADOrganizationalUnit -Filter {Name -eq $Company}).DistinguishedName)).DistinguishedName
        "Enabled" = $True
        "AccountPassword" = (ConvertTo-SecureString -AsPlainText -Force -String (New-Password -Length 15))
    }
    New-ADUser @Splat

}
$Departments = "IT","Marketing","HR","Operations","Finance","Legal"
Foreach ($Company in $Companies)
{
    [System.Collections.Generic.Stack[Microsoft.ActiveDirectory.Management.ADUser]]$CompanyUsers = Get-ADUser -Filter {Company -eq $Company} -Properties Company | Sort-Object {Get-Random}
    $CEO = $CompanyUsers.Pop() | Set-ADUser -Title "CEO" -Department "Management" -PassThru
    $CFO = $CompanyUsers.Pop() | Set-ADUser -Title "CFO" -Department "Management" -Manager $CEO -PassThru
    $CTO = $CompanyUsers.Pop() | Set-ADUser -Title "CTO" -Department "Management" -Manager $CEO -PassThru
    $COO = $CompanyUsers.Pop() | Set-ADUser -Title "COO" -Department "Management" -Manager $CEO -PassThru
    $CCO = $CompanyUsers.Pop() | Set-ADUser -Title "CCO" -Department "Management" -Manager $CEO -PassThru
    While ($CompanyUsers.count -gt 0) {$CompanyUsers.Pop() | Set-ADUser -Department ($Departments | Get-Random)}
    Foreach ($Department in $Departments)
    {
        [System.Collections.Generic.Stack[Microsoft.ActiveDirectory.Management.ADUser]]$DepartmentUsers = Get-ADUser -Filter {Department -eq $Department -and Company -eq $Company} -Properties Department | Sort-Object {Get-Random}
        Switch ($Department) {
            "IT" {$Manager = $CTO}
            "Marketing" {$Manager = $COO}
            "HR" {$Manager = $COO}
            "Operations" {$Manager = $COO}
            "Finance" {$Manager = $CFO}
            "Legal" {$Manager = $CCO}
        }
        $DepartmentManager = $DepartmentUsers.Pop() | Set-ADUser -Title "Head of $Department" -Department $Department -Manager $Manager -PassThru
        While ($DepartmentUsers.count -gt 0)
        {
            $DepartmentUsers.Pop() | Set-ADUser -Title "Employee" -Manager $DepartmentManager
        }
    }
}