# Azure Virtual Data Centre Lab

# Contents

**[VDC Lab Introduction](#intro)**

**[Initial Lab Setup](#setup)**

**[Lab 1: Explore the VDC Environment](#explore)**

**[Lab 2: Configure the VDC Infrastructure](#configure)**

- [2.1: Configure site-to-site VPN](#vpn)

- [2.2: Configure Cisco CSR1000V](#cisco)

- [2.3: Configure User Defined Routes](#udr)

- [2.4: Test Connectivity Between On-Premises and Spoke VNets](#testconn)

**[Lab 3: Secure the VDC Environment](#secure)**

- [3.1: Network Security Groups](#nsgsec)

**[Lab 4: Monitor the VDC Environment](#monitor)**

- [4.1: Enable Network Watcher](#netwatcher)

- [4.2: NSG Flow Logs](#nsgflowlogs)

- [4.3: Tracing Next Hop Information](#nexthop)



**[Decommission the lab](#decommission)**

**[Conclusion](#conclusion)**

**[Useful References](#ref)**

# VDC Lab Introduction <a name="intro"></a>

This lab guide allows the user to deploy and test a complete Microsoft Azure Virtual Data Centre (VDC) environment. A VDC is not a specific Azure product; instead, it is a combination of features and capabilities that are brought together to meet the requirements of a modern application environment in the cloud. This lab currently focuses on the networking and security elements of a VDC, however the plan is that this will be expanded over time to include other areas, such as identity.

More information on VDCs can be found at the following link:

[https://docs.microsoft.com/en-us/azure/networking/networking-virtual-datacenter]

Before proceeding with this lab, please make sure you have fulfilled all of the following prerequisites:

- A valid subscription to Azure. If you don't currently have a subscription, consider setting up a free trial (https://azure.microsoft.com/en-gb/free/)
- Access to the Azure CLI 2.0. You can achieve this in one of two ways: either by installing the CLI on the Windows 10 Bash shell (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli), or by using the built-in Cloud Shell in the Azure portal - you can access this by clicking on the ">_" symbol in the top right corner of the portal.

# Initial Lab Setup <a name="setup"></a>

**Important: The initial lab setup using ARM templates takes around 45 minutes - please initiate this process as soon as possible to avoid a delay in starting the lab.**

*All usernames and passwords for virtual machines (including Cisco CSR routers) are set to labuser / M1crosoft123*

Perform the following steps to initialise the lab environment:

**1)** Open an Azure CLI session, either using a local machine (e.g. Windows 10 Bash shell), or using the Azure portal cloud shell. If you are using a local CLI session, you must log in to Azure using the *az login* command as follows:

<pre lang="...">
az login
To sign in, use a web browser to open the page https://aka.ms/devicelogin and enter the code XXXXXXXXX to authenticate.
</pre>

The above command will provide a code as output. Open a browser and navigate to aka.ms/devicelogin to complete the login process.

**2)** Use the Azure CLI to create two resource groups: *VDC-Main* and *VDC-NVA*. Note that th.e resource groups *must* be named exactly as shown here to ensure that the ARM templates deploy correctly. Use the following CLI commands to achieve this:

<pre lang="...">
az group create -l westeurope -n VDC-Main
az group create -l westeurope -n VDC-NVA
</pre>

**3)** Once the resource groups have been deployed, you can deploy the lab environment into these using a set of pre-defined ARM templates. The templates are available at https://github.com/Araffe/vdc-networking-lab if you wish to learn more about how the lab is defined. Essentially, a single master template (*VDC-Networking-Master.json*) is used to call a number of other templates, which in turn complete the deployment of virtual networks, virtual machines, load balancers, availability sets, VPN gateways and third party (Cisco) network virtual appliances (NVAs). The templates also deploy a simple Node.js application on the spoke virtual machines. Use the following CLI command to deploy the template:

<pre lang="...">
az group deployment create --name VDC-Create -g VDC-Main --template-uri https://raw.githubusercontent.com/Araffe/vdc-networking-lab/master/VDC-Networking-Master.json
</pre>

The template deployment process will take approximately 45 minutes. You can monitor the progress of the deployment from the portal (navigate to the *VDC-Main* resource group and click on *Deployments* at the top of the Overview blade). Alternatively, the CLI can be used to monitor the template depoyment progress as follows:

<pre lang="...">
<b>az group deployment list -g VDC-Main -o table</b>
Name                Timestamp                         State
------------------  --------------------------------  ---------
vnets               2017-07-28T08:37:55.961882+00:00  Succeeded
Hub-Spoke3-Peering  2017-07-28T08:38:21.404605+00:00  Succeeded
Hub-Spoke2-Peering  2017-07-28T08:38:22.934825+00:00  Succeeded
Hub-Spoke1-Peering  2017-07-28T08:38:35.888680+00:00  Succeeded
createSpoke1VMs     2017-07-28T08:44:16.048346+00:00  Succeeded
createSpoke2VMs     2017-07-28T08:44:31.623084+00:00  Succeeded
createOnPremVM      2017-07-28T08:44:49.999502+00:00  Succeeded
Hub_GW1             2017-07-28T09:13:14.553300+00:00  Succeeded
OnPrem_GW1          2017-07-28T09:14:27.922243+00:00  Succeeded
VDC-Create          2017-07-28T09:14:44.088006+00:00  Succeeded
</pre>

Once the template deployment has succeeded, you can proceed to the next sections of the lab.

# Lab 1: Explore VDC Environment <a name="explore"></a>

In this section of the lab, we will explorer the environment that has been deployed to Azure by the ARM templates. The lab environment has the following topology:

![Main VDC Image](https://github.com/araffe/vdc-networking-lab/blob/master/VDC-Networking-Main.jpg "VDC Environment")

**Figure 1:** VDC Lab Environment

**1)** Use the Azure portal to explore the resources that have been created for you. Navigate to the resource group *VDC-Main* to get an overall view of the resources deployed:

![Main VDC Resource Group Image](https://github.com/Araffe/vdc-networking-lab/blob/master/VDC-Main-RG.JPG "VDC-Main Resource Group")

**Figure 2:** VDC-Main Resource Group View

**Tip**: Select 'group by type' on the top right of the resource group view to group the resources together.

**2)** Under the resource group *VDC-Main*, look at each of the virtual networks and the subnets created within each one. You will notice that *Hub_Vnet* and *OnPrem_VNet* have an additional subnet called *GatewaySubnet* - this is a special subnet used for the VPN gateway.

**3)** Navigate to the *Spoke1-LB* load balancer. From here, navigate to 'Backend Pools' - you will see that both virtual machines are configured as part of the back end pool for the load balancer, as shown in figure 3.

![LB Backend Pools](https://github.com/Araffe/vdc-networking-lab/blob/master/BackendPools.JPG "LB Backend Pools")

**Figure 3:** Load Balancer Backend Pools View

**4)** Under the load balancer, navigate to 'Load Balancing Rules'. Here, you will see that we have a single rule configured (*DemoAppRule*) that maps incoming HTTP requests to port 3000 on the backend (our simple Node.js application listens on port 3000).

**5)** Navigate to the virtual network named *Hub_Vnet* in the *VDC-Main* resource group and then select 'Peerings'. Notice that the hub virtual network has VNet peerings configured with each of the spoke VNets.

![VNet Peerings](https://github.com/Araffe/vdc-networking-lab/blob/master/VNet-Peerings.JPG "VNet Peerings")

**Figure 4:** Virtual Network Peerings

**6)** Navigate to the *VDC-NVA* resource group. Under this resource group, you will see that a single network virtual appliance - a Cisco CSR1000V - has been deployed with two NICs, a storage account, a public IP address and a Network Security Group. Deployment of an NVA requires a new empty resource group, hence the reason for the additional group here.

Now that you are familiar with the overall architecture, let's move on to the next lab where you will start to add some additional configuration.

# Lab 2: Configure the VDC Infrastructure <a name="configure"></a>

## 2.1: Configure Site-to-site VPN <a name="vpn"></a>

In our VDC environment, we have a hub virtual network (used as a central point for control and inspection of ingress / egress traffic between different zones) and a virtual network used to simulate an on-premises environment. In order to provide connectivity between the hub and on-premises, we will configure a site-to-site VPN. The VPN gateways required to achieve this have already been deployed, however they must be configured before traffic will flow. Follow the steps below to configure the site-to-site VPN connection.

**1)** Using the Azure CLI (either local or using the Azure Cloud Shell), enter the following to create one side of the VPN connection:

<pre lang="...">
az network vpn-connection create --name Hub2OnPrem -g VDC-Main --vnet-gateway1 Hub_GW1 --vnet-gateway2 OnPrem_GW1 --shared-key M1crosoft123 --enable-bgp
</pre>

**2)** Use the Azure CLI to create the other side of the VPN connection:

<pre lang="...">
az network vpn-connection create --name OnPrem2Hub -g VDC-Main --vnet-gateway1 OnPrem_GW1 --vnet-gateway2 Hub_GW1 --shared-key M1crosoft123 --enable-bgp
</pre>

**3)** Using the Azure portal, under the resource group *VDC-Main* navigate to the *OnPrem_GW1* virtual network gateway resource and then click 'Connections'. You should see a successful VPN connection between the OnPrem and Hub VPN gateways.

**Note:** It may take a few minutes before a successful connection is shown between the gateways.

At this point, we can start to verify the connectivity we have set up. One of the ways we can do this is by inspecting the *effective routes* associated with a virtual machine. Let's take a look at the effective routes associated with the *OnPrem_VM1* virtual machine that resides in the OnPrem VNet.

**4)** Using the Azure portal, navigate to the *OnPrem_VM1-nic* object under the VDC-Main resource group. This object is the network interface associated with the OnPrem_VM virtual machine.

**5)** Under 'Support + Troubleshooting', select 'Effective Routes'. You should see two entries for 'virtual network gateway', one of which specifies an address range of 10.101.0.0/16, as shown in figure 5.

![Effective Routes](https://github.com/Araffe/vdc-networking-lab/blob/master/EffectiveRoutes1.JPG "Effective Routes")

**Figure 5:** OnPrem_VM Effective Routes

Figure 6 shows a diagram explaining what we see when we view the effective routes of OnPrem_VM.

![Routing from OnPrem_VM](https://github.com/Araffe/vdc-networking-lab/blob/master/EffectiveRoutes2.jpg "Routing from OnPrem_VM")

**Figure 6:** Routing from OnPrem_VM

Next, let's move on to configuring our Cisco Network Virtual Appliances.

## 2.2: Configure Cisco CSR1000V <a name="cisco"></a>

One of the requirements of many enterprise organisations is to provide a secure perimeter or DMZ environment using third party routers or firewall devices. Azure allows for this requirement to be met through the use of third party Network Virtual Appliances (NVAs). An NVA is essentially a virtual machine that runs specialised software, typically from a network equipment manufacturer, and that provides routing or firewall functionality within the Azure environment.

In our VDC environment, we are using Cisco CSR1000V routers in the Hub virtual network - CSR stands for *Cloud Services Router* and is a virtualised Cisco router running IOS-XE software. The CSR1000V is a fully featured Cisco router that supports most routing functionality, such as OSPF and BGP routing, IPSec VPNs and Zone Based Firewalls.

The ARM templates used to deploy our VDC environment provisioned the CSR1000V router in the Hub virtual network, however it must now be configured in order to route traffic. Follow the steps in this section to configure the CSR1000V.

**1)** To log on to the CSR1000V, you'll need to obtain the public IP address assigned to it. You can obtain this using the Azure portal (navigate to the *VDC-NVA* resource group and inspect the object named 'csr1-pip'). Alternatively, you can use the Azure CLI to obtain the public IP address, as follows:

<pre lang="...">
<b>az network public-ip list -g VDC-NVA -o table</b>
  IpAddress      Location     Name     ProvisioningState    PublicIpAllocationMethod    ResourceGroup
  ------------  -----------  --------  ------------------  ------------------------     ---------------
 40.68.197.125  westeurope   csr1-PIP   Succeeded           Dynamic                      VDC-NVA
 </pre>
 
**2)** Now that you have the public IP address, SSH to the CSR1000V VM using your favourite terminal emulator (e.g. Putty or similar). The username and password for the CSR are *labuser / M1crosoft123*.

**3)** Enter configuration mode on the CSR:

<pre lang="...">
conf t
 </pre>

**4)** The CSR1000V has two interfaces - one connected to Hub_VNet-Subnet1 and the other connected to Hub_VNet-Subnet2. We want to ensure that these interfaces are configured using DHCP, so use the following CLI config to ensure that this is the case and that the interfaces are both in the 'up' state:

<pre lang="...">
vdc-csr-1(config)#interface gig1
vdc-csr-1(config-if)#ip address dhcp
vdc-csr-1(config-if)#no shut
vdc-csr-1(config)#interface gig2
vdc-csr-1(config-if)#ip address dhcp
vdc-csr-1(config-if)#no shut
vdc-csr-1(config-if)#exit
vdc-csr-1(config)#exit
 </pre>

**5)** Verify that the interfaces are up and configured with an IP address as follows:

<pre lang="...">
vdc-csr-1#show ip interface brief
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet1       10.101.1.4      YES DHCP   up                    up
GigabitEthernet2       10.101.2.4      YES DHCP   up                    up
</pre>

**Note:** At this point, you may be wondering why we are using DHCP to configure router interfaces (given that other devices use the interfaces to route to and they therefore must be consistent). The answer is that we have configured static addresses in Azure (essentially DHCP reservations) to ensure that the network interfaces will always receive a statically configured IP address.

**6)** Find the public IP address of the virtual machine named *OnPrem_VM* using the following command:

<pre lang="...">
az network public-ip list -g VDC-Main -o table
</pre>

**7)** SSH to the public IP of OnPrem_VM. From within the VM, attempt to connect to the private IP address of one of the CSR1000V interfaces (10.101.1.4):

<pre lang="...">
ssh labuser@10.101.1.4
</pre>

This step should succeed, which proves connectivity between the On Premises and Hub VNets using the VPN connection. Figure 7 shows the connection we have just made.

![SSH to NVA](https://github.com/Araffe/vdc-networking-lab/blob/master/SSHtoNVA.jpg "SSH to NVA")

**Figure 6:** SSH from OnPrem_VM to vdc-csr-1

**8)** From the same VM, attempt to connect to the private IP address of a virtual machine within the Spoke 1 Vnet:

<pre lang="...">
ssh labuser@10.1.1.5
</pre>

This attempt will fail - the reason for this is that we do not yet have the correct routing in place to allow connectivity between the On Premises VNet and the Spoke VNets via the hub / NVA. In the next section, we will configure the routing required to achieve this.

## 2.3: Configure User Defined Routes <a name="udr"></a>

In this section, we will configured a number of *User Defined Routes*. A UDR in Azure is a routing table that you as the user define, potentially overriding the default routing that Azure sets up for you. UDRs are generally required any time a Network Virtual Appliance (NVA) is deployed, such as the Cisco CSR router we are using in our lab. The goal of this exercise is to allow traffic to flow from VMs residing in the Spoke VNets, to the VM in the On Premises VNet. This traffic will flow through the Cisco CSR router in the Hub VNet. The diagram in figure 7 shows what we are trying to achieve in this section.

![User Defined Routes](https://github.com/Araffe/vdc-networking-lab/blob/master/UDR.jpg "User Defined Routes")

**Figure 7:** User Defined Routes

We'll create our first User Define Route using the Azure portal, with subsequent UDRs configured using the Azure CLI.

**1)** In the Azure portal, navigate to the *VDC-Main* resource group. Click 'Add' and then search for 'Route Table'. Select this and then create a new route table named *OnPrem-UDR*. Once complete, navigate to the newly created UDR in the VDC-Main resource group and select it.

**2)** Click on 'Routes' and then 'Add'. Create a new route with the following parameters:

- Route Name: *Spoke1-Route*
- Address Prefix: *10.1.0.0/16*
- Next Hop Type: *Virtual Network Gateway*

Click 'Submit' to create the route. Repeat the process for Spoke 2 as follows:

- Route Name: *Spoke2-Route*
- Address Prefix: *10.2.0.0/16*
- Next Hop Type: *Virtual Network Gateway*

Figure 8 shows the route creation screen.

![Defining UDRs](https://github.com/Araffe/vdc-networking-lab/blob/master/UDR2.jpg "Defining UDRs")

**Figure 8:** Defining UDRs

**3)** We now need to associate the UDR with a specific subnet. Click on 'Subnets' and then 'Associate'. Select the VNet 'OnPrem\_Vnet' and then the subnet 'OnPrem\_Vnet-Subnet1'. Click OK to associate the UDR to the subnet.

We'll now switch to the Azure CLI to define the rest of the UDRs that we need.

**4)** Create the UDR for the Hub Vnet (GatewaySubnet):

<pre lang="...">
az network route-table create --name Hub_UDR -g VDC-Main
</pre>

**5)** Create the routes to point to Spoke1 and Spoke2, via the Cisco CSR router:

