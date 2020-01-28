#!/usr/bin/ruby

require 'daemons'

Daemons.run 	'convPDF.rb',
							:dir => '/mnt/freenas/02_users/dirk/convPDF/etc',
							:dir_mode => :normal
