#
=begin
    Progr:      EneoBwCom_AddMBR4
    Function:   add requests to Members table
    Build:      2-5-1   <250209-1035>
    Call:       ruby EneoBwCom_AddMBR4.rb   N E X cdc
    Input:      csv file
    Output:     Members table
    Parameters:
        P1: debug => N or Y
        P2: mode => E for exec OR L for log
        P3: filename to read (activity only) or X
        P4: CDC or ALL
    explains:
        mode = E => exec
        mode = L => log
=end
#
#require gems
require 'rubygems'
require 'net/http'
require 'net/smtp'
require 'timeout'
require 'uri'
require 'json'
require 'csv'
require 'pp'
require 'notion-ruby-client'
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
#Parameters
#++++++++++
    _debug  = ARGV[0]       #debug
    _mode   = ARGV[1]       #mode
    _file   = ARGV[2]       #file : only activity part
    _cdc    = ARGV[3]       #cdc

    _debug  = _debug.upcase
    _debug  = true  if _debug == 'Y'
    _debug  = false if _debug == 'N'
    _mode   = _mode.upcase
#
#***** Exec environment *****
# Start of block
    program = 'EneoBwCom_AddMbr4'
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
    process_dir = arrdirs['process']
require "#{arrdirs['common']}/ClNotion_2.rb"
  
# End of block
#***** Exec environment *****
#
    Dir.chdir(member_dir)
require "#{member_dir}/mdEneoBwCom.rb"
#

#
#Internal functions
#++++++++++++++++++
#
    #read 1 line & transform to hash
    def readCsvLine(p_row=[])
        #++++++++++++++
        #   INP::   row array 1 string to split(;)
        #   OUT::   row hash into @csv_array
            #check
            return  false   if p_row.length == 0
            p_row   = p_row[0]                  #extract string
            row     = p_row.split(";")          #split into fields
            #load array
            @csv_array  = {}                    #clear array
            @csv_fields.each do |field| #<L1>   #load array
                name    = field[0]
                index   = field[1]
                type    = field[2]
                value   = row[index]            #if conversion
                puts    "DBG>>Fields::NAME:#{name}-INDEX:#{index}-TYPE:#{type}-VAL:#{value}"
                case    type    #<SW2>
                when    'T'     #<SW2>
                    value   = "*"   if value.nil? or value.size == 0
                    row[index]  = value
                when    'D'     #<SW2>
                    value   = "*"   if value.nil? or value.size == 0
                    value   = "#{value[6,4]}-#{value[3,2]}-#{value[0,2]}"   if value!='*'
                    row[index]  = value
                when    'I'
                    value   = "*"   if value.nil? or value.size == 0
                    row[index]  = value
                    point   = value.index('.')
                else
                    row[index]  = value
                end #<SW2>
                @csv_array[name]    = row[index]    #add entry {name=>value}
            end #<L1>
           #
           return   true
        end #<def>
#
#Variables
#+++++++++
#
    arrfields   = ['object','id','created_time','last_edited_time','properties']
    arrprops    = ['Référence','Auteur','Texte']
    arrblocks   = []

    integr      = 'secret_2XXOYzX5JThHqZviHGZpPna5ihVU2o3knCvrCu76RjS'
    repnext     = 'N'
    actprc      = ""
    index       = 0
    x_actsec0   = 0
    x_actsecs   = ""
    x_actsec1   = ""
    x_actsec2   = ""
    x_actsec3   = ""
    x_actsec4   = ""
    x_actsec5   = ""
    y_actsec0   = 0
    y_actsecs   = ""
    y_actsec1   = ""
    y_actsec2   = ""
    y_actsec3   = ""
    y_actsec4   = ""
    y_actsec5   = ""

    count_rec       = 0
    count_next      = 0
    count_mbrok     = 0
    count_cotok     = 0
    count_mbradd    = 0
    count_cotadd    = 0
    count_syntax    = 0
    count_stop      = 5

    mbrproperties   = {}
    mbrfields       = {}
    mbrpageid       = ''

    arrcdc          = []