<pre lang="...">
az network route-table route create --name Spoke1-Route --address-prefix 10.1.0.0/16 --next-hop-type VirtualAppliance --next-hop-ip-address 10.101.1.4 --route-table-name Hub_UDR -g VDC-Main
az network route-table route create --name Spoke2-Route --address-prefix 10.2.0.0/16 --next-hop-type VirtualAppliance --next-hop-ip-address 10.101.1.4 --route-table-name Hub_UDR -g VDC-Main
</pre>

**6)** Associate the UDR with the GatewaySubnet inside the Hub Vnet:

<pre lang="...">
az network vnet subnet update --name Hub_Vnet-Subnet1 --vnet-name Hub_Vnet --route-table Hub_UDR -g VDC-Main
</pre>

**7)** Configure the UDRs for the Spoke VNets, with relevant routes and associate to the subnets:

<pre lang="...">
az network route-table create --name Spoke1_UDR -g VDC-Main
az network route-table create --name Spoke2_UDR -g VDC-Main

az network route-table route create --name OnPrem-Route --address-prefix 10.102.0.0/16 --next-hop-type VirtualAppliance --next-hop-ip-address 10.101.2.4 --route-table-name Spoke1_UDR -g VDC-Main
az network route-table route create --name OnPrem-Route --address-prefix 10.102.0.0/16 --next-hop-type VirtualAppliance --next-hop-ip-address 10.101.2.4 --route-table-name Spoke2_UDR -g VDC-Main

