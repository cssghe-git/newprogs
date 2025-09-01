#
=begin
    Progr:      EneoBwCom_ExtMbr6
    Function:   extract records from MembersV24 table
    Build:  2.4.1   <250113-1804>  

    Input:      Members DB
    Output:     File : CDC-ListeMembres_[Activity]-Envoi.xlsx

    Parameters:
        P1: debug => Y, N 
        P2: [CDC,Activity,EnCours,Cotis,Cnci,va]
        P3: filename to write (activity only) or X
        
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
    _debug  = ARGV[0]       #debug  Y, N
    _filter = ARGV[1]       #filters
    _file   = ARGV[2]       #file : only activity part

    _debug  = _debug.upcase
    _debug  = true  if _debug == 'Y'
    _debug  = false if _debug == 'N'
#

#
#***** Exec environment *****
# Start of block
    program = 'EneoBwCom_ExtMbr6'
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
    Dir.chdir(member_dir)
require "#{member_dir}/mdEneoBwCom.rb"
#
#Internal functions
#++++++++++++++++++
#
    def setDates(p_date='')
    #INP::  p_date => date to reverse
    #OUT::  new date format
        return  if p_date.nil?
        aaaa    = p_date[0,4]
        mmmm    = p_date[5,2]
        jjjj    = p_date[8,2]
        return  "#{jjjj}/#{mmmm}/#{aaaa}"
    end
