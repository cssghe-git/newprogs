#
=begin
    #Function:  extract 1 member
    #Call:      ruby EneoBwSpc_ExtFiche.rb N X
    #Parameters::
        #P1:    R=>request D=>default Y=>debug N=>None
        #P2:    member's reference or None
        #P3:    display => Raw or Fixed or None
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
    _member = ARGV[1]
    _dis    = ARGV[2]
rescue
    _debug  = false
    _member = 'None'
    _dis    = 'F'
end
    _debug  = true if _debug == 'Y'
    _debug  = false if _debug == 'N'
    _dis    = _dis.upcase
    _dis    = 'F' if _dis == 'R' || _dis == 'RAW'
    _dis    = 'F' if _dis == 'F' || _dis == 'FIXED'
    _dis    = 'F' if _dis == 'NONE'

# Check parameters
#*****************
    if _debug
        puts "Debug mode: #{_debug}"
        puts "Member: #{_member}"
        puts "Display mode: #{_dis}"
    end
    if _member  == 'None'
        print   "For member ? : "
        _member = $stdin.gets.chomp
    end
    if _dis == 'None'
        print   "Display mode (R)aw or (F)ixed ? : "
        _dis    = $stdin.gets.chomp
    end

#
#***** Exec environment *****
# Start of block
    program = 'EneoBwSpc_ExtFiche4'
    exec_mode   = 'P'                                   #change B or P
    dbglevel    = 'DEBUG'
    arrdirs = _dir.otherDirs(exec_mode)                 #=>{exec,private,membres,common,send,work}
require "#{arrdirs['common']}/ClCommon_2.rb"
    _com    = Common_2.new(program,_debug,dbglevel)
    private_dir = arrdirs['private']
    member_dir   = arrdirs['membres']                     #members directory
    common_dir   = arrdirs['common']                     #common directory
    work_dir    = arrdirs['work']
    send_dir    = arrdirs['send']
require "#{arrdirs['common']}/ClNotion_2.rb"
# End of block
#***** Exec environment *****
#

#
# Variables
#**********
    #membres_v24 => mbr_
    mbr_key     = 'membres_v24'                         #DB key
    mbr_fields  = []                                    #DB fields
    #requests
    req_fields  = [                                     #array of fields requested, or ALL
        'ALL'
    ] 
    req_activity    = 'NIV-'
    #
    infos   = {}
    count   = 0

    #pdf
    header  = "
                <head>
                    <style>
                        h1 {color:green;}
                        h2 {color:blue;}
                        h3 {color:orange}
                        h4 {color:pink}
                        div {height:400px;width:100%;background_color:blue}
                        body {text-align:left; color:black;}
                    </style>
                </head>
    "
    body    = ''
    @content    = "*****Start*****<br>"
    filepflog   = "#{send_dir}/FicheMembre_#{_member}.pdf"

#
# Internal functions
#*******************

