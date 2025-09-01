#
=begin
    #Function:  extract 1 member's trackings
    #Call:      ruby EneoBwSpc_ExtTracking.rb N None None
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
### require 'profile'
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
    _debug      = ARGV[0]
    _member     = ARGV[1]
    _dis        = ARGV[2]

    _debug  = _debug.upcase
    _debug  = true if _debug == 'Y'
    _debug  = false if _debug == 'N'

    if _member == 'None'
        print   "For member ? : "
        _member    = $stdin.gets.chomp
    end
    if _dis == 'None'
        print   "Display mode (R)aw or (F)ixed ? : "
        _dis    = $stdin.gets.chomp
        _dis    = _dis.upcase
    end

#
#***** Exec environment *****
# Start of block
    program = 'EneoBwSpc_ExtTraking4'
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
    mbr_key     = 'membres_v24'                         #Mbr key
    mbr_fields  = []                                    #Mbr fields
    #modifications_v24 => mod_
    mod_key     = 'modifications_v24'                   #Mod key
    mod_fields  = []                                    #Mod fields
    #logfile_v24 => log_
    log_key     = 'logfile_v24'                         #Log key
    log_fields  = []                                    #Log fields
    #updates_v24 => upd_
    upd_key     = 'updates_v24'                         #Upd key
    upd_fields  = []                                    #Upd fields

    #requests
    req_fields  = [                                     #array of fields requested, or ALL
        'ALL'
    ] 
    req_activity    = 'NIV-'
    #
    infos       = {}
    count_mbr   = 0
    count_upd   = 0
    count_mod   = 0
    count_log   = 0

    #pdf
    pdf_header  = "
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
    pdf_body    = ''
    @content    = "*****Start*****<br>"
    filepflog   = "#{send_dir}/SuivisMembre_#{_member}.pdf"

