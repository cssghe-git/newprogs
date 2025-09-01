#
=begin
    Progr:      EneoBwCom_ExtSecr6
    Function:   extract records from MembersV24 table for Office
    Build:  4.1.1   <250516-0637>  

    Input:      Members table
    Output:     File : CDC-ListeMembres_All-Envoi.xlsx

    Parameters:
        P1: debug   => Y or N 
        P2: mode    => L or E
        P3: activity    => All
        
=end
#
#require gems
require 'rubygems'
require 'net/http'
require 'net/smtp'
require 'timeout'
require 'rubyXL'
require 'rubyXL/convenience_methods'
require 'uri'
require 'json'
require 'csv'
require 'pp'
require 'notion-ruby-client'
#
    require_dir = Dir.pwd
require "#{require_dir}/ClDirectories.rb"
#
    exec_mode   = 'P'                                   #change B or P
    _dir    = Directories.new('N')
    arrdirs = _dir.otherDirs(exec_mode)                 #=>{exec,private,membres,common,send,work}
require "#{arrdirs['common']}/ClCommon_2.rb"
    _com    = Common_2.new(false)
#
    send_dir        = arrdirs['send']
#
    Dir.chdir(arrdirs['membres'])
    require_dir = Dir.pwd
    puts    "dirREQUIRE:"+require_dir
require "#{require_dir}/mdEneoBwCom.rb"
#
#Internal functions
#++++++++++++++++++
#
    def setDates(p_date='')
    #===========
    #INP::  p_date => date to reverse
    #OUT::  new date format
        return  if p_date.size == 0
        aaaa    = p_date[0,4]
        mmmm    = p_date[5,2]
        jjjj    = p_date[8,2]
        return  "#{jjjj}/#{mmmm}/#{aaaa}"
    end
#
#Parameters
#++++++++++
    _debug  = ARGV[0]       #debug  Y, N
    _mode   = ARGV[1]       #mode
    _file   = ARGV[2]       #file : only activity part

    _debug  = _debug.upcase
