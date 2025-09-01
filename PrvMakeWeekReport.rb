#
=begin
    #Function:  make a week financial report
    #Call:      ruby ?.rb N L/E
    #Parameters::
        #P1:    Debug: true/Y=>debug false/N=>None
        #P2:    Mode: L for log / E for exec
        #P3:    ?
    #Actions:
        #
        #
=end
# Required
#*********
#require gems
require 'rubygems'
require 'net/http'
require 'net/smtp'
require 'timeout'
require 'uri'
require 'json'
require 'csv'
require 'pp'
require 'pdfkit'
#
#***** Directories management *****
# Start of block
    require_dir = Dir.pwd
    ### puts    "dirREQUIRE:"+require_dir
require "#{require_dir}/ClDirectories.rb"
    _dir    = Directories.new(false)
# End of block
#***** Directories management *****
#

#
# Input parameters
#*****************
begin
    _debug  = ARGV[0]
    _mode   = ARGV[1]
rescue
    _debug  = false
    _mode   = 'L'
end
    _debug  = true if _debug == 'Y'
    _debug  = false if _debug == 'N'

# Check parameters
#*****************
    if _debug
        puts "Debug mode: #{_debug}"
    end

#
#***** Exec environment *****
# Start of block
    program = 'PrvMakeWeekReport'
    exec_mode   = 'B'                                   #change B or P
    dbglevel    = 'DEBUG'
    arrdirs     = _dir.otherDirs(exec_mode)             #=>{exec,private,membres,common,send,work}
require "#{arrdirs['common']}/ClCommon_2.rb"
    _com    = Common_2.new(program,_debug,dbglevel)
    private_dir     = arrdirs['private']
    member_dir      = arrdirs['membres']                #members directory
    common_dir      = arrdirs['common']                 #common directory
    work_dir        = arrdirs['work']
    send_dir        = arrdirs['send']
    downloads_dir   = arrdirs['idown']                  #iDrive/Downloads
require "#{arrdirs['common']}/ClNotion_2.rb"
# End of block
#***** Exec environment *****
#

#
# Variables
#**********
    rep_key = 'report'                                  #rep key for Notion class
    pages_id = {
        'report' => ''                                  # name => id
    }
    mvt_records = []                                    #[[name,id,category],[...],...]
#
# Internal functions
#*******************

# Main code
#**********
    # Initialize
    #+++++++++++
    # Notion class
    _rep    = ClNotion_2.new('Private')                   #mbr24 DBs familly

    _com.start(program," ")
    _com.logData(" ")
    _com.step("1-Initialize>")
    rc  = _rep.loadParams(_debug,_rep)                     #load params to Notion class
    _com.step("1A-loadParams => #{rc}")
    rc  = _rep.initNotion(rep_key)                      #init new cycle for 1 DB
    _com.step("1B-initNotion for #{rep_key}=> #{rc}")

    #
    # Processing
    #+++++++++++
    _com.step("2-Processing")
    _com.step("2A-Get week number")
    print "Enter week number (1-52): "
    week_number = $stdin.gets.chomp.to_i
    if week_number < 1 || week_number > 52
        puts "Invalid week number. Please enter a number between 1 and 52."
        exit
    end
    week = week_number.to_s.rjust(2, '0')  # Ensure week number is two digits
    _com.step("2B-Get Report_ww ID")
    filter = {
        'property' => 'expNom','formula' => {'string'=> {'contains'=> "Rapport-#{week}"}}
    }
    result = _rep.getBlock(filter)
    code = result['code']
    data = result['data']
    data = data[0]
    pageid = data['id']
    pages_id['report'] = pageid

    ### pp pages_id
    ### exit 3 if !_com.continue()

    _com.step("2C-Get MVT records")
    filter = {
            'property' => 'expNom','formula' => {'string'=> {'contains'=> "MVT-#{week}"}}
    }
    result = _rep.getBlock(filter)
    code = result['code']
    data = result['data']

    _com.step("2D-Load array for Categories")
    mvt_records = []
    data.each do |item|
        mvt_name = item['properties']['Nom']['title'][0]['text']['content']
        mvt_id = item['id']
        mvt_category = item['properties']['Catégorie']['formula']['string']
        mvt_records << [mvt_name, mvt_id,mvt_category]  #store in array
        cat_name = item['properties']['Catégorie']['formula']['string']
        cat_id = item['properties']['relCatégories']['relation'][0]['id']
        pages_id[cat_name] = ''
    end

    ### pp mvt_records
    ### exit 3 if !_com.continue()

    _com.step("2E-Process CAT records")
    pages_id.each do |cat_name, cat_id|
        next if cat_name == 'report'  # Skip the report page
        cat_body = {
            'Nom' => {'title' => [{'text' => {'content' => "CAT-"+cat_name+"-"+week}}]},
        ###    'relCatégories' => {'relation' => [{'id' => cat_id}]},
            'Parent' => {'relation' => [{'id' => pages_id['report']}]}
        }
        result = _rep.addPage('',cat_body)
        ### pp result
        pages_id[cat_name] = result['id']
    end

    ### pp pages_id
    ### exit 3 if !_com.continue()

    _com.step("2F-Process MVT records")
    mvt_records.each do |mvt|
        mvt_body = {
            'Parent' => {'relation' => [{'id' => pages_id[mvt[2]]}]},  # Use category ID
        }
        result = _rep.updPage(mvt[1], mvt_body)  # Update MVT record for Parent relation
        code = result['code']
        if code != '200'
            _com.step("Error updating MVT record #{mvt[0]}: #{result}")
        else
            _com.step("Updated MVT record #{mvt[0]} successfully.")
        end
    end

    _com.step("3-Generate report")



    #Exit
    #====
    _com.stop(program,"Bye bye")
#<EOS>