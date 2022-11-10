<#
.Synopsis
   Creates a new scheduled task which will run with a gMSA Account
.DESCRIPTION
   Creates a new scheduled task which will run in the context of a gMSA Account
.EXAMPLE
   New-gMSAScheduledTask -Name "Example task" -Path "gMSA scripts" -ScriptPath "\\insert\path\here.ps1" -Trigger (New-ScheduledTaskTrigger -Daily -At 07:30) -gMSAAccount "DOMAIN\gMSA-account-01$"
.EXAMPLE
   New-gMSAScheduledTask -Name "Example task" -Path "gMSA scripts" -ScriptPath "\\insert\path\here.ps1" -Trigger (New-ScheduledTaskTrigger -weekly -DaysOfWeek Monday -At 8:30 -WeeksInterval 4) -gMSAAccount "DOMAIN\gMSA-account-02$" -PS7
.INPUTS
   String values for names, paths and accountname, and a ScheduledTaskTrigger
.OUTPUTS
   None
.NOTES
   If you are using signed powershell scripts, feel free to change to a more strict execution policy.
#>
Function New-gMSAScheduledTask
{
    Param(
        #Name of the Scheduled Task
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]$Name,

        #Path in the task scheduler to place the scheduled task
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]$Path,

        #File path of the powershell script to be executed
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]$ScriptPath,

        #Needs to be a trigger constructed with New-ScheduledTaskTrigger
        [Parameter(Mandatory=$true)]
        $Trigger,

        #Name of the gMSA account in the form DOMAIN\accountname$
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]$gMSAAccount,

        #Run this using powershell core 7
        [Switch]$PS7
    )
    try
    {
        $Splat = @{
            'TaskName'  = $Name
            'TaskPath'  = $Path
            'Trigger'   = $Trigger
            'Settings'  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -ExecutionTimeLimit 12:00:00
            'Principal' = New-ScheduledTaskPrincipal -UserId "$gMSAAccount" -LogonType Password
            'Description'= "Scheduled powershell task made by $(whoami) on $(Get-Date -Format 'yyyy-MM-dd')"
        }
    }
    catch {
        $_
        Write-Error "Error setting up variables for scheduled task"
        exit 154
    }
    If ($PS7.IsPresent)
    {
        $Splat['Action'] = (New-ScheduledTaskAction -Execute "C:\Program Files\PowerShell\7\pwsh.exe" -Argument "-ExecutionPolicy Bypass -File $ScriptPath")
    }else{
        $Splat['Action'] = (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File $ScriptPath")
    }
    try{
        Register-ScheduledTask @Splat
    }
    Catch {
        $_
        Write-Error "Error registering scheduled task"
        exit 155
    }
}
Function Add-GmsaPrincipal
{
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    Param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName)]
        [String[]]
        $DistinguishedName,
        [Parameter()]
        [String]
        [ValidateScript({Get-ADObject $_})]
        $NewPrincipal,
        [Switch]$Force
        )
    Begin {
        if ($Force -and -not $Confirm){
            $ConfirmPreference = 'None'
        }
        try {
            Import-Module ActiveDirectory -ErrorAction Stop
        }
        Catch{
            Write-Error "Error loading Active Directory module"
            exit 3
        }
    }
    Process{
        Foreach ($Row in $DistinguishedName)
        {
            If ($Force -or $PSCmdlet.ShouldProcess($Row,'Add'))
            {
                try
                {
                    Get-ADServiceAccount -Identity $Row -Properties PrincipalsAllowedToRetrieveManagedPassword | Set-ADServiceAccount -PrincipalsAllowedToRetrieveManagedPassword ($_.PrincipalsAllowedToRetrieveManagedPassword + $Principal) -PassThru
                }
                Catch
                {
                    Write-Error "Error adding $Principal as a principal to $Row"
                    Exit 4
                }
            }
        }
    }
}