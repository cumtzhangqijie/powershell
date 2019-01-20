<#-----------------------------------------------------------------#>
<# ���ܣ�                                                          #>
<# Ϊ Azure ���Ѿ����ڵ� load balancer ��ӵ� n ̨������         #>
<# ˵����                                                          #>
<# ���������޸ı��� vmIndex��prodNamePrefix��userName��          #>
<# sshPublicKey �� location �ȱ�����ֵ                             #>
<# �÷���                                                          #>
<# ֱ��ִ�нű� .\azureloadbalancer_addvm.ps1                      #>
<#-----------------------------------------------------------------#>

#*******************************************************************#
# ����ű�������ı���
#*******************************************************************#

# ����ӵ��������
$vmIndex = "3"
# ��Դ���Ƶ�ǰ׺
$prodNamePrefix = "Nick"
$lowerProdNamePrefix = $prodNamePrefix.ToLower()

# vm user name
$userName = "nick"
# vm user public key
$sshPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzO/q7SCCTdPou/Pj/IYyUXk1f1gQ5yhc1werRvivcSRDCnGPXnF3VaiuLdmXsbPscZBQ83wAs2rMZ8zEMDsSO+OGJcuQdJd7yuCfhwQ7ugasmhJ9PhxGK865HBY9iMJBE1cVyA6pZ2bKRLlNB375UB4NoFJkc4Nxsvpl0RunfD+YjupGDeFGrgGklgZAqb/DXY+zzvEIW6VUdWTpRYmP5DV6/hF4pBDB+ItA+eYi8BqJr8OSW/QUZsTe/9edOM1acHQi0HdZWpwSNT3xR75D4gGGdQOtRoj+EdapZtW3oUdkce3zKVWiMHq1dK601Lzz5UUU+VNRp4aKWP7AWHxp/ nick@u16os"

# resource loacation
$location = "japaneast"
# resource group name
$rgName = $prodNamePrefix + "LBGroup"
# virtual network infomation
$vnetName = $prodNamePrefix + "LBVNet"
$vnetPrefix = "10.0.0.0/16"
$subnetName = $prodNamePrefix + "LBSubNet"
$subnetPrefix = "10.0.0.0/24"
# load balancer name
$lbName = $prodNamePrefix + "LoadBalancer"

# Load Balancer Frontend ���õ�����
$frontendV4Name = "LBFrontendIPv4"
$frontendV6Name = "LBFrontendIPv6"

# Load Balancer Backend Poll ���õ�����
$backendAddressPoolV4Name = "LBBackendPoolIPv4"
$backendAddressPoolV6Name = "LBBackendPoolIPv6"

# Load Balancer Inbound NAT rules �������Ƶ�ǰ׺
$natRulexV4Name = "NatRule-SSH-VM" + $vmIndex

# Availability Set ����
$availabilitySetName = $prodNamePrefix + "LBAvailabilitySet"

# ��������������
$nicxName = $prodNamePrefix + "IPv4IPv6Nic" + $vmIndex

# �������
$vmSize = "Standard_B2s"
$vmVersion = "18.04-LTS"
#$userName = "nick"
$userPassword = "123456"
#$sshPublicKey = ""
$vmxName = $prodNamePrefix + "LBVM" + $vmIndex
$vmxDiskName = $prodNamePrefix + "LBVM" + $vmIndex + "_OsDisk"
$storageAccountTypeName = "Standard_LRS"
$vmxComputerHostName = $lowerProdNamePrefix + "lbvm" + $vmIndex
$frontendPort = $vmIndex + "0022"


#*******************************************************************#
# ��ȡ�������缰������������ʵ��
#*******************************************************************#

# ��ȡ���������ʵ��
$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName
# ��ȡ����������ʵ��
$backendSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet


#*******************************************************************#
# ��ȡ Load Balancer ���������Ե�ʵ��
#*******************************************************************#
$loadbalancer = Get-AzureRmLoadBalancer -Name $lbName -ResourceGroupName $rgName

# ��ȡ Load Balancer �� Backend pools ʵ��
$backendpoolipv4 = Get-AzureRmLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolV4Name -LoadBalancer $loadbalancer
$backendpoolipv6 = Get-AzureRmLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolV6Name -LoadBalancer $loadbalancer

# ��ȡ Load Balancer �� Frontend IP ʵ��
$FEIPConfigv4 = Get-AzureRmLoadBalancerFrontendIpConfig -Name $frontendV4Name -LoadBalancer $loadbalancer
$FEIPConfigv6 = Get-AzureRmLoadBalancerFrontendIpConfig -Name $frontendV6Name -LoadBalancer $loadbalancer

# �� Load Balancer ʵ��������µ� Inbound NAT rule
$loadbalancer | Add-AzureRmLoadBalancerInboundNatRuleConfig -Name $natRulexV4Name -FrontendIPConfiguration $FEIPConfigv4 -Protocol TCP -FrontendPort $frontendPort -BackendPort 22


#*******************************************************************#
# ���ƶ˸��� Load Balancer ʵ��
#*******************************************************************#

# ���ƶ˸��� Load Balancer ʵ��
$loadbalancer | Set-AzureRmLoadBalancer

# ��ø��º�� Load Balancer ʵ��
$loadbalancer = Get-AzureRmLoadBalancer -Name $lbName -ResourceGroupName $rgName
$inboundNATRulev4 = Get-AzureRmLoadBalancerInboundNatRuleConfig -Name $natRulexV4Name -LoadBalancer $loadbalancer


#*******************************************************************#
# ������������
#*******************************************************************#
$nicIPv4 = New-AzureRmNetworkInterfaceIpConfig -Name "IPv4IPConfig" -PrivateIpAddressVersion "IPv4" -Subnet $backendSubnet -LoadBalancerBackendAddressPool $backendpoolipv4 -LoadBalancerInboundNatRule $inboundNATRulev4
$nicIPv6 = New-AzureRmNetworkInterfaceIpConfig -Name "IPv6IPConfig" -PrivateIpAddressVersion "IPv6" -LoadBalancerBackendAddressPool $backendpoolipv6
$nic = New-AzureRmNetworkInterface -Name $nicxName -IpConfiguration $nicIPv4,$nicIPv6 -ResourceGroupName $rgName -Location $location


#*******************************************************************#
# ����������������½��� NIC
#*******************************************************************#

# ��ȡ Availability Set
$availabilitySet = Get-AzureRmAvailabilitySet -Name $availabilitySetName -ResourceGroupName $rgName

# �����û� Credential
$securePassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
$userCred = New-Object System.Management.Automation.PSCredential ($userName, $securePassword)

# �������
$vm = New-AzureRmVMConfig -VMName $vmxName -VMSize $vmSize -AvailabilitySetId $availabilitySet.Id
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Linux -ComputerName $vmxComputerHostName -Credential $userCred -DisablePasswordAuthentication
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName Canonical -Offer UbuntuServer -Skus $vmVersion -Version "latest"
$vm = Set-AzureRmVMBootDiagnostics -VM $vm -Disable
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id -Primary
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $vmxDiskName -CreateOption FromImage -StorageAccountType $storageAccountTypeName
Add-AzureRmVMSshPublicKey -VM $vm -KeyData $sshPublicKey -Path "/home/$userName/.ssh/authorized_keys"
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm

Write-Host "Adding VM to Load Balancer is completed."