az network vnet subnet update --name Spoke_VNet1-Subnet1 --vnet-name Spoke_Vnet1 --route-table Spoke1_UDR -g VDC-Main
az network vnet subnet update --name Spoke_VNet2-Subnet1 --vnet-name Spoke_Vnet2 --route-table Spoke2_UDR -g VDC-Main
</pre>

Great, everything is in place - we are now ready to test connectivity between our on-premises environment and the Spoke VNets.

## 2.4: Test Connectivity Between On-Premises and Spoke VNets <a name="testconn"></a>

In this section, we'll perform some simple tests to validate connectivity between our "on-premises" environment and the Spoke VNets - this communication should occur through the Cisco CSR router that resides in the Hub VNet.

**1)** SSH into the virtual machine named *OnPrem-VM1* as you did earlier.

**2)** From within this VM, attempt to SSH to the first virtual machine inside the Spoke 1 virtual network (e.g. with an IP address of 10.1.1.6):

<pre lang="...">
ssh labuser@10.1.1.6
</pre>

Although we have all the routing we need configured, this connectivity is still failing. Why?

It turns out that there is an additional setting we must configure on the VNet peerings to allow this type of hub and spoke connectivity to happen. Follow these steps to make the required changes:

**3)** In the Azure portal, navigate to *Spoke_VNet1* in the 'VDC-Main' resource group. Select 'peerings' and then select the 'to-Hub_Vnet' peering. You'll see that the option entitled *Use Remote Gateways* is unchecked. Checking this option allows the VNet to use a gateway in a *remote* virtual network - as we need our Spoke VNets to use a gateway residing in the Hub VNet, this is exactly what we need, so check the box as shown in figure 9.

