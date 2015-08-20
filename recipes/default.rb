#
# Cookbook Name:: opsline-dogwatch
# Recipe:: default
#
# Author:: Radek Wierzbicki
#
# Copyright 2014, OpsLine, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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
  comment 'Dogwatch User'
  supports :manage_home => true
  home "/home/#{node['opsline-dogwatch']['user']}"
  shell '/bin/bash'
end

remote_file '/usr/local/bin/dogwatch.py' do
  source "https://raw.githubusercontent.com/opsline/dogwatch/#{node['opsline-dogwatch']['version']}/dogwatch.py"
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

file '/var/log/dogwatch.log' do
  owner node['opsline-dogwatch']['user']
  group node['opsline-dogwatch']['group']
  mode 0640
end

template '/etc/dogwatch.yaml' do
  source 'dogwatch.yaml.erb'
  owner node['opsline-dogwatch']['user']
  group node['opsline-dogwatch']['group']
  mode 0600
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
  create "640 #{node['opsline-dogwatch']['user']} #{node['opsline-dogwatch']['group']}"
end
