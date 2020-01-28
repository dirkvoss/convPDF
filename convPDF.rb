#!/usr/bin/ruby

require 'logger'
require 'fileutils'
require 'pdf-reader'

map2Dir = { 
						"Vattenfall" 	            => "GasWasserStrom", 
            "barclaycard"		          => "Bank",
            "kontoauszug"             => "Bank",
            "Huk-Coburg"              => "Versicherungen"
					}

maindir='/mnt/freenas/02_users/dirk/convPDF/'
ocrbin='/usr/bin/ocrmypdf --force-ocr -l deu '
origdir='/mnt/freenas/07_Dokumente/Scan/'

indir=origdir  + 'Inbox/Scanned/'
outdir=origdir + 'Inbox/ScannedOCR/'
errdir=origdir + 'Inbox/ScannedError/'
defaultdir=origdir + 'Mix/'

logdir=maindir + 'log/';
logfile=logdir + 'convPDF.log'
sleeptime=600

log = Logger.new(logfile, 'monthly')

loop do
  log.debug "Start"
  log.debug "No PDF file in  #{indir} " if Dir.empty?(indir)

  Dir.glob('*.pdf', base: indir) do |file|
    infile=indir + file
    cmd=ocrbin + indir + file + ' ' + outdir + file + " 2>&1"
    execute=`#{cmd}`
    if $?.success?
	    log.debug "#{file} generated in #{outdir} "
	    if File.exist?(infile)
              File.delete(infile) 
	      log.debug "#{file} in #{indir} deleted"
	    else
	      log.error "#{file} not found in #{indir}"	  
      end  
   
      outfile=outdir + file	   
      log.debug "#{outfile} will be scanned"
      reader = PDF::Reader.new(outfile.strip)

      #hash leeren
      found_hash = Hash.new
      map2Dir.each do |key, value|
        found_hash[key]=0
      end

      reader.pages.each do |page|
        map2Dir.each do |key, value|
          #log.debug "check #{key}"
          if page.text.match (/#{key}/i) 
            #log.debug "#{key} found"
            found_hash[key]+=1
          end
        end
      end
    
      maxCnt=0
      maxkey=''
      map2Dir.each do |key, value|
        if found_hash[key] > 0
          log.debug "Searchpattern \"#{key}\" found #{found_hash[key]} times in #{file}"
          if found_hash[key] > maxCnt
            maxCnt=found_hash[key]
            maxkey=key
          end
        else
          log.debug "Searchpattern \"#{key}\" not found in #{file}"
        end
      end

      if maxCnt == 0
        log.debug "#{file} will be moved to default dir #{defaultdir}"
          if Dir.exists?(defaultdir)
            log.debug "#{defaultdir} exists - file will be moved"
            FileUtils.move outfile, defaultdir
          else
            log.debug "#{defaultdir} does not exist and will be created and file will be moved"
            Dir.mkdir(defaultdir,755) 
            FileUtils.move outfile, defaultdir
          end
      else
        log.debug "The searchpattern \"#{maxkey}\" with #{found_hash[maxkey]} hits was the maximum in #{file}"
        destdir=origdir+map2Dir[maxkey]
        log.debug "File will be moved to #{destdir}"

        newfilename=maxkey.upcase.gsub(/[^a-zA-Z\s.]/,'').strip  + '_' + file
        dest = destdir + '/' + newfilename
        log.debug "File #{file} will be renamed to #{newfilename}"
                
        if Dir.exists?(destdir)
          log.debug "#{destdir} exists - file will be moved"
          FileUtils.move outfile, dest
        else
          log.debug "#{destdir} does not exist and will be created and file will be moved"
          Dir.mkdir(destdir,755) 
          FileUtils.move outfile, dest
        end
      end

    else
      log.error "#{file} konnte nicht umgewandelt werden !"
      log.error "#{execute.chomp}"
      FileUtils.move infile, errdir
      log.error "mv #{file} to #{errdir}"
    end
  end
  log.debug "End"
 sleep (sleeptime)
end
