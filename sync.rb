#! /usr/bin/env ruby
#
# Copyright © 2014 Andrew DeMaria (muff1nman) <ademaria@mines.edu>
#
# All Rights Reserved.

require 'github_api'
require 'socket'
require 'etc'

SSH_KEY_PATH = File.join(ENV['HOME'],'.ssh')

local_public_keys = Dir.glob( File.join(SSH_KEY_PATH, '*.pub')).map { |key_filename| (File.read key_filename).chomp }.to_set
puts local_public_keys.inspect

github = Github.new basic_auth: ENV['GITHUB_AUTH']
github_keys = github.users.keys.list.to_set
github_keys_key_only = github_keys.map { |key| key.fetch 'key' }.to_set
puts github_keys_key_only.inspect
puts github_keys.map { |key| key.title }.inspect

keys_in_both = github_keys_key_only & local_public_keys
puts "Keys in both github and local:#{keys_in_both}"

keys_only_local = local_public_keys - github_keys_key_only
puts "Keys unique to local:#{keys_only_local.inspect}" 

if !keys_in_both.empty?
  exit 0
elsif !keys_only_local.empty?
  title_for_key = "#{Etc.getlogin}@#{Socket.gethostbyname(Socket.gethostname).first}"
  push_to_github = keys_only_local.first
  puts "pushing key #{push_to_github} to github as identity #{title_for_key}"
  title_already_used = github_keys.any? { |github_key| github_key.title.casecmp(title_for_key).zero? }
  if title_already_used
    abort "a key already exists on github for this identity (#{title_for_key})"
  end
  github.users.keys.create "title" => title_for_key, "key"=> push_to_github
  puts "#{title_for_key} added successfully"
else
  abort "No public keys were found on github for #{SSH_KEY_PATH} and there was none to upload to github"
end