#
#Variables
#+++++++++
#
    program = "EneoBwCom_ExtSecr6"
    integr  = 'secret_2XXOYzX5JThHqZviHGZpPna5ihVU2o3knCvrCu76RjS'  #EneoBW
    mbrid   = '19ae0e553d938007b793fc4e7e74e666'    #members24 db   https://www.notion.so/eneobw/19ae0e553d938007b793fc4e7e74e666?v=19ae0e553d93819e95fb000ce1280044&pvs=4

    count_blocks    = 0
    count_pages     = 0
    count_xl        = 0

    listsel         = 2
    count_activities    = {     #[activity, count,cot17]
        'NIV-Amicale_des_Archers'=>[0,0],
        'NIV-Aquagym_1'=>[0,0],
        'NIV-Aquagym_2'=>[0,0],
        'NIV-Aquagym_3'=>[0,0],
        'NIV-Art_Floral'=>[0,0],
        'NIV-Danse'=>[0,0],
        'NIV-Dessin'=>[0,0],
        'NIV-Gymnastique_1'=>[0,0],
        'NIV-Gymnastique_2'=>[0,0],
        'NIV-Informatique'=>[0,0],
        'NIV-Marcheurs_du_Jeudi'=>[0,0],
        'NIV-Marche_Nordique'=>[0,0],
        'NIV-Pilates'=>[0,0],
        'NIV-Randonneurs_du_Brabant'=>[0,0],
        'NIV-Scrapbooking'=>[0,0],
        'NIV-TaiChi'=>[0,0],
        'NIV-Tennis_de_Table'=>[0,0],
        'NIV-Vie_Active'=>[0,0],
        'NIV-EXT'=>[0,0],
        'System'=>[0,0]
    }

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
#
#Main code
#+++++++++
#   Initialisations
#   ===============
    timefrom    = Time.now.to_i
    t           = Time.now
    month       = t.month
    day         = t.day
    envdate     = "_#{month}-#{day}"

    #Get filter values
    prms        = EneoBwCom.filters('N','N')   #{CDC=>?,ActCDC,Activity=>[num,txt],EnCours,Cotisation,Cnci,V-A}
    ### pp prms
    #mbrid       = prms[0]
    selcdc      = prms['CDC']
    actcdc      = prms['ActCDC']
    selact      = prms['Activity']
    actnum      = selact[0].to_i
    acttxt      = selact[1]
    selEnCours  = 'Y'
    selcotis    = 99
    selcnci     = '?'
    selsgm      = 'Y'
    selva       = ''

    activity    = "#{actcdc}-#{acttxt}"                             #activity in use or ALL for all activities
    
    puts ">>>Invalid choice, bye bye"   if actnum == 0
    exit 5                              if actnum == 0
    actnum      = 0     if acttxt == 'ALL'

    _file       = acttxt    if _file == 'X'
    filewrite   = "#{send_dir}/#{actcdc}-ListeMembres_#{_file}-Envoi#{envdate}.xlsx"
    filetitle   = "#{actcdc}-ListeMembres_#{_file}-Envoi.xlsx"

    #Starting
    _com.start(program,"Debug:#{_debug} Filters:#{prms} File:#{filewrite}")

    #Create xlsx file
    _com.step("1::Create workbook")
    workbook                = RubyXL::Workbook.new
    worksheet               = workbook[0]
    worksheet.sheet_name    = 'Membres24'

    #Notion
    _com.step("2::Create Notion")
    Notion.configure do |config|
        config.token = integr
    end
    #Client instances
    mbrcli  = Notion::Client.new

    #
    #Make filter
    #===========
    #
    _com.step("3A::Create filter body")
    prms    = [
                selcdc,
                actcdc,
                selact,
                selEnCours,
                selcnci,
                selcotis
    ] 
    body2   = EneoBwCom.body(prms)
    _com.step("3B::Filter body::#{body2}")
    ### pp body2
    ###exit 999
    _com.step("3C::SELCT::CDC:#{selcdc}-ACT:#{selact}")
    #
    #Make sort
    #=========
    sort    = [
    #    {'property'=> 'CDC', 'direction'=> 'ascending'},
        {'property'=> 'Référence', 'direction'=> 'descending'}
    ]
    #
    #settings XL
    #===========
    #settings columns width
    _com.step("4::Settings worksheet")
    worksheet.change_column_width(0, 10)        #seagma
    worksheet.change_column_width(1, 30)        #nom
    worksheet.change_column_width(2, 10)        #prénom
    worksheet.change_column_width(3, 10)        #naissance
    worksheet.change_column_width(4, 40)        #adresse
    worksheet.change_column_width(5, 10)        #téléphone
    worksheet.change_column_width(6, 10)        #gsm
    worksheet.change_column_width(7, 20)        #mail
    worksheet.change_column_width(8, 10)        #cotisation-1
    worksheet.change_column_width(9, 10)        #cotisation-2
    worksheet.change_column_width(10, 10)       #CPE
    worksheet.change_column_width(11, 10)       #eneo
    worksheet.change_column_width(12, 10)       #eneosport
    worksheet.change_column_width(13, 10)       #v-a
    worksheet.change_column_width(14, 10)       #cdc pr
    worksheet.change_column_width(15, 10)       #cdc sec
    worksheet.change_column_width(16, 10)       #nouveau
    worksheet.change_column_width(17, 10)       #modification
    worksheet.change_column_width(18, 10)       #arrêt
    worksheet.change_column_width(19, 10)       #décès
    worksheet.change_column_width(20, 15)       #ActPrc for checks
    #setting title
    worksheet.insert_row(0)
    worksheet.change_row_height(0,20)
    worksheet.change_row_bold(0,true)
    worksheet.add_cell(0,0,filetitle)
    worksheet.merge_cells(0, 0, 0, 20)
    #settings fields
    worksheet.insert_row(1)
    worksheet.change_row_height(1,20)
    worksheet.add_cell(1,0,'Seagma')
    worksheet.add_cell(1,1,'Nom')
    worksheet.add_cell(1,2,'Prénom')
    worksheet.add_cell(1,3,'Naissance')
    worksheet.add_cell(1,4,'Adresse')
    worksheet.add_cell(1,5,'Téléphone')
    worksheet.add_cell(1,6,'Gsm')
    worksheet.add_cell(1,7,'Mails')
    worksheet.add_cell(1,8,'Cotis-1')
    worksheet.add_cell(1,9,'Cotis-2')
    worksheet.add_cell(1,10,'CPE')
    worksheet.add_cell(1,11,'Eneo')
    worksheet.add_cell(1,12,'EneoSport')
    worksheet.add_cell(1,13,'V-A')
    worksheet.add_cell(1,14,'CDC Pr')
    worksheet.add_cell(1,15,'CDC Sc')
    worksheet.add_cell(1,16,'Nouveau')
    worksheet.add_cell(1,17,'Modif.')
    worksheet.add_cell(1,18,'Ancien')
    worksheet.add_cell(1,19,'Décès')
    worksheet.add_cell(1,20,'ActPrc')

    #Init fields
    valcdc          = ''
    valcdcpr        = ''
    valcdcsc        = ''
    valreference    = ''
    valnom          = ''
    valprenom       = ''
    valcivilite     = ''
    valadresse      = ''
    valcanton       = ''
    vallocalite     = ''
    valgsm          = ''
    valtelephone    = ''
    valmail         = ''
    valnaissance    = ''
    valcotis        = ''
    valcotis1       = ''
    valcotis2       = ''
    valeneo         = ''
    valeneosport    = ''
    valcpe          = ''
    valactp         = ''
    valacts         = ''
    valseagma       = ''
    valentree      = ''
    valpaiement    = ''
    valsortie      = ''
    valdeces       = ''
    valva           = ''
    valpaiemcheck     = ''
    valsecrcheck    = ''

    flagnouveau      = ''
    flagmodif        = ''
    flagancien       = ''
    flagdeces        = ''

    valsecr        = ''
    valstatut       = ''
    valetat         = ''

    row         = 2
    flagdupl    = 0

    #
    #Loop all records
    #================
    _com.step("5A::Get Mbr records")

    mbrcli.database_query(database_id: mbrid, filter: body2, sorts: sort) do |mbrresult| #<L0>
        count_blocks += 1
        _com.step("5B::Block N° #{count_blocks}")
        mbrdata = mbrresult['results']

        mbrdata.each do |page|      #<L1>                               #extract 1 page
            count_pages     += 1
            _com.step("6::Page N° #{count_pages}")  if _debug   == 'Y'
            pp  page                                if _debug == 'Y'
            mbrproperties   = page['properties']                        #extract properties
            checkref        = mbrproperties['Référence']

            mbrproperties.each do |property|    #<L2>                   #loop all properties
                pp property                         if _debug   == 'Y'
                name    = property[0]
                value   = EneoBwCom.extrProperty('None',property)       #extract property value
                #extract all fields
                next    if value == 'None'

                case name   #<SW3>
                when 'CDC' #<SW3>
                        valcdc  = value.upcase
                        if valcdc == "NIV"
                            valcdcpr    = valcdc
                            valcdcsc    = ""
                        else
                            valcdcpr    = ""
                            valcdcsc    = valcdc
                        end

                when 'Référence' #<SW3>
                    break   if value.size == 0 or value == 'None'    #Title must not be empty
                    valreference    = value
                    puts "Ref: #{value}"            if _debug   == 'Y'
                    pos = value.index('-')
                    if pos.size == 0
                        nom = value[0,99]
                        pre = 'xyz'
                    else
                        nom     = value[0,pos]
                        pre     = value[pos+1,99]
                        pos2    = pre.index('-')
                        pre     = pre[0,pos2]   if pos2.size == 0
                    end
                    valnom      = nom
                    valprenom   = pre

                when 'Civilité' #<SW3>
                    valcivilite = value

                when 'Rue + Numéro/Boite' #<SW3>
                    valadresse  = value

                when 'Code postal' #<SW3>
                    valcanton   = value

                when 'Localité' #<SW3>
                    vallocalite = value

                when 'Gsm' #<SW3>
                    valgsm  = value

                when 'Téléphone' #<SW3>
                    valtelephone    = value

                when 'Mail' #<SW3>
                    valmail = value

                when 'Date de Naissance' #<SW3>
                    valnaissance    = setDates(value[0])    if value != 'None'
                    puts    "DBG>PROP.NAME:#{name} : #{value} FOR:#{checkref}"     #if _debug == 'Y'

                when 'Cotisation' #<SW3>
                    valcotis    = value.to_i
                    if  valcotis == 0
                        valcotis1   = 0
                        valcotis2   = 0
                    elsif   valcotis == 9
                        valcotis1   = 0
                        valcotis2   = 9
                    elsif   valcotis == 17
                        valcotis1   = 17
                        valcotis2   = 0
                    else
                        valcotis1   = 0
                        valcotis2   = 0
                    end

                when 'EneoSport' #<SW3>
                    valeneo = value
                    if valeneo == "Eneo"
                        valeneosport    = ''
                    elsif   valeneo == "EneoSport"
                        valeneosport    = valeneo
                        valeneo         = ''
                    else
                    end

                when 'Cotisant/Participant/Extérieur'
                    valcpe  = value

                when 'ActivitéP' #<SW3>
                    valactp = value

                when 'AllActs' #<SW3>
                    pos     = value.index('#')
                    part2   = value[pos+1,99]
                    valacts = part2

                when "Date d'Inscription" #<SW3>
                    valentree   = setDates(value[0])    if value != 'None'
                    puts    "DBG>PROP.NAME:#{name} : #{value} FOR:#{checkref}"     #if _debug == 'Y'

                when 'Date de Paiement' #<SW3>
                    if value != 'None' and value.size == 0
                        valpaiement     = value[0]
                        valpaiemcheck   = valpaiement[0,10]
                        valpaiement     = setDates(valpaiement[0,10])
                        puts    "DBG>PROP.DATPAIEM:#{name} : #{value} - #{valpaiemcheck} FOR:#{checkref}"     #if _debug == 'Y'
                    end

                when 'Date de Sortie' #<SW3>
                    valsortie   = setDates(value[0])    if value != 'None'
                    puts    "DBG>PROP.NAME:#{name} : #{value} FOR:#{checkref}"     #if _debug == 'Y'

                when 'Date de Décès' #<SW3>
                    if value != 'None' and value.size == 0
                        valdeces   = setDates(value[0])
                    end
                    puts    "DBG>PROP.NAME:#{name} : #{value} FOR:#{checkref}"     #if _debug == 'Y'

                when 'DateSecr.'
                    flagdupl    =+ 1
                    if flagdupl > 1
                        pp  mbrproperties
                    end
                    puts    "DBG>PROP.NAME:#{name} : #{value} FOR:#{checkref}"     #if _debug == 'Y'
                    if value != 'None' and value.size == 0
                        valsecr         = value[0]
                        valsecrcheck    = valsecr[0,10]
                        valsecr         = setDates(valsecr[0,10])
                        puts    "DBG>PROP.DATSECR:#{name} : #{value} - #{valsecrcheck} FOR:#{checkref}"     #if _debug == 'Y'
                    end

                when 'V-A' #<SW3>
                    valva   = value

                when 'Statut'
                    valstatut   = value

                when 'Etat'
                    valetat = value

                when 'Seagma'
                    valseagma   = value

                when 'Date de création'
                when 'Date Modification'

                end #<SW3>
            end #<L2>

            #check filters
            #check cdc
            if selcdc == 'ALL'
                _com.step("7A::Exit cdc: #{selcdc} -> #{valcdc}")     if _debug   == 'Y'
                next    if valcdc != 'NIV'
            end
            #check act
            if actnum > 0 and actnum < 19
                if valactp != activity
                    _com.step("7B::Exit act: #{activity} -> #{valactp}-#{valacts}")   if _debug   == 'Y'
                    next   if not valacts.include?(activity)
                end
            end
            #check cotisation
            if selcotis != 99
                _com.step("7E::Exit cotis: #{selcotis} -> #{valcotis}")   if _debug   == 'Y'
                next   if valcotis != selcotis
            end
            _com.step("7F::REF:: #{valreference} #{valcdc}")     if _debug   == 'Y'
            count_xl    += 1

        #    next

            #compose
            _com.step("MEMBRE: #{valreference} processing with STATUT:#{valstatut} ETAT:#{valetat} DATES:#{valpaiement}-#{valsecr}-#{valdeces}")
            @content.concat("<br>MEMBRE: #{valreference} processing with STATUT:#{valstatut} ETAT:#{valetat} DATES:#{valpaiement}-#{valsecr}-#{valdeces}<br>")
            #composition
            valadresse  = "#{valadresse} #{valcanton} #{vallocalite}"

            #logique
            flagok      = false
            newetat     = ''
            flagancien   = ''
            flagnouveau  = ''
            flagmodif    = ''
            flagdeces    = ''

            case    listsel #<SW4>
            when    1   #<SW4>
            when    2
                if valsecr.size > 0 and valsecr != 'None'
                    if valcotis.to_i > 0 and valpaiement.size == 0 and valsecrcheck > "2025-03-01"
                        puts    "DBG>>MODIF::COTIS:#{valcotis} PAIEM:#{valpaiement}"
                        flagmodif    = 'Y'
                        flagok  = true
                        newetat = "En Cours"
                    end
                end

                if valetat == "No Update" or valetat == "En Cours"
                    if valcotis.to_i > 0 and valpaiement.size > 0
                        flagok  = true
                        newetat = "En Cours"
                    end
                end

                if valetat == "Nouveau" or valstatut == "Nouveau"
                    if valcotis.to_i > 0 and valpaiement.size > 0 and valpaiemcheck > "2025-03-01"
                        puts    "DBG>>NOUVEAU::COTIS:#{valcotis} PAIEM:#{valpaiement}"
                        flagnouveau  = 'Y'
                        flagok  = true
                        newetat = "En Cours"
                    end
                end

                if valdeces != 'None' and valdeces.size > 0
                    puts    "DBG>>DECES:#{valdeces} #{valdeces.size}"
                    if valcotis.to_i > 0 and valpaiement.size > 0 and valpaiemcheck > "2025-03-01"
                        puts    "DBG>>DECES::COTIS:#{valcotis} PAIEM:#{valpaiement} DECES:#{valdeces}"
                        flagdeces    = 'Y'
                        flagok  = true
                        newetat = "Décès"
                    end
                end

            when    3,4
            end #<SW4>                

            #add to worksheet
            if flagok   #<IF4>
                _com.step("7F::ToXL:: #{valreference}")     if _debug   == 'Y'
                count_xl    += 1

                #add to worksheet
                worksheet.insert_row(row)                       #add row
                worksheet.change_row_height(row,20)

                worksheet.add_cell(row,0,valseagma)
                worksheet.add_cell(row,1,valnom)
                worksheet.add_cell(row,2,valprenom)
                worksheet.add_cell(row,3,valnaissance)
                worksheet.add_cell(row,4,valadresse)
                worksheet.add_cell(row,5,valtelephone)
                worksheet.add_cell(row,6,valgsm)
                worksheet.add_cell(row,7,valmail)
                worksheet.add_cell(row,8,valcotis1)
                worksheet.add_cell(row,9,valcotis2)
                worksheet.add_cell(row,10,valcpe)
                worksheet.add_cell(row,11,valeneo)
                worksheet.add_cell(row,12,valeneosport)
                worksheet.add_cell(row,13,valva)
                worksheet.add_cell(row,14,valcdcpr)
                worksheet.add_cell(row,15,valcdcsc)
                worksheet.add_cell(row,16,flagnouveau)
                worksheet.add_cell(row,17,flagmodif)
                worksheet.add_cell(row,18,flagancien)
                worksheet.add_cell(row,19,flagdeces)
                worksheet.add_cell(row,20,valactp)
                workbook.write(filewrite)

                #update page
                newfilter = {
                    'Etat'=> {'select'=> {'name'=> newetat}},
                    'DateSecr.'=> {'date'=>{'start'=>""}}
                }
                if _mode == "E" #<IF5>
                    rc  = mbrcli.updPage(pg_id,newfilter)
                    _com.step("UPD:: #{valreference}")
                else    #<IF5>
                    _com.step("LOG1:: REF:#{valreference} ACTPRC:#{valactp} - STATUT:#{valstatut} ETAT:#{newetat} - FLAGS:: OK:#{flagok} NOV:#{flagnouveau} MOD:#{flagmodif} ANC:#{flagancien} DEC:#{flagdeces}")
                    @content.concat("<br>LOG1:: #{valreference} processing with STATUT:#{valstatut} ETAT:#{valetat} => #{newetat} - FLAGS:: OK:#{flagok} NOV:#{flagnouveau} MOD:#{flagmodif} ANC:#{flagancien} DEC:#{flagdeces}<br>")
                end #<IF5>
            else    #<IF4>
                _com.step("LOG2:: REF:#{valreference} ACTPRC:#{valactp} - STATUT:#{valstatut} ETAT:#{newetat} - FLAGS:: OK:#{flagok} NOV:#{flagnouveau} MOD:#{flagmodif} ANC:#{flagancien} DEC:#{flagdeces}")
            end #<IF4>

            #Init vars
            valadresse      = valcanton = vallocalite = valgsm = valtelephone = valmail = ''
            valnaissance    = valcotis = valeneo = valva = ''
            valactp         = valacts = valseagma = ''
            valentree       = valsortie = valdeces = ''
            flagdupl        = 0
        end #<L1>
    end #<L0>
    workbook.write(filewrite)
    #
    #End of program
    #==============
    text    = "For ACT: #{activity} with MODE: #{_mode} Counters:: Blocks:#{count_blocks} Pages:#{count_pages} - XL:#{count_xl}"
    _com.stop(program,"#{text}")
    #
#<EOS>
