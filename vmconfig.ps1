$username = "azureuser"
$Password = Read-Host "Enter VM password" -AsSecureString
$cred = New-Object System.Management.Automation.PSCredential($username, $Password)

$location = "switzerlandnorth"
$rg = "win11rg”
$VMName = "win11pc”
$size = ”Standard_B2s”
$publisher = "MicrosoftWindowsDesktop"
$offer = "windows-11"
$sku = "win11-22h2-entn" # ha Pro kell: "win11-22h2-pro"
$version = "latest"

New-AzResourceGroup -Location $location -Name $rg

$VnetName = "MyNet"
$NICName = "MyNIC"
$SubnetName = "MySubnet"
$SubnetCidr = "10.0.0.0/24"
$VnetCidr = "10.0.0.0/16"
$NSGName = "MyNSG"
$PipName = "MyPIP"

$vnet = New-AzVirtualNetwork -Name $VnetName -ResourceGroupName $rg -Location $location `
-AddressPrefix $VnetCidr
$vnet = Add-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet -AddressPrefix $SubnetCidr
$vnet = Set-AzVirtualNetwork -VirtualNetwork $vnet
$vnet = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $rg
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $SubnetName
$subnetId = $subnet.Id

$pip = New-AzPublicIpAddress -Name $PipName -ResourceGroupName $rg -Location $location `
-AllocationMethod Static -Sku Standard

$vnet = New-AzVirtualNetwork -Name $VnetName -ResourceGroupName $rg -Location $location `
-AddressPrefix $VnetCidr
$vnet = Add-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet -AddressPrefix $SubnetCidr
$vnet = Set-AzVirtualNetwork -VirtualNetwork $vnet
$vnet = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $rg
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $SubnetName
$subnetId = $subnet.Id

$nsg = New-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $rg -Location $location
$Params = @{
Name = 'allowRDP'
NetworkSecurityGroup = $nsg
Protocol = 'TCP'
Direction = 'Inbound'
Priority = 200
SourceAddressPrefix = '*'
SourcePortRange = '*'
DestinationAddressPrefix = '*'
DestinationPortRange = 3389
Access = 'Allow'
}

Add-AzNetworkSecurityRuleConfig @Params | Set-AzNetworkSecurityGroup | Out-Null

$nic = New-AzNetworkInterface -Name $NICName -ResourceGroupName $rg -Location $location -SubnetId $subnetId -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

$vm = New-AzVMConfig -VMName $vmName -VMSize $size |
Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred |
Set-AzVMSourceImage -PublisherName $publisher -Offer $offer -Skus $sku -Version $version |
Set-AzVMOSDisk -CreateOption FromImage -Name "$vmName-osdisk" -StorageAccountType Standard_LRS | Add-AzVMNetworkInterface -Id $nic.Id

New-AzVM -ResourceGroupName $rg -Location $location -VM $vm -Verbose






