# -*- mode: ruby -*-
# Demo: Telegraf + InfluxDB + Grafana em uma única VM

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "monitoramento"

  # Grafana (painéis) e InfluxDB (banco de métricas) acessíveis no navegador do host
  config.vm.network "forwarded_port", guest: 3000, host: 3000, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 8086, host: 8086, host_ip: "127.0.0.1"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "monitoramento-telegraf-grafana"
    vb.memory = 2048
    vb.cpus   = 2
  end

  config.vm.provision "shell", path: "provision/provision.sh"
end
