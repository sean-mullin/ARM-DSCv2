#
# Lab-DCconfig.psd1
#
@{
    AllNodes = @(
        @{
            NodeName = "localhost"
            psdscallowplaintextpassword = $true
			psdscallowdomainuser = $true

			windowsfeaturepresent = @{name = 'AD-Domain-Services'; includesubfeatures = $true},
								    @{name = 'RSAT-ADDS'; includesubfeatures = $false}


			disksPresent = @{diskid = '2'; driveletter = 'f'}
			isdomaincontroller = $true


            }
    )
}