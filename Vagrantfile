# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. 
# Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

unless Vagrant.has_plugin?("vagrant-vbguest")
  system("vagrant plugin install vagrant-vbguest")
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Either use i386 or amd64 versions
  config.vm.box       = 'puppetlabs/debian-7.8-64-nocm'

  config.vm.hostname  = 'vm.furaha.com'
  config.ssh.forward_agent = true

  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
  end

  # args:
  #   $1 clone dotfiles for this user from github
  #   $2 ruby version to install; one of:
  #      a. .ruby_version (read automatically if available)
  #      b. provide a ruby version here
  #      c. if not provided then ruby-install default ruby
  config.vm.provision :shell, :path => "./bootstrap.sh", 
    :args => ['arafatm', '2.1.5' ], 
    privileged: false
end
