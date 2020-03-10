param(  $IncludeAuditLog    = $false,
        $IncludeEvent       = $false,
        $MyLogDir           = 'C:\ProgramData\Nimble Storage\Logs\',
        $username           = 'admin',
        $password           = 'admin',
        $ArrayIP            = '192.168.1.60'
     )    
process{
    $MyDumpDir = $MyLogDir
    $password2 = ConvertTo-SecureString $password -AsPlainText -Force # This is the Array Password, change admin to YOUR password
    ##############################################################################################################################
    $psCred = ( New-Object System.Management.Automation.PSCredential($username, $password2) )
    if ( -not (get-module -ListAvailable -name HPENimblePowerShellToolkit ) )
        {   Write-Error "You must first download the HPENimblePowerShelLToolkit from the Microsoft PSGallery to use this software."
            exit
        }   
    import-module -name HPENimblePowerShellToolkit
    connect-nsgroup -Group "$ArrayIP" -Credential $psCred -IgnoreServerCertificate
    if ( get-nsarray )  {   Write-warning "Connected to Array"
                        } else 
                        {   Write-Error "You must specify the correct IP address, username and Password to a Nimble Array"
                            exit
                        }
    $Global:NimbleSerial	    =	(Get-nsArray).serial
    if ( $(Get-NSGroup).FC_Enabled -like 'False' )    {   $FC_Enabled = $False
                                                    } else 
                                                    {   $FC_Enabled = $True
                                                    }
                    
function MakeA-Folder 
{   Param(  [Parameter(Mandatory = $True)]
            [String] $DirToMake
         )
    if (-not (Test-Path -LiteralPath $DirToMake)) 
        {   try     {   New-Item -Path ($DirToMake) -ItemType Directory -ErrorAction Stop | Out-Null #-Force
                    }
            catch   {   Write-Error -Message "Unable to create directory '$DirToMake'. Error was: $_" -ErrorAction Stop
                    }
        } 
}


function WriteA-File
{   param(  [Parameter(Mandatory = $True)]
            [String] $FileData,
            
            [Parameter(Mandatory = $True)]
            [String] $Id,

            [Parameter(Mandatory = $True)]
            [String] $Folder    
         )
    MakeA-Folder $Folder
    if (Test-Path -LiteralPath ($Folder+'\'+$Id+'.json') -pathtype leaf ) 
         {   try     {   Remove-Item -LiteralPath ($Folder+'\'+$Id+'.json') -Force -ErrorAction Stop | Out-Null
                     }
             catch   {   Write-Error -Message "Unable to overwrite/delete $Folder\$Id.json file. Error was: $_" -ErrorAction Stop
                     }
             Write-verbose "Successfully removed existing $Id.json file at $Folder."
         } 
    # write-host $FileData
    $action = New-Item -path $Folder -name ('\'+$Id+'.json') -value $FileData   

}
# These are all of the Subroutines to return the JSON. Subdivided to make troubleshooting simpler.
$SerDir=$MyDumpDir + $NimbleSerial + '\'
MakeA-Folder $SerDir
$DateDir=$SerDir+(get-date -format "MM-dd-yyyy_HH-mm-ss")+'\'
MakeA-Folder $DateDir
$MyDumpDir=$DateDir
write-host "Getting AccessControlRecord info: " -NoNewLine
MakeA-Folder $MyDumpDir'AccessControlRecord'
foreach($Data in Get-NSAccessControlRecord )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'AccessControlRecord')
}   write-host ""

write-host "Getting ActiveDirectoryMembership info: " -NoNewLine
MakeA-Folder $MyDumpDir'ActiveDirectoryMembership'
foreach($Data in Get-NSAccessControlRecord )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'ActiveDirectoryMembership') 
}   write-host ""

write-host "Getting Alarm info: " -NoNewLine
MakeA-Folder $MyDumpDir'Alarm'
foreach($Data in Get-NSAlarm )
{   WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'Alarm')
}   write-host ""

write-host "Getting ApplicationCategory info: " -NoNewLine
MakeA-Folder $MyDumpDir'ApplicationCategory'
foreach($Data in Get-NSApplicationCategory )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'ApplicationCategory')
}   write-host ""

write-host "Getting ApplicationServer info: " -NoNewLine
MakeA-Folder $MyDumpDir'ApplicationServer'
foreach($Data in Get-NSApplicationServer )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'ApplicationServer')
}   write-host ""

write-host "Getting Array info: " -NoNewLine
MakeA-Folder $MyDumpDir'Array'
foreach($Data in Get-NSArray )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'Array')
}   write-host ""

