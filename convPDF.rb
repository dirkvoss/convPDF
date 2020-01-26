#!/usr/bin/ruby

require 'logger'
require 'fileutils'
require 'evernote_uploader'
require 'pdf-reader'

map2Dir = { 
						"Vattenfall" 	=> "GasWasserStrom", 
						"ARI Fleet Germany"		=> "Leasing" 
					}

maindir='/mnt/freenas/02_users/dirk/convPDF/'
ocrbin='/usr/bin/ocrmypdf --force-ocr -l deu '
indir='/mnt/freenas/07_Dokumente/Scan/Inbox/Scanned/'
outdir=' /mnt/freenas/07_Dokumente/Scan/Inbox/ScannedOCR/'
errdir='/mnt/freenas/07_Dokumente/Scan/Inbox/ScannedError/'
movedir='/mnt/freenas/07_Dokumente/Scan/'

logdir=maindir + 'log/';
logfile=logdir + 'convPDF.log'
sleeptime=600

log = Logger.new(logfile, 'monthly')

loop do
  log.debug "Start"
  log.debug "Kein PDF FIle in #{indir} vorhanden" if Dir.empty?(indir)

  Dir.glob('*.pdf', base: indir) do |file|
    infile=indir + file
    cmd=ocrbin + indir + file + outdir + file + " 2>&1"
    execute=`#{cmd}`
    if $?.success?
	    log.debug "#{file} erfolgreich in #{outdir} erzeugt"
	    if File.exist?(infile)
              File.delete(infile) 
	      log.debug "File #{file} in #{indir} geloescht"
	    else
	      log.error "File #{file} konnte in #{indir} nicht gefunden werden"	  
      end  
   
      outfile=outdir + file	   
      log.debug "File #{outfile} will be scanned"
      reader = PDF::Reader.new(outfile.strip)

      #hash leeren
      found_hash = Hash.new
      map2Dir.each do |key, value|
        found_hash[key]=0
      end

      reader.pages.each do |page|
        map2Dir.each do |key, value|
          log.debug "check #{key}"
          if page.text.match /#{key}/ 
            log.debug "#{key} found"
            found_hash[key]+=1
          end
        end
      end
    
      maxCnt=0
      maxkey=''
      map2Dir.each do |key, value|
        if found_hash[key] > 0
          log.debug "#{key}  found  #{found_hash[key]} times in #{file}"
          if found_hash[key] > maxCnt
            maxCnt=found_hash[key]
            maxkey=key
          end
        else
          log.debug "#{key} not found in #{file}"
        end
      end

      log.debug "Max #{maxkey} found #{found_hash[maxkey]} times in #{file}"
     
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
