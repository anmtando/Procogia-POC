$Credential = Get-AutomationPSCredential -Name 'AutomationUser'
write-output $Credential
Connect-AzureRMAccount -Credential $Credential
$rg='da-dev-rg-sf-1'
$vmname='da-dev-vm-sf-2'
$storageaccountname='dadevsf1'
$cont='myscripts'
$Extensionname='CustomScript'
$vm = Get-AzureRMVM -Name $vmname -ResourceGroupName $rg
#write-output "Check Get Virtual Machine output $vm"
# Get the storage key
$key = (Get-AzureRMStorageAccountKey -Name $storageaccountname -ResourceGroupName $rg).value[0]
if (!$key) {
    write-output "Could not find a storage key"
    exit
}
#write-output "Check Storage Account Key output $key"
#
# check if there's an existing custom script extension
# if there is remove it - your only allowed one at a time
#
$extname = ($vm.Extensions | Where { $_.VirtualMachineExtensionType -eq 'CustomScript' }).name
if ($Extensionname) {
    write-output "removing existing extension: $extname"
    Remove-AzureRMVMExtension -name $Extensionname  -ResourceGroupName $rg  -VMName $vmname -force
    write-output "removed - waiting 10 seconds ...."
    start-sleep -Seconds 10
}
# get extension types
# for windows use:
# Get-AzureRmVMExtensionImage -Location westeurope -PublisherName Microsoft.Compute -Type CustomScriptExtension
# for Linux use:
# Get-AzureRmVMExtensionImage -Location "East US" -PublisherName "Microsoft.Azure.Extensions" -Type "CustomScript"
#
#
#For Linux:
#
# Setup for call to Set-AzureRmExtension
#
Get-AzureRmVMExtensionImage -Location "East US" -PublisherName "Microsoft.Azure.Extensions" -Type "CustomScript"
$TheURI = "https://dadevsf1.blob.core.windows.net/da-dev-vm-sf-2/sample.sh"
$Settings = @{"fileUris" = @($TheURI); "commandToExecute" = "./sample.sh"};
$ProtectedSettings = @{"storageAccountName" = $storageaccountname; "storageAccountKey" = $key};
#
Set-AzureRmVMExtension -ResourceGroupName $rg -Location $vm.location -VMName $vmname -Name "CustomScript" -Publisher "Microsoft.Azure.Extensions" -Type "CustomScript" -TypeHandlerVersion "2.0" -Settings $Settings -ProtectedSettings $ProtectedSettings
#
if ($?) {
  write-output "Set Extension OK"
  #
  # Get script extension output
  #
  $extout=((Get-AzureRMVM -Name $VMName -ResourceGroupName $RG -Status).Extensions | Where-Object {$_.Name -eq $ExtensionName}).statuses.Message
  #
  # Parse the stdout 
  #
  $stdout=$extout.substring($extout.indexof('[stdout]')+8,$extout.indexof('[stderr]')-$extout.indexof('[stdout]')-8)
  $stdout=$stdout.trim()
  write-output "stdout from command: $settings.commandToExecute"
  $stdout
  }
  else
  {
    write-output "set extension problem?"
  }
#
#