if( $IncludeAuditLog )
{   write-host "Getting AuditLog info: " -NoNewLine
    MakeA-Folder $MyDumpDir'AuditLog'
    foreach($Data in Get-NSAuditLog )
    {   write-host "." -nonewline
        WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'AuditLog')
    }
}   write-host ""

write-host "Getting Controller info: " -NoNewLine
MakeA-Folder $MyDumpDir'Controller'
foreach($Data in $( Get-NSController ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'Controller' )
}   write-host ""

write-host "Getting Disk info: " -NoNewLine
MakeA-Folder $MyDumpDir'Disk'
foreach($Data in $( Get-NSDisk ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'Disk' )
}   write-host ""

if( $IncludeEvent )
{   write-host "Getting Event info: " -NoNewLine
    MakeA-Folder $MyDumpDir'Event'
    foreach($Data in Get-NSEvent )
    {   write-host "." -nonewline
        WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'Event')
    }   
}   write-host ""

if ($FC_Enabled)
{   write-host "Getting FibreChannelConfig info: " -NoNewLine
    MakeA-Folder $MyDumpDir'FibreChannelConfig'
    foreach($Data in $( Get-NSFibreChannelConfig ) )
        {   WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'FibreChannelConfig' )
        }   write-host ""
    write-host "Getting FibreChannelInitiatorAlias info: " -NoNewLine
    MakeA-Folder $MyDumpDir'FibreChannelInitiatorAlias'
    foreach($Data in $( Get-NSFibreChannelInitiatorAlias ) )
    {   WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'FibreChannelInitiatorAlias' )
    }   write-host ""
    write-host "Getting FibreChannelInterface info: " -NoNewLine
    MakeA-Folder $MyDumpDir'FibreChannelInterface'
    foreach($Data in $( Get-NSFibreChannelInterface ) )
    {   WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'FibreChannelInterface' )
    }   write-host ""
    write-host "Getting FibreChannelPort info: " -NoNewLine
    MakeA-Folder $MyDumpDir'FibreChannelPort'
    foreach($Data in $( Get-NSFibreChannelPort ) )
    {   WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'FibreChannelPort' )
    }   write-host ""
    write-host "Getting FibreChannelSession info: " -NoNewLine
    MakeA-Folder $MyDumpDir'FibreChannelSession'
    foreach($Data in $( Get-NSFibreChannelSession ) )
    {   WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'FibreChannelSession' )
    }   write-host ""
} else
{   write-host "Getting ChapUser info: " -NoNewLine
    MakeA-Folder $MyDumpDir'ChapUser'
    foreach($Data in $( Get-NSChapUser ) )
        {    write-host "." -nonewline
            WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'ChapUser' )
        }
}   write-host ""

write-host "Getting Folder Info: " -NoNewLine
MakeA-Folder $MyDumpDir'Folder'
foreach($Data in $( Get-NSFolder ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'Folder' )
}   write-host ""

write-host "Getting Group Info: " -NoNewLine
MakeA-Folder $MyDumpDir'Group'
foreach($Data in $( Get-NSGroup ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'Group' )
}   write-host ""

write-host "Getting Initiator Info: " -NoNewLine
MakeA-Folder $MyDumpDir'Initiator'
foreach($Data in $( Get-NSInitiator ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'Initiator' )
}   write-host ""

write-host "Getting InitiatorGroup Info: " -NoNewLine
MakeA-Folder $MyDumpDir'InitiatorGroup'
foreach($Data in $( Get-NSInitiatorGroup ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'InitiatorGroup' )
}   write-host ""

write-host "Getting Job Info: " -NoNewLine
MakeA-Folder $MyDumpDir'job'
foreach($Data in $( Get-NSjob ) )
{   WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'job' )
}   write-host ""

write-host "Getting MasterKey Info: " -NoNewLine
MakeA-Folder $MyDumpDir'MasterKey'
foreach($Data in $( Get-NSMasterKey ) )
{   WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'MasterKey' )
}   write-host ""

write-host "Getting NetworkConfig Info: " -NoNewLine
MakeA-Folder $MyDumpDir'NetworkConfig'
foreach($Data in $( Get-NSNetworkConfig ) )
{   WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'NetworkConfig' )
}   write-host ""

write-host "Getting NetworkInterface Info: " -NoNewLine
MakeA-Folder $MyDumpDir'NetworkInterface'
foreach($Data in $( Get-NSNetworkInterface ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'NetworkInterface' )
}   write-host ""

