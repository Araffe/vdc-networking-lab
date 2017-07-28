# Azure Virtual Data Centre Lab

# Contents

**[VDC Lab Introduction](#intro)**

**[Initial Lab Setup](#setup)**

**[Part 1: Explore VDC Environment](#explore)**



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

**3)** Once the resource groups have been deployed, you can deploy the lab environment into these using a set of pre-defined ARM templates. The templates are available at https://github.com/Araffe/vdc-networking-lab if you wish to learn more about how the lab is defined. Essentially, a single master template (*VDC-Networking-Master.json*) is used to call a number of other templates, which in turn complete the deployment of virtual networks, virtual machines, load balancers, availability sets, VPN gateways and third party (Cisco) network virtual appliances (NVAs). Use the following CLI command to deploy the template:

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

# Part 1: Explore VDC Environment <a name="explore"></a>

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