#   csv infos
    @csv_fields     = [
        ['Statut',0,'T'],
        ['Référence',1,'T'],
        ['CDC',2,'T'],
        ['Civilité',3,'T'],
        ['Nom',4,'T'],
        ['Prénom',5,'T'],
        ['Adresse',6,'T'],
        ['Canton',7,'T'],
        ['Ville',8,'T'],
        ['GSM',9,'T'],
        ['Téléphone',10,'T'],
        ['Mails',11,'T'],
        ['Date Naissance',12,'D'],
        ['Cotisation',13,'I'],
    #    ['Certificat',14,'T'],
        ['EneoSport',14,'T'],
        ['ActPrc',15,'T'],
        ['ActSecs',16,'T'],
        ['Date Entrée',17,'D'],
        ['Date Paiement',18,'D'],
        ['Date Sortie',19,'D'],
        ['Date Décès',20,'D'],
        ['V-A',21,'T']
    ]
    @csv_array      = {}
    @csv_statements = []
#
#Main code
#+++++++++
#   Initialisation
#   ==============
    timefrom    = Time.now.to_i

    #Get values
    currentcdc  = "NIV"     #_cdc
    currentcdcx = currentcdc + "-"
    #
    #
    #get values for this cdc
    item   = EneoBwCom.load(currentcdc)     #[mbrid,modid,logid,[cdc,act,f_fields],arrcdc]
    mbrid   = item[0]                                           #members db
    mbrid   = '19ae0e553d938007b793fc4e7e74e666'    #https://www.notion.so/eneobw/19ae0e553d938007b793fc4e7e74e666?v=19ae0e553d93819e95fb000ce1280044&pvs=4
                                                    #https://www.notion.so/eneobw/19ae0e553d938007b793fc4e7e74e666?v=19ae0e553d93810299df000cac2c60ae&pvs=4
    values  = item[3]
    arrcdc  = item[4]

    arract  = values[1]                                         #activities for this cdc
    arrf_   = values[2]                                         #fields position
    #
    item    = EneoBwCom.reqAct(currentcdc)                      #request activity
    actnum  = item[0]                                           #number
    acttxt  = item[1]                                           #text
    activity    = "#{currentcdcx}#{acttxt}"                     #activity in use
    puts "DBG>Act:: Num: #{actnum} Txt: #{acttxt} => #{activity}"   if _debug == 'Y'
    exit 5                  if actnum == 0
    _file       = acttxt    #if _file == 'X'                    #file in use

    #make filename
    fileread    = "#{process_dir}/#{currentcdcx}ListeMembres_#{_file}-Retour.csv"
    #
    #Starting
    _com.start(program," with Debug:#{_debug} Mode:#{_mode} Activity:#{activity} File:#{fileread}")
    _com.step("1-Initialize")

    #Check file
    rc  = File.file?(fileread)
    if rc == false
        _com.step(">>>File doesn't exist")
        exit 1
    end

    #Notion token
    Notion.configure do |config|
        config.token = integr
    end
    #Client instances
    mbrcli  = Notion::Client.new
    #