write-host "Getting PerformancePolicy Info: " -NoNewLine
MakeA-Folder $MyDumpDir'PerformancePolicy'
foreach($Data in $( Get-NSPerformancePolicy ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'PerformancePolicy' )
}   write-host ""

write-host "Getting Pool Info: " -NoNewLine
MakeA-Folder $MyDumpDir'\Pool'
foreach($Data in $( Get-NSPool ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'Pool' )
}   write-host ""

write-host "Getting ProtectionSchedule Info: " -NoNewLine
MakeA-Folder $MyDumpDir'ProtectionSchedule'
foreach($Data in $( Get-NSProtectionSchedule ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'ProtectionSchedule' )
}   write-host ""

write-host "Getting ProtectionTemplate Info: " -NoNewLine
MakeA-Folder $MyDumpDir'ProtectionTemplate'
foreach($Data in $( Get-NSProtectionTemplate ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'ProtectionTemplate' )
}   write-host ""

write-host "Getting ProtocolEndpoint Info: " -NoNewLine
MakeA-Folder $MyDumpDir'ProtocolEndpoint'
foreach($Data in $( Get-NSProtocolEndpoint ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'ProtocolEndpoint' )
}   write-host ""

write-host "Getting ReplicationPartner Info: " -NoNewLine
MakeA-Folder $MyDumpDir'ReplicationPartner'
foreach($Data in $( Get-NSReplicationPartner ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'ReplicationPartner' )
}   write-host ""

write-host "Getting Shelf Info: " -NoNewLine
MakeA-Folder $MyDumpDir'Shelf'
foreach($Data in $( Get-NSShelf ) )
{   WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'Shelf' )
}   write-host ""

write-host "Getting SnapshotCollection Info: " -NoNewLine
MakeA-Folder $MyDumpDir'SnapshotCollection'
foreach($Data in $( Get-NSSnapshotCollection ) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'SnapshotCollection' )
}   write-host ""

write-host "Getting SoftwareVersion Info: " -NoNewLine
MakeA-Folder $MyDumpDir'SoftwareVersion'
foreach($Data in $( Get-NSSoftwareVersion -erroraction silentlycontinue) )
{   if ($data)
    {   write-host "." -nonewline
        WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.version) -Folder ($MyDumpDir+'SoftwareVersion' )
    }
}   write-host ""

write-host "Getting SpaceDomain Info: " -NoNewLine
MakeA-Folder $MyDumpDir'SpaceDomain'
foreach($Data in $( Get-NSSpaceDomain) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'SpaceDomain' )
}   write-host ""

write-host "Getting Subnet Info: " -NoNewLine
MakeA-Folder $MyDumpDir'Subnet'
foreach($Data in $( Get-NSSubnet) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'Subnet' )
}   write-host ""

write-host "Getting User Info: " -NoNewLine
MakeA-Folder $MyDumpDir'User'
foreach($Data in $( Get-NSUser) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'\User' )
}   write-host ""

write-host "Getting UserGroup Info: " -NoNewLine
MakeA-Folder $MyDumpDir'UserGroup'
foreach($Data in $( Get-NSUserGroup) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data.id) -Folder ($MyDumpDir+'\UserGroup' )
}   write-host ""

write-host "Getting Volume(V) & Snapshot(s) Info: " -NoNewLine
MakeA-Folder $MyDumpDir'Volume'
foreach($VolData in $( Get-NSVolume) )
{   WriteA-File -FileData ($VolData | ConvertTo-JSON -depth 10) -Id ($VolData.id) -Folder ($MyDumpDir+'Volume' ) 
    $FName = $MyDumpDir+'Volume\'+($VolData).id+'Snapshots'
    Write-host "V" -nonewline
    MakeA-Folder $FName
    foreach($SnapData in $( Get-NSSnapshot -vol_id ($VolData).id ) )
    {   WriteA-File -FileData ($SnapData | ConvertTo-JSON -depth 10) -Id ($SnapData).id -Folder $FName
        Write-host "s" -nonewline
    }
}   write-host ""

write-host "Getting VolumeCollection Info: " -NoNewLine
MakeA-Folder $MyDumpDir'VolumeCollection'
foreach($Data in $( Get-NSVolumeCollection) )
{   write-host "." -nonewline
    WriteA-File -FileData ($Data | ConvertTo-JSON -depth 10) -Id ($Data).id -Folder ($MyDumpDir+'VolumeCollection' )
}   write-host ""

}