![Use Remote GW](https://github.com/Araffe/vdc-networking-lab/blob/master/UseRemoteGW.JPG "Use Remote GW")

**Figure 9:** Use Remote Gateway Option

**4)** From within the OnPrem_VM1 virtual machine, try to SSH to the Spoke VM once more. The connection attempt should now succeed.

**5)** Configure the Spoke 2 VNet peering with 'Use Remote Network Gateway' and then attempt to connect to one of the virtual machines in Spoke 2 (e.g. 10.2.1.6). This connection should also now succeed.

**6)** Still from the OnPrem_VM machine, use the curl command to make an HTTP request to the load balancer private IP address in Spoke1. Note that the IP address *should* be 10.1.1.5, however you may need to verify this in the portal or CLI:

<pre lang="...">
curl http://10.1.1.5
</pre>

This command should return an HTML page showing some information, such as the page title, the hostname, system info and whether the application is running inside a container or not.

If you try the same request a number of times, you may notice that the response contains either *Spoke1-VM1* or *Spoke1-VM2* as the hostname, as the load balancer has both of these machines in the backend pool.

In the next section, we will lock down the environment to ensure that our On Premises user can only reach the required services.

# Lab 3: Secure the VDC Environment <a name="secure"></a>

In this section of the lab, we will use a number of mechanisms to further secure the virtual data centre environment. We will use the following two options to secure traffic from our On Premises virtual network to the applications running on our spoke VNets:

- Traffic filtering / firewalling at the NVA level (in our case the Cisco CSR router) within the Hub VNet.
- Azure Network Security Groups.

## 3.1: Network Security Groups <a name="nsgsec"></a>

At the moment, our user in the On Premises VNet is potentially able to access the Spoke 1 & 2 virtual machines on any TCP port - for example, SSH. We want to use Azure Network Security Groups (NSGs) to prevent traffic on any port other than HTTP and port 3000 (the port the application runs on) being allowed into our Spoke VNets.

An NSG is a list of user=defined security rules that allows or denies traffic on specific ports, or to / from specific IP address ranges. An NSG can be applied at two levels: at the virtual machine NIC level, or at a subnet level.

Our NSG will define two rules - one for HTTP and another for TCP port 3000. This NSG will be applied at the subnet level.

**1)** In the Azure portal under the resource group VDC-Main, click 'Add' and search for 'Network Security Group'. Create a new NSG named *Spoke-NSG*.

**2)** Navigate to the newly created NSG and select it. Select 'Inbound Security Rules'. Click 'Add' to add a new rule. Use the following parameters:

- Name: *Allow-http*
- Priority: *100*
- Source port range: *Any*
- Destination port range: *80*
- Action: *Allow*

![NSG Rule1](https://github.com/Araffe/vdc-networking-lab/blob/master/NSG1.jpg "NSG Rule1")

**Figure 10:** Network Security Group - HTTP Rule

**3)** Add another rule with the following parameters:

- Name: *Allow-3000*
- Priority: *110*
- Source port range: *Any*
- Destination port range: *3000*
- Action: *Allow*

**4)** Add one more rule with the following parameters:

- Name: *Deny-All*
- Priority: *120*
- Source port range: *Any*
- Destination port range: *Any*
- Action: *Deny*

**5)** Select 'Subnets'. Click the 'Associate' button and choose 'Spoke_VNet1' and 'Spoke\_VNet1-Subnet1'.

![NSG Associate Subnet](https://github.com/Araffe/vdc-networking-lab/blob/master/NSG1.jpg "NSG Associate Subnet")

**Figure 11:** Network Security Group - Associating with a Subnet

**6)** SSH into the OnPrem-VM1 virtual machine from your terminal emulator. From this VM, attempt to SSH to the first Spoke1 VM:

<pre lang="...">
ssh labuser@10.1.1.6
</pre>

This connection attempt will fail due to the NSG now associated with the Spoke1 subnet.

**7)** From OnPrem_VM1, make sure you can still access the demo app:

<pre lang="...">
curl http://10.1.1.5
</pre>

You might wonder why the third rule denying all traffic is required in this example. The reason for this is that a default rule exists in the NSG that allows all traffic from every virtual network. Therefore, without the specific 'Deny-All' rule in place, all traffic will succeed (in other words, the NSG will have no effect). You can see the default rules by clicking on 'Default Rules' under the security rules view.

