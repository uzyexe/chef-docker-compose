#
# Cookbook Name:: docker-compose
# Recipe:: default
#
# Copyright 2014, Denis Barishev
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'docker'
include_recipe 'python'

directory 'compose.d' do
  path  node['docker-compose']['config_directory']
  mode  00755
  owner 'root'
  group 'root'
end

python_pip 'docker-compose' do
  package_name(node['docker-compose']['git_url']) if node['docker-compose']['git_url']
end
