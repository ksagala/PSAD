function Get-DSDomainPasswordPolicy {
    <#
    .SYNOPSIS
    Retrieves default password policy for given domain.
    .DESCRIPTION
    Retrieves default password policy for given domain.
    .PARAMETER ComputerName
    Fully Qualified Name of a remote domain controller to connect to.
    .PARAMETER Credential
    Alternate credentials for retrieving domain information.
    .PARAMETER Identity
    Domain name to retreive.
    .EXAMPLE
    C:\PS> Get-DSDomainPasswordPolicy

    ComplexityEnabled           : True
    DistinguishedName           : DC=contoso,DC=com
    LockoutDuration             : 00:15:00
    LockoutObservationWindow    : 00:14:00
    LockoutThreshold            : 6
    MaxPasswordAge              : 90.00:00:00
    MinPasswordAge              : 7.00:00:00
    MinPasswordLength           : 8
    PasswordHistoryCount        : 24
    ReversibleEncryptionEnabled : False

    .OUTPUTS
    Object
    .NOTES
    Author: Zachary Loeber
    This does not account for any GPO driven default domain password policies.
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('Name','Domain','DomainName')]
        [string]$Identity = ($Script:CurrentDomain).name,

        [Parameter( Position = 1 )]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter( Position = 2 )]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    Begin {
        # Function initialization
        if ($Script:IsLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }

        if ($null -eq $Identity) {
            try {
                $Identity = (Get-DSDomain @DSParams).GetDirectoryEntry().distinguishedName
            }
            catch {
                throw
            }
        }

        <#
        ComplexityEnabled           : True
    DistinguishedName           : DC=contoso,DC=com
    LockoutDuration             : 00:15:00
    LockoutObservationWindow    : 00:14:00
    LockoutThreshold            : 6
    MaxPasswordAge              : 90.00:00:00
    MinPasswordAge              : 7.00:00:00
    MinPasswordLength           : 8
    PasswordHistoryCount        : 24
    ReversibleEncryptionEnabled : False
        #>
        $DomainProps = @(
            @{n='DistinguishedName';e={$_.DistinguishedName}},
            @{n='ComplexityEnabled';e={($_.pwdproperties -contains ('RequireComplexPasswords'))}},
            @{n='LockoutDuration';e={$_.lockoutduration}},
            @{n='LockoutObservationWindow';e={$_.lockoutobservationwindow}},
            @{n='LockoutThreshold';e={$_.lockoutthreshold}},
            @{n='MaxPasswordAge';e={$_.maxpwdage}},
            @{n='MinPasswordAge';e={$_.minpwdage}},
            @{n='MinPasswordLength';e={$_.minpwdlength}},
            @{n='PasswordHistoryCount';e={$_.pwdhistorylength}},
            @{n='ReversibleEncryptionEnabled';e={($_.pwdproperties -contains ('StorePasswordsInClearText'))}}
        )
    }

    process {
        try {
            Get-DSObject -Identity $Identity -SearchScope:Base @DSParams -IncludeAllProperties | Select $DomainProps
        }
        catch {
            throw
        }
    }
}