#
#   Loop all rows & columns
#   =======================
    _com.step("2-Extract all rows")
    csv_flag    = false                                         #to skip 1st line (titles)
    CSV.foreach(fileread) do |row|     #<L1> => @csv_array
        if csv_flag #<IF2>
            if  readCsvLine(row)    #<IF3>
                puts    "DBG>>CSV:#{@csv_array}"    #if _debug == 'Y'
                if @csv_array['Statut'] == 'Statut' #iF4>
                else    #<IF4>
                    @csv_statements.push(@csv_array)                #add to statements
                end #<IF4>
            end #<IF3>
        else    #<IF2>
            csv_flag    = true
            next
        end #<IF2>
    end #<L1>

    #exit 9

    _com.step("3-Check all rows")
    @csv_statements.each do |statement| #<L1>loop all statements
        count_rec   += 1

        #get fields (cols)
        #+++++++++++++++++
        #checks
        x_reference = statement['Référence'].strip
        if x_reference == "*"  #<IF2>
            break   #cancel iteration <L1>
        end #<IF2>
        #
        x_statut    = statement['Statut']
        x_statut    = x_statut.strip.capitalize
        if x_statut == "*"      #<IF2>
            count_next  += 1
            next    #go to next iteration
        end #<IF2>

        #OK - make flags
        flagupdate  = false
        flagupdate  = true  if x_statut == 'Nouveau' or x_statut == 'Modification'
        flagout     = false
        flagout     = true  if x_statut == 'Suppression'
        flagstop    = false
        flagstop    = true  if x_statut == 'Arrêt'
        flagdead    = false
        flagdead    = true  if x_statut == 'Décès'

        #load fields from csv
        #++++++++++++++++++++
        x_cdc           = statement['CDC']
        x_civilite      = statement['Civilité']
        x_adresse       = statement['Adresse']
        x_canton        = statement['Canton']
        x_localite      = statement['Ville']
        x_gsm           = statement['GSM']
        x_telephone     = statement['Téléphone']
        x_mail          = statement['Mails']
        x_naissance     = statement['Date Naissance']
        x_cotisation    = statement['Cotisation']
        x_eneo          = statement['EneoSport']
        x_entree        = statement['Date Entrée']
        x_paiement      = statement['Date Paiement']
        x_sortie        = statement['Date Sortie']
        x_deces         = statement['Date Décès']
        x_actprc        = statement['ActPrc']
        x_actsecs       = statement['ActSecs']
        x_va            = statement['V-A']
        #update for erors
        x_actprc        = x_actprc.strip
    #    x_actprc        = x_actprc.titleize
        if x_actsecs    != '*'
            x_actsecs   = x_actsecs.strip
    #        x_actsecs   = x_actsecs.titleize
        end

        #
        #Print for checks
        #++++++++++++++++
        puts    "DBG>Checks::   Ref:#{x_reference} for #{x_statut}"
        puts    "               ACT:#{x_actprc} - #{x_actsecs}"
        puts    "               ADR:#{x_adresse}-#{x_canton}-#{x_localite}"
        puts    "               COM:#{x_gsm}-#{x_telephone}-#{x_mail}"
        puts    "               DATES:#{x_naissance} #{x_entree} #{x_paiement} #{x_sortie} #{x_deces}"
        puts    "               CCE:#{x_cotisation}-#{x_eneo}"
        puts    "               FLAGS::UPD:#{flagupdate} OUT:#{flagout} STOP:#{flagstop} DEAD:#{flagdead}"

        #make activités secondaires
        #++++++++++++++++++++++++++
        x_actsec0   = 0
        x_actsec1   = ''
        x_actsec2   = ''
        x_actsec3   = ''
        x_actsec4   = ''
        x_actsec5   = ''
        if x_actsecs != "*" #<IF2>
            res = EneoBwCom.split(x_actsecs," ")
            puts "DBG>Split: #{res}"                            if _debug == 'Y'
            x_actsec0   = res[0]                                #count of values
            items       = res[1]                                #["value,value,..."]
            items       = items[0]
            if x_actsec0 > 0   #<IF3> values
                res = EneoBwCom.split(x_actsecs,'*',",")
                puts "DBG>Split: #{res}"                        if _debug == 'Y'
                x_actsec0   = res[0]                            #count of values
                items       = res[1]                            #["value,value,..."]
                index       = 1
                items.each do |actsec|  #<L4>
                    puts "DBG>Split-Act:: Index:#{index} Act:#{actsec}"      if _debug == 'Y'
                    case index  #<SW5>
                    when 1  #<SW5>
                        x_actsec1 = actsec
                    when 2
                        x_actsec2 = actsec
                    when 3
                        x_actsec3 = actsec
                    when 4
                        x_actsec4 = actsec
                    when 5
                        x_actsec5 = actsec
                    end #<SW45
                    index   += 1
                end #<L4>
            end #<IF3>
        end #<IF2>
 
        #check Prc or Sec
        #++++++++++++++++
        flagprinc   = false
        flagprinc   = true      if activity == x_actprc

        #make CPE
        #++++++++
        if x_cdc == "EXT"   #<IF2>#exterieur
            x_cpe   = 'Extérieur'                               #default
        else    #<IF2>#BW
            if x_cdc == currentcdc  #<IF3>#me
                x_cpe   = 'Cotisant'
            else    #<IF3>#other
                x_cpe   = 'Participant'
            end #<IF3>
        end #<IF2>
        _com.step(">>>STATEMENT:: Ref: #{x_reference} Statut: #{x_statut} FLAGS::#{flagupdate}-#{flagout}-#{flagdead}-#{flagprinc}")

        #make filter to check Member
        #+++++++++++++++++++++++++++
        mbrfilter  = {
            'and'=> [
                {'property'=> 'RefID','formula'=> {'string'=> {'contains'=> x_reference}}}
            ]
        }
        _com.step(">>>REQ::Nom:#{x_reference},Demande:#{x_statut},CDC:#{x_cdc},ActPrc:#{x_actprc},ActSecs:#{x_actsecs},CPE:#{x_cpe}")

        #
        #Processing following flags
        #++++++++++++++++++++++++++
        if flagupdate   #<IF2>
            _com.step("3A-Update member")
            #some init
            y_actsec0   = 0
            y_actsec1   = ''
            y_actsec2   = ''
            y_actsec3   = ''
            y_actsec4   = ''
            y_actsec5   = ''

            #Check Member
            #++++++++++++
            _com.step(">>>Check MBR for #{x_reference}")        if _debug == 'Y'
            #get member
            mbrflag     = false
            mbrpageid   = ''
            mbrfields   = {}
            mbrresult   = mbrcli.database_query(database_id: mbrid, filter: mbrfilter)
            pp mbrresult                                        if _debug == 'Y'
            mbrdata     = mbrresult['results']
        
            #member exists or not
            #++++++++++++++++++++
            if mbrdata.length > 0     #<IF3>
                #member exists
                #+++++++++++++
                count_mbrok += 1
                _com.step(">>>MBR: #{x_reference} exists")
                mbrflag     = true
                mbrdata.each do |page|  #<L4>loop all pages
                    pp page                                     if _debug == 'Y'
                    #extract values
                    mbrpageid           = page['id']
                    mbrpagecreatedtime  = page['created_time']
                    mbrpageeditedtime   = page['last_edited_time']
                    mbrproperties       = page['properties']

                    #load fields from MBR
                    mbrproperties.each do |property|    #<L5>
                       mbrfields[property[0]] = EneoBwCom.extrProperty('None',property)
                    end #<L5>
                    pp  mbrfields                               if _debug == 'Y'

                    y_actsecs   = mbrfields['ActivitéS']
                    puts    "DBG>SplitA:#{y_actsecs} - #{y_actsecs.class}"  if _debug == 'Y'
                    res = EneoBwCom.split(y_actsecs,"*",",")    #split 
                    puts    "DBG>SplitB: #{res}"                if _debug == 'Y'
                    y_actsec0   = res[0]                        #count of values
                    if y_actsec0 > 0    #<IF5>
                        items   = res[1]                        #["value,value,..."]
                        index   = 1
                        items.each do |actsec|  #<L5>
                            puts "DBG>Split-Act:: Index:#{index} Act:#{actsec}"      #if _debug == 'Y'
                            case index  #<SW6>
                            when 1  #<SW6>
                                y_actsec1 = actsec
                            when 2
                                y_actsec2 = actsec
                            when 3
                                y_actsec3 = actsec
                            when 4
                                y_actsec4 = actsec
                            when 5
                                y_actsec5 = actsec
                            end #<SW6>
                            index   += 1
                        end #<L5>
                    end #<IF5>
                end #<L4>
            else    #<IF3>  
                #member doesn't exists
                #+++++++++++++++++++++
                _com.step(">>>MBR: #{x_reference} does not exists")
                #add page to MBR
                count_mbradd    += 1
                mbrdata         = []
                mbrproperties = {
                    'Référence'=>   {'title'=> [{'text'=> {'content'=> x_reference}}]},
                    'Civilité'=>    {'select'=> {'name'=> x_civilite}},
                    'Cotisation'=>  {'select'=> {'name'=>"0"}},
                    'CPE'=>         {'select'=> {'name'=> x_cpe}},
                    'CDC'=>         {'select'=> {'name'=> x_cdc}}
                }
                #=>=>=>
                if _mode == 'E'
                    mbrresult   = mbrcli.create_page(parent: {database_id: mbrid},properties: mbrproperties)
                    _com.step(">>>MBR: Create page")
                    pp mbrresult                                if _debug == 'Y'
                    mbrpageid   = mbrresult['id']
                elsif _mode == 'L'
                    _com.step(">>>LOG:: MBR:Create page")
                    pp mbrproperties
                end
                #=>=>=>
                _com.step(">>>MBR: #{x_reference} added")
                #init some fields
                mbrfields['CDC']            = "NIV"
                mbrfields['ActivitéP']      = ""
                mbrfields['ActivitéS']      = ""
                mbrfields['Cotisant/Participant/Extérieur'] = "Extérieur"
                mbrfields['V-A']                = ""
                mbrfields['Civilité']           = ""
                mbrfields['Rue + Numéro/Boite'] = ""
                mbrfields['Code postal']        = 0
                mbrfields['Localité']           = ""
                mbrfields['Gsm']                = ""
                mbrfields['Téléphone']          = ""
                mbrfields['Mail']               = ""
                mbrfields['Cotisation']         = 0
            #    mbrfields['Certificat']         = "Non"
                mbrfields['Date de Naissance']  = ""
                mbrfields["Date Inscription"]   = ""
                mbrfields['Date de Paiement']   = ""
                mbrfields['Date de Sortie']     = ""
                mbrfields['Date de Décès']      = ""
                mbrfields['EneoSport']          = "Eneo"

                y_actsec0   = 0

            end #<IF3>

            #
            #Process Modifications
            #+++++++++++++++++++++
            mbrproperties = {
                'Référence'=> { 'title'=> [{'text'=> {'content'=> x_reference}}]}
            }
            #check MBR <> XL
            #Cotisation
            if flagprinc
                if x_cotisation.to_i > mbrfields['Cotisation'].to_i
                    item    = {'Cotisation'=> {'select'=> {'name' => x_cotisation.to_s}}}
                    mbrproperties.merge!(item)
                elsif mbrfields['Cotisation'].nil? == false
                    item    = {'Cotisation'=> {'select'=> {'name' => mbrfields['Cotisation']}}}
                    mbrproperties.merge!(item)
                end
            end

            #EneoSport
            if x_eneo == mbrfields['EneoSport']
                item    = {'EneoSport'=> {'select'=> {'name' => x_eneo}}}
            elsif x_eneo == "Eneo" and mbrfields['EneoSport']=="EneoSport"
                item    = {'EneoSport'=> {'select'=> {'name' => mbrfields['EneoSport']}}}
            elsif x_eneo == "EneoSport"
                item    = {'EneoSport'=> {'select'=> {'name' => x_eneo}}}
            else
                item    = {'EneoSport'=> {'select'=> {'name' => "Eneo"}}}
            end
            mbrproperties.merge!(item)

            #Adresse
            if x_adresse != "*"
                item    = {'Rue + Numéro/Boite'=> {'rich_text'=> [{'text' => {'content'=> x_adresse}}]}}
                mbrproperties.merge!(item)
            end

            #Code postal
            if x_canton != '*'
                item    = {'Code postal'=> {'number'=> x_canton.to_i}}
                mbrproperties.merge!(item)
            end

            #Localité
            if x_localite != "*"
                item    = {'Localité'=> {'rich_text'=> [{'text' => {'content'=> x_localite}}]}}
                mbrproperties.merge!(item)
            end

            #GSM
            if x_gsm != "*"
                item    = {'Gsm'=> {'phone_number'=> x_gsm.to_s}}
                mbrproperties.merge!(item) 
            end

            #Téléphone
            if x_telephone != "*"
                item    = {'Téléphone'=> {'phone_number'=> x_telephone.to_s}}
                mbrproperties.merge!(item) 
            end

            #Mail
            if x_mail != "*"
                item    = {'Mail'=> {'email'=> x_mail}}
                mbrproperties.merge!(item)
            end

            #Naissance
            if x_naissance != "*"
                item    = {'Date de Naissance'=> {'date'=> {'start'=> x_naissance}}}
                mbrproperties.merge!(item)
            end

            #Inscription
            if x_entree != "*"
                item    = {"Date Inscription"=> {'date'=> {'start'=> x_entree}}}
                mbrproperties.merge!(item)
            end

            #Paiement
        ###    if x_paiement != "*"
        ###        item    = {"Date de Paiement"=> {'date'=> {'start'=> x_paiement.to_s}}}
        ###        modproperties.merge!(item)
        ###    elsif mbrfields["Date de Paiement"].nil? == false
        ###        item    = {"Date de Paiement"=> {'date'=> {'start'=> mbrfields["Date de Paiement"]}}}
        ###        modproperties.merge!(item)
        ###    end

            #Sortie
            if x_sortie != "*"
                item    = {"Date de Sortie"=> {'date'=> {'start'=> x_sortie}}}
                mbrproperties.merge!(item)
            end

            #Décès
            if x_deces != "*"
                item    = {"Date de Décès"=> {'date'=> {'start'=> x_deces}}}
                mbrproperties.merge!(item)
            end

            #V-A
           if x_va != '*'
                item    = {'V-A'=> {'select'=> {'name' => x_va}}}
                mbrproperties.merge!(item)
            end

            #ActPrc
            if x_actprc != "*"
                item    = {'ActivitéP'=> {'select'=> {'name' => x_actprc}}}
                mbrproperties.merge!(item)
            end

            #ActSecs
            if x_actsec0 == 0 and y_actsec0 == 0
                item    = {'ActivitéS'=> {'multi_select'=> []}}
            elsif x_actsec0 == 0 and y_actsec0 > 0
                case y_actsec0
                when 1
                    item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> y_actsec1}]}}
                when 2
                    item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> y_actsec1},{'name'=> y_actsec2}]}}
                when 3
                    item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> y_actsec1},{'name'=> y_actsec2},{'name'=> y_actsec3}]}}
                when 4
                    item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> y_actsec1},{'name'=> y_actsec2},{'name'=> y_actsec3},{'name'=> y_actsec4}]}}
                when 5
                    item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> y_actsec1},{'name'=> y_actsec2},{'name'=> y_actsec3},{'name'=> y_actsec4},{'name'=> y_actsec5}]}}
                end
            elsif x_actsec0 > 0
                case x_actsec0
                when 1
                    item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> x_actsec1}]}}
                when 2
                    item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> x_actsec1},{'name'=> x_actsec2}]}}
                when 3
                    item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> x_actsec1},{'name'=> x_actsec2},{'name'=> x_actsec3}]}}
                when 4
                    item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> x_actsec1},{'name'=> x_actsec2},{'name'=> x_actsec3},{'name'=> x_actsec4}]}}
                when 5
                    item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> x_actsec1},{'name'=> x_actsec2},{'name'=> x_actsec3},{'name'=> x_actsec4},{'name'=> x_actsec5}]}}
                end
            end
            mbrproperties.merge!(item)

            #upd to Mbr
            #++++++++++
            _com.step(">>>MBR: #{x_reference} updating")            ###if _debug == 'F'
            count_mbradd    += 1
            item    = {'Statut'=> {'status'=> {'name'=> x_statut}}}
            mbrproperties.merge!(item)
            #
            item    = {'EnCours'=> {'checkbox' => true}}
            mbrproperties.merge!(item)
            #=>=>=>
            if _mode == 'E'
                pp mbrproperties                                #if _debug == 'Y'
                rc  = mbrcli.update_page(page_id: mbrpageid, properties: mbrproperties)
                pp  rc
                _com.step(">>>MBR: #{x_reference} added with Validation ON")
            elsif _mode == 'L'
                _com.step(">>>MBR: Update page")
                pp mbrproperties
            end
            #=>=>=>
            #

        elsif flagout   #<IF2>
            #<Remove> from 1 activity
            #+++++++++++++++++++++++++++
            _com.step("3B-Remove member on Activity")
            #
            #only for removal on 1 activity from ActPrc or ActSecs
            #
            puts "DBG>Statut #{x_statut} in progress..."        if _debug == 'Y'
            #get all relative records on mbr
            _com.step(">>>MBR: #{x_reference} get relative records")
            filter2  = {
                'and'=> [
                    {'property'=> 'Reference','formula'=> {'string'=> {'contains'=> x_reference}}}
                ]
            }
            sort2 = {
                'timestamp': 'created_time',
                'direction': 'descending'                    
            }
            o_mbrresult = mbrcli.database_query(database_id: mbrid, filter: filter2)
