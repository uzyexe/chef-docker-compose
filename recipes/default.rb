#
# Cookbook Name:: docker-compose
# Recipe:: default
#
# Copyright 2014, Denis Barishev
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'docker' if node['docker-compose']['include_docker']
include_recipe 'python::default'

directory 'compose.d' do
  path  node['docker-compose']['config_directory']
  mode  00755
  owner 'root'
  group 'root'
end

package 'curl'

bash "Install docker-compose" do
  code <<-EOH
  curl -L #{node['docker-compose']['base_url']}/#{node['docker-compose']['version']}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose-#{node['docker-compose']['version']}
  mv /usr/local/bin/docker-compose-#{node['docker-compose']['version']} /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
EOH
  not_if "docker-compose --version | grep -w 'docker-compose version' | grep -w '#{node['docker-compose']['version']}'"
end
