Write-Host "Begin"

function Test-Function {
    Param(
        [switch]$Break,
        [switch]$Continue,
        [Switch]$Return,
        [Switch]$Exit
    )
    Foreach ($Row in "ABCDEFGH".ToCharArray())
    {
        if ($Row -eq 'E')
        {
            If ($Break.IsPresent) {break}     # <- abort loop
            If ($Continue.IsPresent) {continue}  # <- skip just this iteration, but continue loop
            If ($Return.IsPresent) {return}    # <- abort code, and continue in caller scope
            If ($Exit.IsPresent) {exit}      # <- abort code at caller scope 
        }

        Write-Host "Row $Row"

    }
    Write-Host 'Done.'
}

Test-Function -Break
Write-Host "Done breaking"
Test-Function -Continue
Write-Host "Done continuing"
Test-Function -Return
Write-Host "Done returning"
Test-Function -Exit
Write-Host "Done Exiting"

Write-Host "End"