#            o_mbrresult = mbr_result
            o_mbrdata   = o_mbrresult['results']
            o_mbrpageid = ''
            if o_mbrdata.length > 0     #<IF3>
                _com.step(">>>MBR: #{x_reference} set relative records to remove activity")
                o_mbrdata.each do |page|  #<L4>
                    pp page                                     if _debug == 'Y'
                    flagexpand      = 2
                    updproperties   = {             #base obj
                        'Statut'=> {'status'=> {'name'=> x_statut}}
                    }
                    #extract properties
                    o_mbrpageid     = page['id']
                    o_mbrproperties = page['properties']
                    #
                    o_itemx     = o_mbrproperties['ActivitéP']
                    o_parms     = ['ActivitéP',o_itemx]
                    o_actprc    = EneoBwCom.extrProperty('None',o_parms)
                    #
                    o_itemx     = o_mbrproperties['ActivitéS']
                    o_parms     = ['ActivitéS',o_itemx]
                    o_actsecs   = EneoBwCom.extrProperty('None',o_parms)
                    puts    "DBG>Page: #{x_reference} ActPrc: #{o_actprc}, ActSecs:#{o_actsecs}"     #if _debug == 'Y'

                    if o_actprc.nil? or o_actprc == 'None'     #<IF5>
                        x_cpe   = 'Participant'
                        o_item  = {'CPE'=> { 'select'=> {'name'=> x_cpe}}}
                        flagexpand  -= 1
                    else    #<IF5>
                        if o_actprc == activity #<IF6>
                            o_item    = {'ActivitéP'=> {'select'=> {'name'=> "None"}}}  
                            flagexpand  -= 1
                        else    #<IF6>
                            o_item    = {'ActivitéP'=> {'select'=> {'name'=> o_actprc}}}
                        end #<IF6>
                    end #<IF5>
                    updproperties.merge!(o_item)    #add ActPrc
                    #
                    o_index         = 1
                    o_count         = o_actsecs.length
                    o_actsecs.each do |o_actsec|    #<L5>
                        if o_actsec != activity     #<IF6>
                            case o_index  #<SW7>
                            when 1  #<SW7>
                                o_actsec1 = o_actsec
                                o_item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> o_actsec1}]}}
                            ###    puts "mbr 1: #{o_item}"
                            when 2
                                o_actsec2 = o_actsec
                                o_item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> o_actsec1},{'name'=> o_actsec2}]}}
                            ###    puts "mbr 2: #{o_item}"
                            when 3
                                o_actsec3 = o_actsec
                                o_item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> o_actsec1},{'name'=> o_actsec2},{'name'=> o_actsec3}]}}
                            when 4
                                o_actsec4 = o_actsec
                                o_item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> o_actsec1},{'name'=> o_actsec2},{'name'=> o_actsec3},{'name'=> o_actsec4}]}}
                            when 5
                                o_actsec5 = o_actsec
                                o_item    = {'ActivitéS'=> {'multi_select'=> [{'name'=> o_actsec1},{'name'=> o_actsec2},{'name'=> o_actsec3},{'name'=> o_actsec4},{'name'=> o_actsec5}]}}
                            end #<SW7>
                            o_index   += 1
                        else    #<IF6>
                            o_count -= 1
                        end #<IF6>
                    end #<L5>
                    if o_count == 0   #<IF6>
                        o_item    = {'ActivitéS'=> {'multi_select'=> []}}
                        flagexpand  -= 1
                    end #<IF6>
                    updproperties.merge!(o_item)        #add ActSecs
                    pp  updproperties
                    #
                    puts    "DBG>FLAGEXPAND:#{flagexpand}"  if _debug == 'Y'
                    if flagexpand > 0  #<IF5>
                        o_item = {'EnCours'=> {'checkbox' => true}}
                    else    #<IF5>
                        o_item = {'EnCours'=> {'checkbox' => false}}
                    end #<IF5>
                    updproperties.merge!(o_item)    #change EnCours
                    pp  updproperties
                    #
                    if _mode == 'E'
                        mbrcli.update_page(page_id: o_mbrpageid, properties: updproperties)
                        break                               #skip other records
                    elsif _mode == 'L'
                        _com.step(">>>MBR: Update_1 page")
                    end
                end #<L4>
            end #<IF3>
            #
        elsif flagstop  #<IF2>
            #Arrêt
            #+++++
            _com.step("3C-Remove member on all Activities")
            #
            puts "DBG>Statut #{x_statut} in progress..."        if _debug == 'Y'
            #get all relative records on mbr
            _com.step(">>>MBR: #{x_reference} get relative records")
            filter2  = {
                'and'=> [
                    {'property'=> 'Reference','formula'=> {'string'=> {'contains'=> x_reference}}}
                ]
            }
            sort2 = {
                'timestamp': 'created_time',
                'direction': 'ascending'                    
            }
