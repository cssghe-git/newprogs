#
=begin
    #Function:  extract 1 activity
    #Call:      ruby EneoBwSpc_ExtActivity.rb N X
    #Parameters::
        #P1:    R=>request D=>default Y=>debug N=>None
        #P2:    activity's reference or None
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
    _act    = ARGV[1]
    _dis    = ARGV[2]
rescue
    _debug  = 'N'
    _act    = 'None'
    _dis    = 'F'
end
    _debug  = _debug.upcase
    _debug  = true if _debug == 'Y'
    _debug  = false if _debug == 'N'
    if _act == 'None'
        print   "For activity ? : "
        _act    = $stdin.gets.chomp
    end
    if _dis == 'None'
        print   "Display mode (R)aw or (F)ixed ? : "
        _dis    = $stdin.gets.chomp
        _dis    = _dis.upcase
    end

    print   "Filter on Ctrl (Y/N) ? : "
    _filter = $stdin.gets.chomp.upcase
    _filter = 'N'   if _filter.size == 0

#
#***** Exec environment *****
# Start of block
    program = 'EneoBwSpc_ExtActivity4'
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
    downloads_dir   = arrdirs['work']
require "#{arrdirs['common']}/ClNotion_2.rb"
# End of block
#***** Exec environment *****
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
    if _act.include?("NIV-")
    else
        _act    = "NIV-#{_act}"
    end
    req_activity    = _act
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
                    <style>
                        table {
                            border-collapse: collapse; /* Évite la double bordure */
                            width: 100%;
                        }
                        th, td {
                            border: 1px solid #000; /* Bordure autour des cellules */
                            padding: 8px;
                            text-align: center;
                        }
                        th {
                            background-color: #f2f2f2; /* Couleur de fond pour l'en-tête */
                        }
                    </style>
                </head>
    "
    body    = ''
    @content    = "*****Start*****<br>"
    @content.concat("<table>")
    @content.concat("<caption>Mon Activité</caption>")
    @content.concat("<tr><th>Membre</th><th>CDC</th><th>ActPrc</th><th>ActSecs</th><th>Cotisation</th><th>Contrôles</th></tr>")

    filepflog   = "#{send_dir}/FicheActivite_#{_act}.pdf"

#
# Internal functions
#*******************

# Main code
#**********
    # Initialize
    #+++++++++++
    # Notion class
    _mbr    = ClNotion_2.new('Mbr24')                   #mbr24 DBs familly

    _com.start(program,"Start for activity: "+_act+" with controls: "+_filter)
    _com.logData(" Start for activity: "+_act+" with controls: "+_filter)
    _com.step("1-Initialize>")
    rc  = _mbr.loadParams(_debug,_mbr)                     #load params to Notion class
    _com.step("1A-loadParams => #{rc}")
    rc  = _mbr.initNotion(mbr_key)                      #init new cycle for 1 DB
    _com.step("1B-initNotion for #{mbr_key}=> #{rc}")

    #
    # Processing
    #+++++++++++

    _com.step("2-Processing with properties :: Debug:#{_debug} ACT:#{_act}")
    _com.step("2A-Get MBR Fields")
    result  = _mbr.getDbFields()
    mbr_fields  = result['data']                        #{code=>,fields=>[]}
    ### _com.step("2B-Fields: #{mbr_fields}")

    _com.step("3-Yield block")
    if _filter == 'Y'
        mbr_filter  = {
            'and'=> [
                {'property'=> 'EnCours', 'checkbox'=> {'equals'=>true}},
                {'property'=> 'CDC', 'select'=> {'equals'=>"NIV"}},
                {'property'=> 'Ctrl', 'formula'=> {'string'=> {'does_not_contain'=> "OK"}}},
                {'property'=> 'AllActs', 'formula'=>{'string'=>{'contains'=>_act}}}
            ]
        }
    else
        mbr_filter  = {
            'and'=> [
                {'property'=> 'EnCours', 'checkbox'=>{'equals'=>true}},
                {'property'=> 'AllActs', 'formula'=>{'string'=>{'contains'=>_act}}}
            ]
        }
    end
    mbr_sort    = [
        {'property'=> 'Référence', 'direction'=> 'ascending'}
    ]
    fields  = ['ALL']                                   #array of fields requested or ALL, or ALL

    _mbr.runPages(mbr_filter,mbr_sort,fields) do |code,data|    #execute bloc on Notion class with filter, sort & properties
                                                        #data => result function => all properties {field=>value,...}
        count   += 1
        #pp  data

        if code == true #<IF2>
            properties  = _mbr.loadProperties(data,fields)

            member      = properties['Référence']
            _com.step("4A-REF:#{member}")
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
            elsif _dis.include?('F') #<IF3>
                puts "<br>CDC               => #{properties['CDC']}<br>"
                puts "<br>Activité Prc      => #{properties['ActivitéP']}<br>"
                puts "<br>Activités Sec     => #{properties['ActivitéS']}<br><br>"
                puts "<br>Cotisation        => #{properties['Cotisation']} - #{properties['Date de Paiement']}<br>"
                puts "<br>Contrôles         => #{properties['Ctrl']}<br>"

                @content.concat("<tr>")
                @content.concat("<td>#{properties['Référence']}</td>")
                @content.concat("<td>#{properties['CDC']}</td>")
                @content.concat("<td>#{properties['ActivitéP']}</td>")
                @content.concat("<td>#{properties['ActivitéS']}</td>")
                @content.concat("<td>#{properties['Cotisation']}</td>")
                @content.concat("<td>#{properties['Ctrl']}</td>")
                @content.concat("</tr>")
            end #<IF3>
        end #<IF2>
    end #<L1>
    @content.concat("</table>")

    #Create pdf
    #++++++++++
    _com.step("5-Create pdf")
    @content.concat("<br><br>*****End*****<br>")
    body    = "<body> #{@content} </body>"
    html    = "#{header} #{body}"
    _pdf    = PDFKit.new(html, :orientation => 'Landscape')
    _pdf.to_file(filepflog)

    #Display counters
    #================
    _com.step("6-Counters::Members:#{count}")
    _com.exit("Bye bye")
#<EOS>