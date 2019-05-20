configuration Main
{

    Param ( 
        [String]$DomainName,
        [PSCredential]$AdminCreds,
        [Int]$RetryCount = 30,
        [Int]$RetryIntervalSec = 120,
        [String]$ThumbPrint
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xActiveDirectory 
    Import-DscResource -ModuleName xStorage
    Import-DscResource -ModuleName xPendingReboot 
    Import-DscResource -ModuleName xComputerManagement

    [PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("$DomainName\$($AdminCreds.UserName)", $AdminCreds.Password)

    node $allnodes.nodename
    {
        Write-Verbose -Message $Nodename -Verbose

		#To clean up resource names use a regular expression to remove spaces, slashes an colons Etc.
        $StringFilter = "\W",""

        LocalConfigurationManager 
        {
            ActionAfterReboot    = 'ContinueConfiguration'
            ConfigurationMode    = 'ApplyandMonitor'
            RebootNodeIfNeeded   = $true
            AllowModuleOverWrite = $true
        }

		foreach($windowsfeature in $node.windowsfeaturepresent)
		{
			WindowsFeature $windowsfeature.name
			{            
			    Ensure               = "Present"
			    Name                 = $windowsfeature.name
				IncludeAllSubFeature = $windowsfeature.includesubfeatures
			}
			$dependsonwindowsfeature += @("[WindowsFeature]$($windowsfeature.name)")
		}
        
		foreach($disk in $node.disksPresent)
		{
			xDisk $disk.diskid 
			{
			    DiskID      = $disk.diskid
			    DriveLetter = $disk.driveletter
			}
			$dependsondisk += @("[xDisk]$($disk.diskid)")
		}

		if($node.isdomaincontroller)
		{
			xADDomain DC1 
			{
				DomainName                    = $DomainName
				DomainAdministratorCredential = $DomainCreds
				SafemodeAdministratorPassword = $DomainCreds
				DatabasePath                  = 'F:\NTDS'
				LogPath                       = 'F:\NTDS'
				SysvolPath                    = 'F:\SYSVOL'
				DependsOn                     = $dependsonwindowsfeature, $dependsondisk
			}
			
			xWaitForADDomain DC1 
			{
				DependsOn            = '[xADDomain]DC1'
				DomainName           = $DomainName
				RetryCount           = $RetryCount
				RetryIntervalSec     = $RetryIntervalSec
				DomainUserCredential = $DomainCreds
			}

			xADRecycleBin RecycleBin
			{
				EnterpriseAdministratorCredential = $DomainCreds
				ForestFQDN                        = $DomainName
				DependsOn                         = '[xWaitForADDomain]DC1'
			}

			xPendingReboot RebootforForestCreation 
			{
				Name      = 'RebootforForestCreation'
				DependsOn = '[xADDomain]DC1'
			}

			script setDNS
			{
				DependsOn = '[xADRecycleBin]RecycleBin'
				getscript = {
				   return @{
				   result = [string]$(netsh interface ip show config)}
					}
       
				setscript = {

					Write-Verbose "Setting Ethernet DNS to DHCP"
					netsh interface ip set dns "Ethernet" dhcp
					netsh interface ipv6 set dns "Ethernet" dhcp
				}
				testscript = {

					(Get-DnsClientServerAddress -InterfaceAlias Ethernet* -AddressFamily IPV4 | 
					Foreach {! ($_.ServerAddresses -contains '127.0.0.1')}) -notcontains $false
				}

			}
		} #close of if is domain controller statement
		else{
			xWaitForADDomain $domainname
			{
			    DomainName           = $DomainName
			    RetryCount           = $RetryCount
			    RetryIntervalSec     = $RetryIntervalSec
			    DomainUserCredential = $DomainCreds
			}
			xComputer localhost
			{
				Name                  = 'localhost' 
				DomainName            = $DomainName
				Credential            = $DomainCreds  
				DependsOn             = "[xWaitForADDomain]$domainname"

			}
			
			xPendingReboot RebootforPending 
			{
			    Name      = 'RebootforPending'
			    DependsOn = "[xComputer]localhost"
			}
		} #end of else
       
		foreach($directory in $node.directorypresent)
		{
			$name= $directory.destinationpath -replace $StringFilter
			file $name
			{
				Type = $directory.type
				Ensure = 'Present'
				DestinationPath = $directory.destinationpath
			}
			$dependsonfile += @("[file]$name")

		}

		foreach ($download in $node.webdownload)
		{
			xremotefile DownloadMsi
			{
			    DependsOn = $dependsonfile,'[xPendingReboot]RebootforPending'
				DestinationPath = $download.destinationpath
				Uri = $download.uri
			}
		}
    }#nodes
} #end main