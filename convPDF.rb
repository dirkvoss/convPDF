#!/usr/bin/ruby

require 'logger'
require 'fileutils'
require 'evernote_uploader'
require 'pdf-reader'

maindir='/home/dirk/convPDF/'
ocrbin='/usr/bin/ocrmypdf --force-ocr -l deu '
indir='/mnt/freenas/07_Dokumente/Scan/Inbox/Scanned/'
outdir=' /mnt/freenas/07_Dokumente/Scan/Inbox/ScannedOCR/'
errdir='/mnt/freenas/07_Dokumente/Scan/Inbox/ScannedError/'
logfile=maindir + 'convPDF.log'
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