#            mbrresult   = mbrcli.database_query(database_id: mbrid, filter: filter2)
#            mbrdata     = mbrresult['results']
#            mbrpageid   = ''
            if mbrdata.length > 0     #<IF6>
                _com.step(">>>mbr: #{x_reference} set relative records to set EnCours FALSE")
                mbrdata.each do |page|  #<L7>
                    #extract values
                    mbrpageid   = page['id']
                    puts "DBG>Page: #{x_reference} PageID:#{mbrpageid}"     if _debug == 'Y'
                    updproperties = {
                        'EnCours'=> {'checkbox'=> false},
                        'Statut'=> {'status'=> {'name'=> x_statut}},
                        'Date de Sortie'=> {'date'=> [{'start'=> x_sortie}]}
                    }
                    if _mode == 'E'
                        mbrcli.update_page(page_id: mbrpageid, properties: updproperties)
                    elsif _mode == 'L'
                        _com.step(">>>MBR>Update_2 page")
                        pp updproperties                        if _debug == 'Y'
                    end
                end #<L7>
            end #<IF6>         
            #
        elsif flagdead  #<IF2>
            #Décès
            #+++++
            _com.step("3D-Remove member on CDC")
            #
            puts "DBG>Statut #{x_statut} in progress..."        if _debug == 'Y'
            #get all relative records on mbr
            _com.step(">>>MBR: #{x_reference} get relative records")
            filter2  = {
                'and'=> [
                    {'property'=> 'Reference','formula'=> {'string'=> {'contains'=> x_reference}}}
                ]
            }
            sort2 = {
                'timestamp': 'created_time',
                'direction': 'ascending'                    
            }