#
#Variables
#+++++++++
#
    integr  = 'secret_2XXOYzX5JThHqZviHGZpPna5ihVU2o3knCvrCu76RjS'  #EneoBW
    mbrid   = '19ae0e553d938007b793fc4e7e74e666'    #members24 db   https://www.notion.so/eneobw/19ae0e553d938007b793fc4e7e74e666?v=19ae0e553d93819e95fb000ce1280044&pvs=4

    count_blocks    = 0
    count_pages     = 0
    count_xl        = 0
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
    filewrite   = "#{send_dir}/#{actcdc}-ListeMembres_#{_file}-Envoi#{envdate}.csv"
    filetitle   = "#{actcdc}-ListeMembres_#{_file}-Envoi.csv"

    #Starting
    _com.start(program,"Debug:#{_debug} Filters:#{prms} File:#{filewrite}")

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
    body    = EneoBwCom.body(prms)
    _com.step("3B::Filter body::#{body}")
    ### pp body
    ###exit 999
    #
    #Make sort
    #=========
    sort    = [
    #    {'property'=> 'CDC', 'direction'=> 'ascending'},
        {'property'=> 'Référence', 'direction'=> 'ascending'}
    ]
    #Make csv values
    #===============
    csvtitles   = [ 'Statut',
                    'Référence',
                    'CDC',
                    'Civilité',
                    'Nom',
                    'Prénom',
                    'Adresse',
                    'Canton',
                    'Ville',
                    'Gsm',
                    'Téléphone',
                    'Mails',
                    'Date Naissance',
                    'Cotisation',
                    'EneoSport',
                    'ActPrc',
                    'ActSecs',
                    'Date Entrée',
                    'Date Paiement',
                    'Date Sortie',
                    'Date Deces',
                    'V-A'
                ]

    #Init fields
    valstatut       = ''
    valcdc          = ''
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
    valeneo         = ''
    valactp         = ''
    valacts         = ''
    valentree       = ''
    valpaiement     = ''
    valsortie       = ''
    valdeces        = ''
    valva           = ''

    csvlines    = [valstatut,valreference,valcdc,valcivilite,valnom,valprenom,
                    valadresse,valcanton,vallocalite,valgsm,valtelephone,
                    valmail,valnaissance,valcotis,valeneo,valactp,valacts,
                    valentree,valpaiement,valsortie,valdeces,valva
                ]

    #
    #Loop all records
    #================
    _com.step("5A::Process Mbr records")

    CSV.open(filewrite,'wb') do |line|  #<L1>
        #add titles
        line << csvtitles

        #add lines
        mbrcli.database_query(database_id: mbrid, filter: body, sorts: sort) do |mbrresult| #<L2>
            count_blocks += 1
            _com.step("5B::Block N° #{count_blocks}")
            mbrdata = mbrresult['results']

            mbrdata.each do |page|      #<L3>                               #extract 1 page
                count_pages     += 1
                _com.step("6::Page N° #{count_pages}")  if _debug   == 'Y'
                pp  page                                if _debug == 'Y'
                mbrproperties   = page['properties']                        #extract properties

                #init local vars
                valreference    = 'None'
                valcdc = valnom = valprenom = valcivilite = valadresse = valcanton = ''
                vallocalite = valgsm = valtelephone = valmail = ''
                valnaissance = valcotis = valeneo = valactp = valacts = ''
                valentree = valpaiement = valsortie = valdeces = valva = ''

                #load properties to local vars
                mbrproperties.each do |property|    #<L4>                   #loop all properties
                    pp property                         if _debug   == 'Y'
                    name    = property[0]
                    value   = EneoBwCom.extrProperty('None',property)       #extract property value
                    next    if value == 'None'
                    puts    "DBG>PROP.NAME:#{name} : #{value}"     if _debug == 'Y'

                    #dispatch
                    case name   #<SW3>
                    when 'CDC' #<SW3>
                        valcdc  = value.upcase

                    when 'Référence' #<SW3>
                        break   if value.nil? or value == 'None'    #Title must not be empty
                        valreference    = value
                        puts "Ref: #{value}"            if _debug   == 'Y'
                        pos = value.index('-')
                        if pos.nil?
                            nom = value[0,99]
                            pre = 'xyz'
                        else
                            nom = value[0,pos]
                            pre = value[pos+1,99]
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
                        valnaissance    = setDates(value[0])

                    when 'Cotisation' #<SW3>
                        valcotis    = value.to_i

                    when 'EneoSport' #<SW3>
                        valeneo = value

                    when 'ActivitéP' #<SW3>
                        valactp = value

                    when 'AllActs' #<SW3>
                        pos = value.index('#')
                        part2   = value[pos+1,99]
                        valacts = part2

                    when "Date d'Inscription" #<SW3>
                        valentree   = setDates(value[0])

                    when 'Date de Paiement' #<SW3>
                        valpaiement = value[0]
                        valpaiement = setDates(valpaiement[0,10])

                    when 'Date de Sortie' #<SW3>
                        valsortie   = setDates(value[0])

                    when 'Date de Décès' #<SW3>
                        valdeces   = setDates(value[0])

                    when 'V-A' #<SW3>
                        valva   = value
                    end #<SW3>
                end #<L4>

                #check filters
            #    puts "For CDC: #{selcdc} -> #{valcdc} # ACT: #{activity} -> #{valactp} - #{valacts}"
                #check cdc
                if selcdc != 'ALL'
                    _com.step("7A::Exit cdc: #{selcdc} -> #{valcdc}")     if _debug   == 'Y'
                    next    if valcdc != selcdc
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
                _com.step("7F::REF:: #{valreference} : #{valnom}-#{valprenom}")     #if _debug   == 'Y'
                count_xl    += 1

                #compose

                #add to csv
    csvlines    = [valstatut,valreference,valcdc,valcivilite,valnom,valprenom,
                    valadresse,valcanton,vallocalite,valgsm,valtelephone,
                    valmail,valnaissance,valcotis,valeneo,valactp,valacts,
                    valentree,valpaiement,valsortie,valdeces,valva
                ]
                line << csvlines

                #Init vars
                valadresse = valcanton = vallocalite = valgsm = valtelephone = balmail = ''
                valnaissance = valcotis = valeneo = valva = ''
                valactp = valacts = ''
                valentree = valsortie = valdeces = ''
            end #<L3>
        end #<L2>
    end #<L1>
    #
    #End of program
    #==============
    text    = "For ACT: #{activity} with MODE: #{_filter} Counters:: Blocks:#{count_blocks} Pages:#{count_pages} - XL:#{count_xl}"
    _com.stop(program,"#{text}")
    #
#<EOS>