# Lab 4: Monitor the VDC Environment <a name="monitor"></a>

In this section, we will explore some of the monitoring options we have in Azure and how those can be used to troubleshoot and diagnose issues in a VDC environment. The first tool we will look at is *Network Watcher*. Network Watcher is a collection of tools available to monitor and troubleshoot issues with network connectivity in Azure, including packet capture, NSG flow logs and IP flow verify.

## 4.1: Enabling Network Watcher <a name="netwatcher"></a>

Before we can use the tools in this section, we must first enable Network Watcher. To do this, follow these steps:

**1)** In the Azure portal, expand the left hand menu and then click *More Services*. In the filter bar, type 'Network Watcher' and then click on the Network Watcher service.

**2)** You should see your Azure subscription listed in the right hand pane - find your region and then click on the'...' on the right hand side. Click 'Enable Network Watcher':

![Enabling Network Watcher](https://github.com/Araffe/vdc-networking-lab/blob/master/NetWatcher1.jpg "Enabling Network Watcher")

**Figure 11:** Enabling Network Watcher

**3)** On the left hand side of screen under 'Monitoring', click on 'Topology'. Select your subscription and then the resorce group 'VDC-Main' and 'Hub_Vnet'. You will see a graphical representation of the topology on the screen:

![Network Topology](https://github.com/Araffe/vdc-networking-lab/blob/master/NetWatcher1.jpg "Network Topology")

**Figure 11:** Network Topology View in Network Watcher

**4)** A useful feature of Network Watcher is the ability to view network related subscription limits and track your resource utilisation against these. In the left hand menu, select 'Network Subscription Limit'. You will see a list of resources, including virtual networks, public IP addresses and more:

![Network Subscription Limits](https://github.com/Araffe/vdc-networking-lab/blob/master/SubLimits.jpg "Network Subscription Limits")

**Figure 12:** Network Related Subscription Limits

## 4.2: NSG Flow Logs <a name="nsgflowlogs"></a>

Network Security Group (NSG) Flow Logs are a feature of Network Watcher that allows you to view information about traffic flowing through a NSG. The logs are written in JSON format and are stored in an Azure storage account that you must designate. In this section, we will enable flow logging for the NSG we configured in the earlier lab and inspect the results.

**1)** To begin with, we need to create a storage account to store the NSG flow logs. Use the following CLI to do this, substituting the storage account name for a unique name of your choice:

<pre lang="...">
az storage account create --name <storage-account-name> -g VDC-Main --sku Standard_LRS
</pre>

**2)** Use the Azure portal to navgiate to the Network Watcher section (expand left menu, select 'More Services' and search for 'Network Watcher'). Select 'NSG Flow Logs' from the Network Watcher menu. Filter using your subscription and Resource Group at the top of the page and you should see the NSG we created in the earlier lab.

**3)** Click on the NSG and then in the settings screen, change the status to 'On'. Select the storage account you created in step 1 and change the retention to 5 days. Click 'Save'.

