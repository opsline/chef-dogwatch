#
# Cookbook Name:: opsline-dogwatch
# Recipe:: default
#
# Copyright (C) 2015 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'python'
python_pip 'dogapi'

group node['opsline-dogwatch']['group'] do
  action :create
  system true
end

user node['opsline-dogwatch']['user'] do
  action :create
  system true
  gid node['opsline-dogwatch']['group']
  comment "Dogwatch User"
  supports :manage_home => true
  home "/home/#{node['opsline-dogwatch']['user']}"
  shell '/bin/bash'
end

remote_file '/usr/local/bin/dogwatch.py' do
  source 'https://raw.githubusercontent.com/opsline/dogwatch/0.1.1/dogwatch.py'
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

file '/var/log/dogwatch.log' do
  owner node['opsline-dogwatch']['user']
  group node['opsline-dogwatch']['group']
  mode 0644
end

template '/etc/dogwatch.yaml' do
  source 'dogwatch.yaml.erb'
  owner 'root'
  group 'root'
  mode 0755
  variables({})
  action :create
end

cron 'dogwatch' do
  command '/usr/local/bin/dogwatch.py -c /etc/dogwatch.yaml >>/var/log/dogwatch.log 2>&1'
  user node['opsline-dogwatch']['user']
  hour '*'
  minute '*'
  action :create
end

logrotate_app 'dogwatch' do
  cookbook 'logrotate'
  path '/var/log/dogwatch.log'
  options ['missingok', 'compress', 'notifempty', 'delaycompress']
  frequency 'daily'
  rotate 7
  create "644 #{node['opsline-dogwatch']['user']} #{node['opsline-dogwatch']['group']}"
end
