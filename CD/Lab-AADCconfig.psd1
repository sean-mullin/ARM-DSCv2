#
# Lab-AADCconfig.psd1
#
@{
    AllNodes = @(
        @{
            NodeName = "localhost"
            psdscallowplaintextpassword = $true
			psdscallowdomainuser = $true

				
			directorypresent = @{type = 'directory';destinationpath = 'c:\aadc'}
			uri = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
		
		


		}
    )
}