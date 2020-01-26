#!/usr/bin/ruby

require 'daemons'

Daemons.run 	'convPDF.rb',
							:dir => '/home/dirk/convPDF/etc',
							:dir_mode => :normal
