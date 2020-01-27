#!/usr/bin/ruby

require 'logger'
require 'fileutils'
require 'evernote_uploader'
require 'pdf-reader'

map2Dir = { 
						"Vattenfall" 	    => "GasWasserStrom", 
            "Geburtsdatum"		=> "GasWasserStrom" ,
            "gibt es bestimmt nicht" => "na"
					}

maindir='/mnt/freenas/02_users/dirk/convPDF/'
ocrbin='/usr/bin/ocrmypdf --force-ocr -l deu '
indir='/mnt/freenas/07_Dokumente/Scan/Inbox/Scanned/'
outdir='/mnt/freenas/07_Dokumente/Scan/Inbox/ScannedOCR/'
errdir='/mnt/freenas/07_Dokumente/Scan/Inbox/ScannedError/'
movedir='/mnt/freenas/07_Dokumente/Scan/'

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
          if page.text.match /#{key}/ 
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

      log.debug "The searchpattern \"#{maxkey}\" with #{found_hash[maxkey]} hits was the maximum in #{file}"
      destdir=movedir+map2Dir[maxkey]
      log.debug "File will be moved to #{destdir}"
      if Dir.exists?(destdir)
        log.debug "#{destdir} exists - file #{outfile} will be moved"
        FileUtils.move outfile, destdir
      else
        log.debug "#{destdir} does not exist and will be created"
        Dir.mkdir(destdir,755) 
        FileUtils.move outfile, destdir
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
