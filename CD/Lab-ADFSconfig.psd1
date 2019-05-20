#
# Lab-ADFSconfig.psd1
#
@{
    AllNodes = @(
        @{
            NodeName = "localhost"
            psdscallowplaintextpassword = $true
			psdscallowdomainuser = $true

			windowsfeaturepresent = @{name = "ADFS-Federation"; includesubfeatures = $true}
            }
    )
}