#
# Internal functions
#*******************
#
# Main code
#**********
    # Initialize
    #+++++++++++
    # Notion class
    _mbr    = ClNotion_2.new('Mbr24')                   #mbr24 DBs familly
    _mod    = ClNotion_2.new('Mbr24')
    _log    = ClNotion_2.new('Mbr24')
    _upd    = ClNotion_2.new('Mbr24')

    _com.start(program," Extract all for "+_member)
    _com.logData(" Start for Member:#{_member} with Display:#{_dis}")
    _com.step("1-Initialize>")
    rc  = _mbr.loadParams(_debug,_mbr)                     #load params to Notion class
    _com.step("1A-loadParams MBR => #{rc}")
    rc  = _mbr.initNotion(mbr_key)                      #init new cycle for 1 DB
    _com.step("1B-initNotion MBR for #{mbr_key}=> #{rc}")

    rc  = _mod.loadParams(_debug,_mod)                     #load params to Notion class
    _com.step("1A-loadParams MOD => #{rc}")
    rc  = _mod.initNotion(mod_key)                      #init new cycle for 1 DB
    _com.step("1B-initNotion MOD for #{mod_key}=> #{rc}")

    rc  = _upd.loadParams(_debug,_upd)                     #load params to Notion class
    _com.step("1A-loadParams UPD => #{rc}")
    rc  = _upd.initNotion(upd_key)                      #init new cycle for 1 DB
    _com.step("1B-initNotion UPD for #{upd_key}=> #{rc}")

    rc  = _log.loadParams(_debug,_log)                     #load params to Notion class
    _com.step("1A-loadParams LOG => #{rc}")
    rc  = _log.initNotion(log_key)                      #init new cycle for 1 DB
    _com.step("1B-initNotion LOG for #{log_key}=> #{rc}")

    #
    # Processing
    #+++++++++++
    _com.step("2-Processing")
    #
    #                   -1-Member's details
    #                   ===================
    _com.step("2A-Get MBR Fields")
    result  = _mbr.getDbFields()
    mbr_fields  = result['data']                        #{code=>,fields=>[]}
    _com.debug("2B-Fields: #{mbr_fields}")

    _com.step("3-Yield block <<<<<Membres>>>>>")
    _com.step("*")
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

    _mbr.runPages(mbr_filter,mbr_sort,fields) do |state,data|    #execute bloc on Notion class with filter, sort & properties
                                                        #data => result function => all properties {field=>value,...}
        count_mbr   += 1
        #   pp  data

        if state == true #<IF1>                  #if page
            created_time = data['created_time']       #created time
            last_edited_time = data['last_edited_time'] #last edited time
            properties  = _mbr.loadProperties(data,fields)
            #   pp properties

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
                    puts "<br>Actif                 => #{properties['Encours']}<br><br>"
                    puts "<br>CDC                   => #{properties['CDC']}<br>"
                    puts "<br>Activité Prc          => #{properties['ActivitéP']}<br>"
                    puts "<br>Activités Sec         => #{properties['ActivitéS']}<br><br>"
                    puts "<br>Civilité              => #{properties['Civilité']}<br>"
                    puts "<br>Adresse               => #{properties['Rue + Numéro/Boite']} - #{properties['Code postal']} - #{properties['Localité']}<br>"
                    puts "<br>Naissance             => #{properties['Date de Naissance']}<br>"
                    puts "<br>GSM                   => #{properties['GSM']}<br>"
                    puts "<br>TEL                   => #{properties['Téléphone']}<br>"
                    puts "<br>@@@                   => #{properties['Mail']}<br><br>"
                    puts "<br>Cotisation            => #{properties['Cotisation']} - #{properties['Date de Paiement']}<br>"
                    puts "<br>CPE                   => #{properties['CPE']}<br>"
                    puts "<br>Cotisant              => #{properties['Cotisant']}<br>"
                    puts "<br>Eneo/Sport            => #{properties['EneoSport']}<br>"
                    puts "<br>Seagma                => #{properties['Seagma']}<br><br>"
                    puts "<br>Introduction          => #{properties['Date Inscription']}<br>"
                    puts "<br>Modification          => #{properties['Date de Modification']}<br>"
                    puts "<br>Sortie                => #{properties['Date de Sortie']}<br>"

                    @content.concat("<br>Membre         => #{properties['Référence']}<br><br>")
                    @content.concat("<br>Actif          => #{properties['Encours']}<br><br>")
                    @content.concat("<br>CDC            => #{properties['CDC']}<br>")
                    @content.concat("<br>Activité Prc   => #{properties['ActivitéP']}<br>")
                    @content.concat("<br>Activités Sec  => #{properties['ActivitéS']}<br><br>")
                    @content.concat("<br>Civilité       => #{properties['Civilité']}<br>")
                    @content.concat("<br>Adresse        => #{properties['Rue + Numéro/Boite']} - #{properties['Code postal']} - #{properties['Localité']}<br>")
                    @content.concat("<br>Naissance      => #{properties['Date de Naissance']}<br>")
                    @content.concat("<br>GSM            => #{properties['GSM']}<br>")
                    @content.concat("<br>TEL            => #{properties['Téléphone']}<br>")
                    @content.concat("<br>@@@            => #{properties['Mail']}<br><br>")
                    @content.concat("<br>Cotisation     => #{properties['Cotisation']} - #{properties['Date de Paiement']}<br>")
                    @content.concat("<br>CPE            => #{properties['CPE']}<br>")
                    @content.concat("<br>Cotisant       => #{properties['Cotisant']}<br>")
                    @content.concat("<br>Eneo/Sport     => #{properties['EneoSport']}<br>")
                    @content.concat("<br>Seagma         => #{properties['Seagma']}<br><br>")
                    @content.concat("<br>Introduction   => #{properties['Date Inscription']}<br>")
                    @content.concat("<br>Modification   => #{properties['Date de Modification']}<br>")
                    @content.concat("<br>Sortie         => #{properties['Date de Sortie']}<br>")
                    @content.concat("<br>Décès          => #{properties['Date de Décès']}<br><br>")
                end #<IF3>
            end #<IF2>
            break   if sch_flag == true                     #exit loop
        else #<IF1>
            _com.step("4B-REF:#{member} => Not a page")
            break
        end #<IF1>
    end #<L1>

    #
    #                   -2-Updates / forms
    #                   ==================
    _com.step("2A-Get UPD Fields")
    result  = _upd.getDbFields()
    upd_fields  = result['data']                        #{code=>,fields=>[]}
    _com.debug("2B-Fields: #{upd_fields}")

    _com.step("3-Yield block <<<<<Forms/Updates>>>>>")
    _com.step("*")
    upd_filter  = {
        'and'=> [
            {'property'=> 'Référence', 'title'=>{'contains'=>_member}}
        ]
    }
    upd_sort    = [
        {'property'=> 'Référence', 'direction'=> 'ascending'}
    ]
    fields  = ['ALL']                                   #array of fields requested or ALL, or ALL

    @content.concat("<table>")
    @content.concat("<caption>Formulaires<br>***********</caption>")
    @content.concat("<thead><tr>"+
                    "<th>Membre</th>"+
                    "<th>CDC</th><th>ActPrc</th><th>ActSecs</th>"+
                    "<th>EneoSport</th>"+
                    "<th>En/Hors</th><th>EnCours</th><th>Statut</th>"+
                    "<th>Modification</th>"+
                    "</tr></thead>"+
                    "<tbody>")

    _upd.runPages(upd_filter,upd_sort,fields) do |state,data|    #execute bloc on Notion class with filter, sort & properties
        #data => result function => all properties {field=>value,...}
        count_upd   += 1
        #   pp  data

        if state == true #<IF2>
            created_time = data['created_time']       #created time
            last_edited_time = data['last_edited_time'] #last edited time
            properties  = _upd.loadProperties(data,fields)

            member      = properties['Référence']
            _com.step("4A-REF:#{member}")
            if _dis.include?('R')    #<IF3>
                @content.concat("<br>Membre => #{member}<br>")
                properties.each do |prop| #<L4>                   #loop all properties
                    #   pp  prop
                    name    = prop[0]                       #extract name
                    value   = prop[1]                       #extract value
                    if name != "Référence"  #<IF5>
                        _com.step("4B-FIELD:#{name} => #{value}")
                        @content.concat("<br>#{name} => #{value}<br>")
                    end #<IF5>
                end #<L4>
            elsif _dis.include?('F') #<IF3>
                puts "<br>Votre Nom             =>#{properties['Votre nom']}<br>"
                puts "<br>Votre Activité        =>#{properties['Votra activité']}<br>"
                puts "<br>Votre Demande         =>#{properties['Votre demande']}<br>"
                puts "<br>Votre Date            =>#{properties['Votre date']}<br>"

                puts "<br>CDC                   => #{properties['CDC']}<br>"
                puts "<br>Activité Principale   => #{properties['ActivitéP']}<br>"
                puts "<br>Activité Secondaires  => #{properties['ActivitéS']}<br><br>"
                puts "<br>Cotisation            => #{properties['Cotisation']} - #{properties['Date de Paiement']}<br>"
                puts "<br>Eneo/Sport            => #{properties['EneoSport']}<br>"
                puts "<br>En Hors service       => #{properties['En/Hors']}<br>"
                puts "<br>En cours              => #{properties['EnCours']}<br>"
                puts "<br>Statut                => #{properties['Statut']}<br>"
                puts "<br>Date Modification     => #{properties['Date Modification']}<br>"

                @content.concat("<tr>")
                @content.concat("<td>#{properties['Référence']}</td>")
                @content.concat("<td>#{properties['CDC']}</td>")
                @content.concat("<td>#{properties['ActivitéP']}</td>")
                @content.concat("<td>#{properties['ActivitéS']}</td>")
                @content.concat("<td>#{properties['Cotisation']}</td>")
                @content.concat("<td>#{properties['EneoSport']}</td>")
                @content.concat("<td>#{properties['En/Hors']}</td>")
                @content.concat("<td>#{properties['EnCours']}</td>")
                @content.concat("<td>#{properties['Statut']}</td>")
                @content.concat("<td>#{properties['Date Modification']}</td>")
                @content.concat("</tr>")
            end #<IF3>
        else    #<IF2>
            _com.step("4B-REF:#{member} => Not a page")
            break
        end
    end #<L1>
    @content.concat("</tbody>")
    @content.concat('<tfoot><tr><th scope="row" colspan="2">Nombre : </th>')
    @content.concat("<td>#{count_upd}</td></tr></tfoot>")
    @content.concat("</table>")

    #
    #                   -3-Modifications records
    #                   ========================
    _com.step("2A-Get MOD Fields")
    result  = _mod.getDbFields()
    mod_fields  = result['data']                        #{code=>,fields=>[]}
    _com.debug("2B-Fields: #{mod_fields}")

    _com.step("3-Yield block <<<<<Modifications>>>>")
    _com.step("*")
    mod_filter  = {
        'and'=> [
            {'property'=> 'Référence', 'title'=>{'contains'=>_member}}
        ]
    }
    mod_sort    = [
        {'property'=> 'Référence', 'direction'=> 'ascending'}
    ]
    fields  = ['ALL']                                   #array of fields requested or ALL, or ALL

    @content.concat("<table>")
    @content.concat("<caption>Modifications<br>*************</caption>")
    @content.concat("<thead><tr>"+
                    "<th>Membre</th><th>CDC</th><th>ActPrc</th><th>ActSecs</th>"+
                    "<th>Cotisation</th>"+
                    "<th>EneoSport</th>"+
                    "<th>En/Hors</th><th>EnCours</th><th>Statut</th>"+
                    "<th>Modification</th>"+
                    "</tr></thead"+
                    "<tbody>")

    _mod.runPages(mod_filter,mod_sort,fields) do |state,data|    #execute bloc on Notion class with filter, sort & properties
        #data => result function => all properties {field=>value,...}
        count_mod   += 1
        #   pp  data

        if state == true #<IF2>
            properties  = _mod.loadProperties(data,fields)

            member      = properties['Référence']
            _com.step("4A-REF:#{member}")
            if _dis.include?('R')    #<IF3>
                @content.concat("<br>Membre => #{member}<br>")
                properties.each do |prop| #<L4>                   #loop all properties
                    #   pp  prop
                    name    = prop[0]                       #extract name
                    value   = prop[1]                       #extract value
                    if name != "Référence"  #<IF5>
                        _com.step("4B-FIELD:#{name} => #{value}")
                        @content.concat("<br>#{name} => #{value}<br>")
                    end #<IF5>
                end #<L4>
            elsif _dis.include?('F') #<IF3>
                puts "<br>Votre Nom             =>#{properties['Votre nom']}<br>"
                puts "<br>Votre Activité        =>#{properties['Votre activité']}<br>"
                puts "<br>Votre Demande         =>#{properties['Votre demande']}<br>"
                puts "<br>Votre Date            =>#{properties['Votre date']}<br>"

                puts "<br>CDC                   => #{properties['CDC']}<br>"
                puts "<br>Activité Principale   => #{properties['ActivitéP']}<br>"
                puts "<br>Activité Secondaires  => #{properties['ActivitéS']}<br><br>"
                puts "<br>Cotisation            => #{properties['Cotisation']} - #{properties['Date de Paiement']}<br>"
                puts "<br>Eneo/Sport            => #{properties['EneoSport']}<br>"
                puts "<br>En Hors service       => #{properties['En/Hors']}<br>"
                puts "<br>En cours              => #{properties['EnCours']}<br>"
                puts "<br>Statut                => #{properties['Statut']}<br>"
                puts "<br>Date Modification     => #{properties['Date Modification']}<br>"

                @content.concat("<tr>")
                @content.concat("<td>#{properties['Référence']}</td>")
                @content.concat("<td>#{properties['CDC']}</td>")
                @content.concat("<td>#{properties['ActivitéP']}</td>")
                @content.concat("<td>#{properties['ActivitéS']}</td>")
                @content.concat("<td>#{properties['Cotisation']}</td>")
                @content.concat("<td>#{properties['EneoSport']}</td>")
                @content.concat("<td>#{properties['En/Hors']}</td>")
                @content.concat("<td>#{properties['EnCours']}</td>")
                @content.concat("<td>#{properties['Statut']}</td>")
                @content.concat("<td>#{properties['Date Modification']}</td>")
                @content.concat("</tr>")
            end #<IF3>
        else    #<IF2>
            _com.step("4B-REF:#{member} => Not a page")
            break
        end #<IF2>
    end #<L1>
    @content.concat("</tbody>")
    @content.concat('<tfoot><tr><th scope="row" colspan="2">Nombre : </th>')
    @content.concat("<td>#{count_mod}</td></tr></tfoot>")
    @content.concat("</table>")

    #
    #                   -4-Logging records
    #                   ==================
    _com.step("2A-Get LOG Fields")
    result  = _log.getDbFields()
    log_fields  = result['data']                        #{code=>,fields=>[]}
    _com.debug("2B-Fields: #{log_fields}")

    _com.step("3-Yield block <<<<<Loggings>>>>>")
    _com.step("*")
    log_filter  = {
        'and'=> [
            {'property'=> 'Référence', 'title'=>{'contains'=>_member}}
        ]
    }
    log_sort    = [
        {'property'=> 'Dernière modification', 'direction'=> 'descending'}
    ]
    fields  = ['ALL']                                   #array of fields requested or ALL, or ALL

    @content.concat("<table>")
    @content.concat("<caption>Logging<br>*******</caption>")
    @content.concat("<thead><tr>"+
                    "<th>Membre</th>"+
                    "<th>Modification</th>"+
                    "<th>Fonction</th>"+
                    "<th>Informations</th>"+
                    "<th>Infos privées</th>"+
                    "<th>Infos Eneo</th>"+
                    "</tr></thead>"+
                    "<tbody>")

    _log.runPages(log_filter,log_sort,fields) do |state,data|    #execute bloc on Notion class with filter, sort & properties
            #data => result function => all properties {field=>value,...}
        count_log   += 1
        #   pp  data

        if state 
            properties  = _log.loadProperties(data,fields)

            member      = properties['Référence']
            _com.step("4A-REF:#{member}")
            if _dis.include?('R')    #<IF3>
                @content.concat("<br>Membre => #{member}<br>")
                properties.each do |prop| #<L4>                   #loop all properties
                    #   pp  prop
                    name    = prop[0]                       #extract name
                    value   = prop[1]                       #extract value
                    if name != "Référence"  #<IF5>
                        _com.step("4B-FIELD:#{name} => #{value}")
                        @content.concat("<br>#{name} => #{value}<br>")
                    end #<IF5>
                end #<L4>
            elsif _dis.include?('F') #<IF3>
                puts "<br>Modification      =>#{properties['Dernière modification']}<br>"
                puts "<br>Fonction          =>#{properties['Fonction']}<br>"
                puts "<br>Informations      =>#{properties['Informations']}<br>"
                puts "<br>Infos privées     =>#{properties['Infos privées']}<br>"
                puts "<br>Infos Eneo        =>#{properties['Infos Eneo']}<br>"

                @content.concat("<tr>")
                @content.concat("<td>#{properties['Référence']}</td>")
                @content.concat("<td>#{properties['Dernière modification']}</td>")
                @content.concat("<td>#{properties['Fonction']}</td>")
                @content.concat("<td>#{properties['Informations']}</td>")
                @content.concat("<td>#{properties['Infos privées']}</td>")
                @content.concat("<td>#{properties['Infos Eneo']}</td>")
                @content.concat("</tr>")
            end #<IF3>
        else    #<IF2>
            _com.step("4B-REF:#{member} => Not a page")
            break
        end
    end #<L1>
    @content.concat("</tbody>")
    @content.concat('<tfoot><tr><th scope="row" colspan="2">Nombre : </th>')
    @content.concat("<td>#{count_log}</td></tr></tfoot>")
    @content.concat("</table>")

    #
    # Create pdf
    #+++++++++++
    _com.step("5-Create pdf")
    @content.concat("<br><br>*****End*****<br>")

    #pp  @content

    pdf_body    = "<body> #{@content} </body>"
    html        = "#{pdf_header} #{pdf_body}"
    _pdf        = PDFKit.new(html)
    _pdf.to_file(filepflog)

    #Display counters
    #================
    _com.step("6-Counters::Members:#{count_mbr} Updates:#{count_upd} Modifications:#{count_mod} Logs:#{count_log}")
    _com.exit("Bye bye")
#<EOS>