# Main code
#**********
    # Initialize
    #+++++++++++
    # Notion class
    _mbr    = ClNotion_2.new('Mbr24')                   #mbr24 DBs familly

    _com.start(program," Extract <Fiche> for "+_member)
    _com.logData(" Start for Member:#{_member} with Display:#{_dis}")
    _com.step("1-Initialize>")
    rc  = _mbr.loadParams(_debug,_mbr)                     #load params to Notion class
    _com.step("1A-loadParams => #{rc}")
    rc  = _mbr.initNotion(mbr_key)                      #init new cycle for 1 DB
    _com.step("1B-initNotion for #{mbr_key}=> #{rc}")

    #
    # Processing
    #+++++++++++

    _com.step("2-Processing")
    _com.step("2A-Get MBR Fields")
    result  = _mbr.getDbFields()
    mbr_code    = result['code']
    mbr_fields  = result['data']                        #{code=>,fields=>[]}
    _com.step("2B-Get MBR Fields with RC : #{mbr_code}")
    _com.step("2B-Get MBR Fields with DATA : #{mbr_fields}")    if _debug

    _com.step("***********************************")
    _com.step("3-Yield block")
    mbr_filter  = {
        'and'=> [
            {'property'=> 'EnCours', 'checkbox'=>{'equals'=>true}},
            {'property'=> 'Référence', 'title'=>{'contains'=>_member}}
        ]
    }
    mbr_sort    = [
        {'property'=> 'Référence', 'direction'=> 'ascending'}
    ]
    fields  = ['ALL']                                   #array of fields requested or ALL, or ALL

    _com.step("3A-Filter:#{mbr_filter}")
    _com.logData(" Filter:#{mbr_filter}")
    _mbr.runPages(mbr_filter,mbr_sort,fields) do |state,data|    #execute bloc on Notion class with filter, sort & properties
                        #code => true if page, false if no more pages   
                        #data => result function => all properties {field=>value,...}
        count   += 1
        _com.step("3B-#{state} => #{count} - DATA:")
        ### pp  data
        code    = data['code']
        if state == true #<IF1>                  #if page
            created_time = data['created_time']       #created time
            last_edited_time = data['last_edited_time'] #last edited time
            properties  = _mbr.loadProperties(data,fields)

            sch_flag    = false
            member      = properties['Référence']
            _com.step("4A-REF:#{member}")
            if member.include?(_member) #IF2>
                sch_flag    = true
                if _dis.include?('R')    #<IF3>
                    @content.concat("<br>Membre => #{member}<br>")
                    properties.each do |prop| #<L4>                   #loop all properties
                    #pp  prop
                        name    = prop[0]                       #extract name
                        value   = prop[1]                       #extract value
                        if name != "Référence"  #<IF5>
                            _com.step("4B-FIELD:#{name} => #{value}")
                            @content.concat("<br>#{name} => #{value}<br>")
                        end #<IF5>
                    end #<L4>
                    _com.step("4B-FIELD:Created => #{created_time}")
                    @content.concat("<br>Created => #{created_time}<br>")
                    _com.step("4B-FIELD:Updated => #{last_edited_time}")
                    @content.concat("<br>Updated => #{last_edited_time}<br>")
                elsif _dis.include?('F') #<IF3>
                    puts "<br>Actif             => #{properties['Encours']}<br><br>"
                    puts "<br>CDC               => #{properties['CDC']}<br>"
                    puts "<br>Activité Prc      => #{properties['ActivitéP']}<br>"
                    puts "<br>Activités Sec     => #{properties['ActivitéS']}<br><br>"
                    puts "<br>Civilité          => #{properties['Civilité']}<br>"
                    puts "<br>Adresse           => #{properties['Rue + Numéro/Boite']} - #{properties['Code postal']} - #{properties['Localité']}<br>"
                    puts "<br>Naissance         => #{properties['Date de Naissance']}<br>"
                    puts "<br>GSM               => #{properties['GSM']}<br>"
                    puts "<br>TEL               => #{properties['Téléphone']}<br>"
                    puts "<br>@@@               => #{properties['Mail']}<br><br>"
                    puts "<br>Cotisation        => #{properties['Cotisation']} - #{properties['Date de Paiement']}<br>"
                    puts "<br>CPE               => #{properties['CPE']}<br>"
                    puts "<br>Cotisant          => #{properties['Cotisant']}<br>"
                    puts "<br>Eneo/Sport        => #{properties['EneoSport']}<br>"
                    puts "<br>Seagma            => #{properties['Seagma']}<br><br>"
                    puts "<br>Introduction      => #{properties['Date Inscription']}<br>"
                    puts "<br>Modification      => #{properties['Date de Modification']}<br>"
                    puts "<br>Sortie            => #{properties['Date de Sortie']}<br>"

                    @content.concat("<br>Actif => #{properties['Encours']}<br><br>")
                    @content.concat("<br>CDC => #{properties['CDC']}<br>")
                    @content.concat("<br>Activité Prc => #{properties['ActivitéP']}<br>")
                    @content.concat("<br>Activités Sec => #{properties['ActivitéS']}<br><br>")
                    @content.concat("<br>Civilité => #{properties['Civilité']}<br>")
                    @content.concat("<br>Adresse => #{properties['Rue + Numéro/Boite']} - #{properties['Code postal']} - #{properties['Localité']}<br>")
                    @content.concat("<br>Naissance => #{properties['Date de Naissance']}<br>")
                    @content.concat("<br>GSM => #{properties['GSM']}<br>")
                    @content.concat("<br>TEL => #{properties['Téléphone']}<br>")
                    @content.concat("<br>@@@ => #{properties['Mail']}<br><br>")
                    @content.concat("<br>Cotisation => #{properties['Cotisation']} - #{properties['Date de Paiement']}<br>")
                    @content.concat("<br>CPE => #{properties['CPE']}<br>")
                    @content.concat("<br>Cotisant => #{properties['Cotisant']}<br>")
                    @content.concat("<br>Eneo/Sport => #{properties['EneoSport']}<br>")
                    @content.concat("<br>Seagma => #{properties['Seagma']}<br><br>")
                    @content.concat("<br>Introduction => #{properties['Date Inscription']}<br>")
                    @content.concat("<br>Modification => #{properties['Date de Modification']}<br>")
                    @content.concat("<br>Sortie => #{properties['Date de Sortie']}<br>")
                    @content.concat("<br>Décès => #{properties['Date de Décès']}<br>")
                end #<IF3>
            end #<IF2>
            break   if sch_flag == true                     #exit loop
        else    #<IF1>                                  #if no more pages
            _com.step("4C-#{code} => No more pages")
            @content.concat("<br>#{code} => No more pages<br>")
            break
        end #<IF1>
    end #<do>
    #Create pdf
    #++++++++++
    _com.step("5-Create pdf")
    @content.concat("<br><br>*****End*****<br>")
    body    = "<body> #{@content} </body>"
    html    = "#{header} #{body}"
    _pdf    = PDFKit.new(html)
    _pdf.to_file(filepflog)

    #Display counters
    #================
    _com.step("6-Counters::Members:#{count}")
    _com.exit("Bye bye")
#<EOS>