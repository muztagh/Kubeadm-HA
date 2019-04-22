# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  # config.vm.box_version = "1809.01"
  # config.vbguest.auto_update = false
  # config.vm.provider 'virtualbox' do |vb|
  #   # vb.vm_integration_services = {
  #   #   guest_service_interface: true,
  #   #   CustomVMSRV: true
  #   # }
    
  # end  
  config.vm.synced_folder ".", "/vagrant", id: "my_vagrant_folder", type: "smb",
    smb_password: "Muztagh7845", smb_username: "muztagh"

  # config.vm.synced_folder ".", "/vagrant", disabled: true
  
  # config.vm.define "K8S-LB" do |node|
  #   node.vm.box =  "centos/7"
  #   node.vm.hostname = "K8s-LB"
  #   #To make nfs work with publci-network, so need to create multiple network adapter
  #   node.vm.network "public_network", ip: "192.168.1.150", bridge: "Qualcomm QCA9377 802.11ac Wireless Adapter"
  #   node.vm.network "private_network", ip: "192.168.100.100"
    
  #   node.vm.provider 'virtualbox' do |vb|
  #     vb.memory = "2048"
  #     vb.cpus = 2
  #     vb.name = "K8S-LB"
  #   end
  #   node.vm.provision "shell", path: "setupLB.sh"
  # end

  #setup ETCD
  # $num_instances = 3
  # (1..$num_instances).each do |i|
  #   config.vm.define "K8S-E#{i}" do |node|
  #     node.vm.box = "centos/7"
  #     node.vm.hostname = "K8s-E#{i}"
  #     ip = "192.168.1.#{i+155}"
  #     node.vm.network "public_network", ip: ip, bridge: "Qualcomm QCA9377 802.11ac Wireless Adapter"
  #     node.vm.network "private_network", ip: "192.168.100.100"
  #     node.vm.provider 'virtualbox' do |vb|
  #       vb.memory = "2048"
  #       vb.cpus = 2
  #       vb.name = "K8S-E#{i}"
  #     end

  #     node.vm.provision "shell", path: "setupK8S.sh", args: [i, 'ETCD', ip]
  #   end
  # end

  #setup Kubernetes control planes
  $num_instances = 3
  (1..$num_instances).each do |i|
    config.vm.define "K8S-M#{i}" do |node|
      node.vm.box = "centos/7"
      node.vm.hostname = "K8s-M#{i}"
      ip = "192.168.1.#{i+150}"
      node.vm.network "public_network", ip: ip, bridge: "Qualcomm QCA9377 802.11ac Wireless Adapter"
      node.vm.network "private_network", ip: "192.168.100.100"
      node.vm.provider 'virtualbox' do |vb|
        vb.memory = "2048"
        vb.cpus = 2
        vb.name = "K8S-M#{i}"
      end

      node.vm.provision "shell", path: "setupK8S.sh", args: [i, 'Master', ip]
    end
  end

   #install Kubernetes worker nodes
   $num_instances = 3
   (1..$num_instances).each do |i|
     config.vm.define "K8S-W#{i}" do |node|
       node.vm.box = "centos/7"
       node.vm.hostname = "K8s-W#{i}"
       ip = "192.168.1.#{i+160}"
       node.vm.network "public_network", ip: ip, bridge: "Qualcomm QCA9377 802.11ac Wireless Adapter"
       node.vm.network "private_network", ip: "192.168.100.100"
       node.vm.provider 'virtualbox' do |vb|
         vb.memory = "12288"
         vb.cpus = 4
         vb.name = "K8S-W#{i}"
       end
 
       node.vm.provision "shell", path: "setupK8S.sh", args: [i, 'Worker', ip]
     end
   end
  
end
