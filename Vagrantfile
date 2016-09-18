# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'
require 'io/console'

Vagrant.require_version ">= 1.6.0"

CLOUD_CONFIG_PATH = File.join(File.dirname(__FILE__), "user-data")
IP = "172.17.100.101"
UPDATE_CHANNEL = "beta"
IMAGE_VERSION = "current"
GUEST_MEMORY = 1024  # megabytes
GUEST_CPUS = 2

# Handle windows shared folders
if Vagrant::Util::Platform.windows? && (ARGV[0].eql?('up') || ARGV[0].eql?('reload'))
  puts "Due to MinTTY and Cygwin not supporting the no-echo TTY mode"
  puts "it is necessary to request your account username and password"
  puts "at this stage in order to correctly setup SMB shared folders."
  puts
  print "Enter username: "
  STDOUT.flush
  shared_username = STDIN.gets.chomp
  begin
    print "Enter password: "
    STDOUT.flush
    shared_password = STDIN.noecho(&:gets).chomp
  rescue
    # use hackery with control codes for cygwin/babun
    # 8m is the control code to hide characters
    print "\e[0;8m"
    shared_password = STDIN.gets.chomp
  ensure
    # 0m is the control code to reset formatting attributes
    puts "\e[0m"
  end
  STDOUT.flush
end


Vagrant.configure("2") do |config|
  if IMAGE_VERSION != "current"
    config.vm.box_version = IMAGE_VERSION
  end

  config.vm.box = "coreos-%s" % UPDATE_CHANNEL
  config.vm.box_url = "http://%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant.json" % [UPDATE_CHANNEL, IMAGE_VERSION]

  config.vm.provider :parallels do |p, override|
    override.vm.box = "AntonioMeireles/coreos-%s" % UPDATE_CHANNEL
    override.vm.box_url = "AntonioMeireles/coreos-%s" % UPDATE_CHANNEL
  end

  # Add the vagrant_insecure_key to your ssh agent to fleetctl journal among cluster nodes
  config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |v|
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS, so tell Vagrant that so it can be smarter.
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  config.vm.define vm_name = "core-01"
  config.vm.hostname = vm_name

  config.vm.provider :virtualbox do |vb|
    vb.gui = false
    vb.memory = GUEST_MEMORY
    vb.cpus = GUEST_CPUS

  end

  config.vm.network :private_network, ip: IP

  #share folders for windows

  if Vagrant::Util::Platform.windows?
    config.vm.synced_folder ".", "/home/core/dev", type: "smb", smb_username:"#{shared_username}", smb_password:"#{shared_password}", mount_options: ["username=#{shared_username}","password=#{shared_password}"]
  else
    config.vm.synced_folder ".", "/home/core/dev", id: "core", :nfs => true, :mount_options => ['nolock,vers=3,udp']
  end

  if File.exist?(CLOUD_CONFIG_PATH)
    config.vm.provision :file, :source => "#{CLOUD_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
    config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
  end

  config.vm.provision :shell, :inline => "/bin/bash /home/core/dev/scripts/run-dev.sh", :privileged => true
end
