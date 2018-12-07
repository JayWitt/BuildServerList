$SubscriptionID = "<insert subscription ID here>"

#Get list of VM sizes of all valid commercial regions
$VMSizes = Get-AzurermLocation | where-object {$_.Providers -contains 'Microsoft.Compute'} | get-azurermvmsize | Sort-Object -Property Name -Unique

$Coretable = @{}
$Memtable = @{}

foreach ($key in $VMSizes){
    $vmsize = $key.Name
    $VMcores = $key.NumberOfCores
    $VMMem = $key.MemoryInMB
    $Coretable[$vmsize] = $VMcores
    $Memtable[$vmsize] = $VMMem / 1024
}


#Service List
$searchresults = Search-AzureRMGraph -Subscription $SubscriptionID -query "where type =~ 'Microsoft.Compute/virtualMachines' or type =~ 'Microsoft.Compute/virtualmachinescalsets' or type =~ 'microsoft.sql/servers/databases' or type =~ 'Microsoft.web/serverfarms' | extend ResourceType= case(type=='microsoft.compute/virtualmachines','VM',type=='microsoft.sql/servers/databases','Database',type=='microsoft.web/serverfarms','App Service Plan','Unknown') | extend VMSize=properties.hardwareProfile.vmSize | extend Image=properties.storageProfile.imageReference.sku | extend LicenseType= case(tostring(properties.licenseType)=='Windows_Server','AHUB','') | project tostring(name), tostring(resourceGroup), tostring(ResourceType), tostring(VMSize), tostring(Image), tostring(LicenseType), tostring(tags['appname'])" 

#Add in lookup table data
$searchresults | Select-Object @{Name="Name";Expression={$_.Name}},@{Name="ResourceGroup";Expression={$_.ResourceGroup}},@{Name="ResourceType";Expression={$_.ResourceType}},@{Name="VMSize";Expression={$_.VMSize}},@{Name="CoreCount";Expression={$Coretable[$_.VMSize]}},@{name="Memory";Expression={$memtable[$_.VMSize]}},@{Name="LicenseType";Expression={$_.LicenseType}},@{Name="AppName";Expression={$_.tags_appname}} | sort-object -property Resourcetype | ft