#            mbrresult   = mbrcli.database_query(database_id: mbrid, filter: filter2)
#            mbrdata     = mbrresult['results']
#            mbrpageid   = ''
            if mbrdata.length > 0     #<IF6>
                _com.step(">>>mbr: #{x_reference} set relative records to set EnCours FALSE")
                mbrdata.each do |page|  #<L7>
                    #extract values
                    mbrpageid   = page['id']
                    puts "DBG>Page: #{x_reference} PageID:#{mbrpageid}"      if _debug == 'Y'
                    updproperties = {
                        'EnCours'=> {'checkbox'=> false},
                        'Statut'=> {'status'=> {'name'=> x_statut}},
                        'Date de Décès'=> {'date'=> [{'start'=> x_deces}]}
                    }
                    if _mode == 'E'
                        mbrcli.update_page(page_id: mbrpageid, properties: updproperties)
                    elsif _mode == 'L'
                        _com.step(">>>mbr>Update_3 page")
                        pp updproperties                    if _debug == 'Y'
                    end
                end #<L7>
            end #<IF6>         
            #
        end #<IF2>
        
        if repnext  != 'A'
            print ">>>Next ? "
            repnext  = $stdin.gets.chomp.upcase
            if repnext == 'Q'
                exit 9
            end
        end
        #
    end #<L1>
    #
    _com.step("5-Log process")
    text    = "For ACT: #{activity} with MODE: #{_mode} Counters:: Rec:#{count_rec} - Next:#{count_next} MbrOK:#{count_mbrok} - MbrAdd:#{count_mbradd} - Mod:#{count_mbradd}"
    timeto      = Time.now.to_i
    timediff    = timeto - timefrom
    _com.step(text)
    #
    logproperties   = {
        'Function'=> {'title'=> [{'text'=> {'content'=> "EneoBwCom_AddMod"}}]},
        'Text'=> {'rich_text'=> [{'text' => {'content'=> text}}]},
        'Time'=> {'number'=> timediff}
    }
    #
    ###logcli.create_page(parent: {database_id: logid},properties: logproperties)
#
    _com.stop(program,"ByeBye")
#   <EOF>