![NSG Flow Log Settings](https://github.com/Araffe/vdc-networking-lab/blob/master/FlowLogs1.jpg "NSG Flow Log Settings")

**Figure 13:** NSG Flow Log Settings

**4)** In order to view data from the NSG logs, we must initiate some traffic that will flow through the NSG. SSH to the OnPrem_VM virtual machine as described earlier in the lab. From here, use the curl command to view the demo app on Spoke1\_VM1 and attempt to SSH to the same VM (this will fail):

<pre lang="...">
curl http://10.1.1.5
ssh labuser@10.1.1.6
</pre>

**5)** NSG Flow Logs are stored in the storage account you configured earlier in this section - in order to view the logs, you must download the JSON file from Blob storage. You can do this either using the Azure portal, or using the *Microsoft Azure Storage Explorer* program available as a free download from http://storageexplorer.com/. If using the Azure portal, navigate to the storage account you created earlier and select 'Blobs'. You will see a container named 'insights-logs-networksecuritygroupflowevent'. Navigate through the directory structure (structured as subscription / resource group / day / month / year / time) until you reach a file named 'PT1H.json'. Download this file to your local machine.

![NSG Log Download](https://github.com/Araffe/vdc-networking-lab/blob/master/NSGLogs.jpg "NSG Log Download")

**Figure 14:** NSG FLow Log Download

**6)** Open the PT1H.json file in an editor on your local machine (Visual Studio Code is a good choice - available as a free download from https://code.visualstudio.com/). The file should show a number of flow entries which can be inspected. Let's start by looking for an entry for TCP port 3000 (the port our demo app operates on) from our OnPrem_VM machine to the Spoke1 load balancer IP address. You can search for the IP address '10.102.1.4' to see entries associated with OnPrem\_VM1.

Here is an example of a relevant JSON entry:

<pre lang="...">
"rule":"UserRule_Allow-3000","flows":[{"mac":"000D3A25DC84","flowTuples":["1501685102,10.102.1.4,10.1.1.6,56934,3000,T,I,A"
</pre>

The above entry shows that a flow has hit the user rule named 'Allow-3000' (a rule that we configured earlier) and that the flow has a source address of 10.102.1.4 and a destination address of 10.1.1.6 (one of our Spoke1 VMs), using TCP port 3000. The letters T, I and A signify the following:

- **T:** A TCP flow (a 'U' would indicate UDP)
- **I:** An ingress flow (an 'E' would indicate an egress flow)
- **A**: An allowed flow (a 'D' would indicate a denied flow)

 **7)** Search the JSON file for a flow using port 22 (SSH).

<pre lang="...">
"rule":"UserRule_Deny-All","flows":[{"mac":"000D3A25DC84","flowTuples":["1501684054,10.102.1.4,10.1.1.6,60084,22,T,I,D"
</pre>

The above example shows a flow that has hit our user defined rule name 'Deny-All'. The source and destination addresses are the same as in the previous example, however the TCP port is 22 (SSH), which is not allowed through the NSG (note the 'D' flag).

## 4.3: Tracing Next Hop Information <a name="nexthop"></a>

Another useful feature of Network Watcher is the ability to trace the next hop for a given network destination. As an example, this is useful for diagnosing issues with User Defined Routes.

**1)** Navigate to Network Watcher as described in earlier sections.

**2)** In the left hand menu, select 'Next Hop'. Use the following parameters as input:

- Resource Group: *VDC-Main*
- Virtual Machine: *Spoke1-VM1*
- Network Interface: *Spoke1-VM1-nic*
- Source IP address: *10.1.1.6*
- Destination IP address: *10.102.1.4*

**3)** The resulting output should display *10.101.1.4* as the next hop. This is the IP address of our Network Virtual Appliance (Cisco CSR) and corresponds to the User Defined Route we configured earlier.

![Next Hop Tracking](https://github.com/Araffe/vdc-networking-lab/blob/master/NextHop.jpg "Next Hop Tracking")

**Figure 15:** Next Hop Tracking

**4)** Try other combinations of IP address / virtual machine. For example, reverse the IP addresses used in the previous step.