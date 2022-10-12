
az group create `
--name rgWebappScript `
--location westeurope

az network public-ip create `
--resource-group rgWebappScript `
--name pipLBwebappScript `
--sku Standard

az network lb create `
--resource-group rgWebappScript `
--name lbWebappScript `
--public-ip-address pipLBwebappScript `
--frontend-ip-name frontWebappScript `
--backend-pool-name backWebappScript `
--sku Standard

az network lb probe create `
--resource-group rgWebappScript `
--lb-name lbWebappScript `
--name hpWebappScript `
--protocol tcp `
--port 80

#Create load balancer rule for port 80
az network lb rule create `
--resource-group rgWebappScript `
--lb-name lbWebappScript `
--name lbWebappScriptRuleWeb `
--protocol tcp `
--frontend-port 80 `
--backend-port 80 `
--frontend-ip-name frontWebappScript `
--backend-pool-name backWebappScript `
--probe-name hpWebappScript

#Configure virtual network
az network vnet create `
--resource-group rgWebappScript `
--location westeurope `
--name vnetWebappScript `
--subnet-name subnetWebappScript

#Create a network security group
az network nsg create `
--resource-group rgWebappScript `
--name nsgWebappScript

#Create a network security group rule named nsgWebappScriptRule for port 80 
az network nsg rule create  --resource-group rgWebappScript --nsg-name nsgWebappScript `
    --name Allow_80 `
    --access Allow `
    --protocol tcp `
    --direction Inbound `
    --source-address-prefix "$MY_IP" `
    --source-port-ranges "*" `
    --destination-address-prefix "*" `
    --destination-port-range "80" `
    --priority 180 

az network nsg rule create  --resource-group rg-webapp-script09 --nsg-name nsg-webapp-script09 `
    --name Allow_22 `
    --access Allow `
    --protocol tcp `
    --direction Inbound `
    --source-address-prefix "$MY_IP" `
    --source-port-ranges "*" `
    --destination-address-prefix "*" `
    --destination-port-range "22" `
    --priority 122
   
#Create three NIC cards one for each VM
$no_Of_NIC = 1,2
foreach($i in $no_Of_NIC ){
 
    az network nic create `
        --resource-group rgWebappScript `
        --name nicWebappScript$i `
        --vnet-name vnetWebappScript `
        --subnet subnetWebappScript `
        --network-security-group nsgWebappScript `
        --lb-name lbWebappScript `
        --lb-address-pools backWebappScript
}

#Create Three Virtual Machines and attach the three NIC cards 
$no_Of_VM = 1,2
foreach($i in $no_Of_VM ){
 
  az vm create `
    --resource-group rgWebappScript `
    --name vmWebappScript$i `
    --nics nicWebappScript$i `
    --image Debian `
    --size Standard_B1ls `
    --admin-username $user `
    --ssh-key-values "ssh-rsa $sshKey" `
    --zone $i

  az vm run-command invoke `
    --resource-group rgWebappScript `
    --name vmWebappScript$i `
    --command-id RunShellScript `
    --scripts "sudo apt-get update && sudo apt-get install -y nginx && sudo apt install git -y && git clone https://github.com/lerna/website.git /home/$user/webapp && cp -a /home/$user/webapp/. /var/www/html/ && sed 's/Documentation | Lerna/vmwebapp0$i-script07/' /var/www/html/index.html  > /var/www/index.html && rm /var/www//html/index.html && cp /var/www/index.html /var/www/html/index.html && rm /var/www/html/index.nginx-debian.html"
}
