#
# RGandKeyValut.ps1
#
$rgName = 'ARM-DSCv2'

$kVaultName = 'KVALBDSCusgovvirginia' #change for environment ie commercial or mag

$location = 'usgovvirginia' # change for environment, ensure the proper location for environment is here

$AdminUserName = 'Admin'



New-AzureRmResourceGroup -Name $rgName -Location $Location

Get-AzureRmResourceGroup -Name $rgName -Location $Location 



New-AzureRmKeyVault -ResourceGroupName $rgName -VaultName $kVaultName -Location $location -Sku premium -EnabledForTemplateDeployment

#Get-AzureRmKeyVault -VaultName contoso -ResourceGroupName rgglobal | Remove-AzureRmKeyVault



# ------- Above this line is required, below this line is optional



# You can also create Secrets/Credentials via the Visual Studio GUI at deployment time.

## You just need the KeyVault pre-created.



$Secret = Read-Host -AsSecureString -Prompt "Enter the Password for $AdminUserName"

Set-AzureKeyVaultSecret -VaultName $kVaultName -Name $AdminUserName -SecretValue $Secret -ContentType txt

#Set-AzureKeyVaultSecret -VaultName "Contoso" -Name "ITSecret" -SecretValue $Secret -Expires $Expires -NotBefore $NBF -ContentType $ContentType -Enable $True -Tags $Tags -PassThru



$ALBDSC = Get-AzureKeyVaultSecret -VaultName $kVaultName -Name $AdminUserName

$ALBDSC.Id

$ALBDSC.SecretValue      # SecureString

$ALBDSC.SecretValueText  # Text

$ALBDSC | gm

$ALBDSC | select *



# most recent key

# E.g. https://kvcontoso.vault.azure.net:443/secrets/ericlang



# specific version of key

# E.g. https://kvcontoso.vault.azure.net:443/secrets/ericlang/afa351084bba48449cc5deb984c7c4a1





# ------- Above this line is required, below this line is optional

# Save the storage account key in the keyvault
#
#$rgName = 'rgGlobal'
#
#$saname = 'sausgovvirginia'
#
#$SS = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgName -Name $saname)[1].value | ConvertTo-SecureString -AsPlainText -Force
#
#Set-AzureKeyVaultSecret -VaultName $kVaultName -Name StorageAccountKeySource -SecretValue $SS -ContentType txt