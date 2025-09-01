#
=begin
    #Function:  add member to update (csv)
    #Call:      ruby EneoBwCom_AddUpd62.rb N
    #Parameters::
        #P1:    true/Y=>debug false/N=>None
        #P2:    ALL or by Demande
        #P3:    ?
    #Actions:
        #   create      250805-0930
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
    exec_mode   = 'B'                                   #change B or P
    require_dir = Dir.pwd
    common_dir  = "/users/gilbert/public/progs/prod/common/"    if exec_mode == 'P'
    common_dir  = "/users/gilbert/public/progs/dvlps/common/"    if exec_mode == 'B'
require "#{common_dir}/ClDirectories.rb"
    _dir    = Directories.new(false)
    arrdirs = _dir.otherDirs(exec_mode)                 #=>{exec,private,membres,common,send,work}
# End of block
#***** Directories management *****
#

#
# Input parameters
#*****************
# Start of block
    prm_hash    = []
    prm_count   = ARGV.length
begin
    ARGV.each_with_index do |param,index|
        prm_hash[index] = param
    end
rescue
    _debug  = false
    _all    = false
end
# End of block

# Check parameters
#*****************
# Start of block
    if prm_count > 0
        _debug  = prm_hash[0]
        _debug  = true      if _debug == 'Y'
        _debug  = false     if _debug == 'N'
    else
        _debug  = false
    end

    _all    = prm_hash[1]   if prm_count > 1
    puts    "Select all records : #{_all}"
    print   "Do you confirm <Selection> ? "
    selall  = $stdin.gets.chomp.upcase
    exit 7 if selall == 'N'
    _all    = false if _all == 'SEL'
    _all    = true  if _all == 'ALL' or selall == 'ALL'
    #etc...
# End of block
#

#***** Exec environment *****
# Start of block
    program     = 'EneoBwCom_AddUpd62'
    dbglevel    = 'DEBUG'

require "#{arrdirs['common']}/ClCommon_2.rb"
    _com    = Common_2.new(program,_debug,dbglevel)
require "#{arrdirs['common']}/ClNotion_2F.rb"

    private_dir     = arrdirs['private']                #private directory
    member_dir      = arrdirs['membres']                #members directory
    common_dir      = arrdirs['common']                 #common directory
    work_dir        = arrdirs['work']
    send_dir        = arrdirs['send']
    process_dir     = arrdirs['process']

require "#{member_dir}/mdEneoBwCom.rb"
# End of block
#***** Exec environment *****
#
# Variables
#**********
upd_key     = 'updates-csv_v24'
mbr_key     = 'membres_v24'
demande_val  = ['Nouveau-Principal','Nouveau-Secondaire','Ajout-Secondaire','Modification','Suppression','Arrêt','Décès']
count_all   = 0
count_sel   = 0

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
        ['EneoSport',14,'T'],
        ['ActPrc',15,'T'],
        ['ActSecs',16,'T'],
        ['Date Entrée',17,'D'],
        ['Date Paiement',18,'D'],
        ['Date Sortie',19,'D'],
        ['Date Décès',20,'D'],
        ['V-A',21,'T']
    ]
    @csv_array      = {}                                #all csv lines
    @csv_statements = []                                #all lines to process
#
# Internal functions
#*******************
#
    #read 1 line & transform to hash
    def readCsvLine(p_row=[])
        #++++++++++++++
        #   INP::   row array 1 string to split(;)
        #   OUT::   row hash into @csv_array
        #check
        return  false   if p_row.length == 0
        p_row   = p_row[0]                              #extract string
        row     = p_row.split(";")                      #split into fields
        #load array
        @csv_array  = {}                                #clear array
        @csv_fields.each do |field| #<L1>               #load array
            name    = field[0]
            index   = field[1]
            type    = field[2]
            value   = row[index]                        #if conversion
        ###    puts    "DBG>>Fields::NAME:#{name}-INDEX:#{index}-TYPE:#{type}-VAL:#{value}"
            case    type    #<SW2>
            when    'T'     #<SW2>
                value   = ""   if value.nil? or value.size == 0
                row[index]  = value
            when    'D'     #<SW2>
                value   = "01/01/1900"   if value.nil? or value.size == 0
                value   = "#{value[6,4]}-#{value[3,2]}-#{value[0,2]}"   if value!=''
                row[index]  = value
            when    'I'
                value   = "0"   if value.nil? or value.size == 0
                row[index]  = value
                point   = value.index('.')
            else
                row[index]  = value
            end #<SW2>
            @csv_array[name]    = row[index]            #add entry {name=>value}
        end #<L1>
        #
        return   true
    end #<def>

# Main code
#**********
    # Initialize
    #+++++++++++
    # Notion class
    _upd    = ClNotion_2F.new('Mbr24')                  #UpdatesV24 DBs familly
    _mbr    = ClNotion_2F.new('Mbr24')                  #MembersV24

    _com.start(program," ")
    _com.step("1-Initialize>")
    rc  = _upd.loadParams(_debug,_upd)                  #load params to Notion class
    _com.step("1A-loadParams => #{rc}")
    rc  = _mbr.loadParams(_debug,_upd)                  #load params to Notion class
    rc  = _upd.initNotion(upd_key)                      #init new cycle for 1 DB
    _com.step("1B-initNotion for #{upd_key}=> #{rc}")
    rc  = _mbr.initNotion(mbr_key)                      #init new cycle for 1 DB
    #
    t           = Time.now                              #get time
    currtime    = t.strftime("%Y-%m-%dT%H:%M").strip    #extract YYYY-MM-DD HH:MM
    currdate    = t.strftime("%Y-%m-%d").strip          #extract YYYY-MM-DD

    #
    response    = EneoBwCom.reqAct('NIV')               #=>[rep,acts[rep]]
    activity    = response[1]                           #extract act
#    print   "1C-Your activity ? "                      #get your activity
#    activity    = $stdin.gets.chomp.to_s
    author      = "Script-Upd62"                        #define request author
    #
    # Processing
    #+++++++++++
    _com.step("2-Processing")
    #
    # Select file to read
    #====================
    _com.step("2A-List of .csv files")
    Dir.chdir(process_dir)
    allfiles    = Dir.glob("*.csv")
    allfiles.each_with_index do |file,index|    #<L1>
        puts    "#{index+1}.#{file}"
    end #<L1>
    print   "2B-Please select file to process by N° => "
    fileindex   = $stdin.gets.chomp.to_i
    fileselect  = allfiles[fileindex-1]
    _com.step("2C-File selected: #{fileselect}")
    
    # Loop all rows & columns
    # =======================
    _com.step("3A-Extract all rows")
    csv_flag    = false                                 #to skip 1st line (titles)
    CSV.foreach(fileselect) do |row|     #<L1> => @csv_array
        if csv_flag #<IF2>
            if  readCsvLine(row)    #<IF3>
                _com.debug("DBG>>CSV:#{@csv_array}")
                if @csv_array['Statut'] == 'Statut' #iF4>
                else    #<IF4>
                    @csv_statements.push(@csv_array)    #add to statements
                end #<IF4>
            end #<IF3>
        else    #<IF2>
            csv_flag    = true
            next
        end #<IF2>
    end #<L1>

    # Display request & add db
    #=========================
    _com.step("3B-Display requests")
    @csv_statements.each do |statement| #<L1>loop all statements
        count_all   +=1
        _com.debug("STATEMENT:#{statement}")
        # check request
        member  = statement['Référence']                #extract fields
        demande  = statement['Statut'].strip
        demande  = 'Checks'  if demande.size == 0 and _all

        if demande_val.include?(demande) or _all  #<IF2>  #if request correct or ALL
            count_sel   +=1

            # check member rec
            mbr_filter  = {
                'and'=> [
                    {'property'=> 'Reference','formula'=> {'string'=> {'contains'=> member}}}
                ]
            }
        ###    pp  mbr_filter
            response    = _mbr.getBlock(mbr_filter)
        ###    pp  response
            code        = response['code']
            data        = response['data'][0]
            _com.step("Member: #{member} with rc: #{code}")
            if code == '200'
                pageid  = data['id']
            else
                pageid  = ''
            end

            # set default values
            cpe = "Participant"
            cpe = "Cotisant"    if statement['CDC'] == 'NIV'

            #set default body
            bodyadd = {
                'Référence'=> {'title'=> [{'text'=>{'content'=> member}}]},
                'Statut'=> {'select'=> {'name'=> demande}},
                'CDC'=> {'select'=> {'name' => statement['CDC']}},
                'Civilité'=> {'select'=> {'name' => statement['Civilité']}},
                'Nom'=> {'rich_text'=> [{'text' => {'content'=> statement['Nom']}}]},
                'Prénom'=> {'rich_text'=> [{'text' => {'content'=> statement['Prénom']}}]},
                'Adresse'=> {'rich_text'=> [{'text' => {'content'=> statement['Adresse']}}]},
                'Canton'=> {'number'=> statement['Canton'].to_i},
                'Ville'=> {'rich_text'=> [{'text' => {'content'=> statement['Ville']}}]},
                'Date Naissance'=> {'date'=> {'start'=> statement['Date Naissance']}},
                'Date Paiement'=> {'date'=> {'start'=> statement['Date Paiement']}},
                'Date Sortie'=> {'date'=> {'start'=> statement['Date Sortie']}},
                'Cotisation'=> {'select'=> {'name' => statement['Cotisation']}},
                'EneoSport'=> {'select'=> {'name' => statement['EneoSport']}},
                'V-A'=> {'select'=> {'name'=> statement['V-A']}},
                'CPE'=> {'select'=> {'name'=> cpe}}
            }

            # set specific values
            if pageid.size > 0
                item    = {'relMembres_NIV'=> {'relation'=> [{'id'=> pageid}]}}
                bodyadd.merge!(item)
            end

            activitep   = statement['ActPrc']
            if activitep != ""
                item    = {'ActPrc'=> {'select'=> {'name' => activitep}}}
                bodyadd.merge!(item)
            end

            actsecs = statement['ActSecs'].split(",")
            length  = actsecs.length()
            if length == 0
                item    = {'ActSecs'=> {'multi_select'=> []}}
            else
                case length
                when 1
                    item    = {'ActSecs'=> {'multi_select'=> [{'name'=> actsecs[0]}]}}
                when 2
                    item    = {'ActSecs'=> {'multi_select'=> [{'name'=> actsecs[0]},{'name'=> actsecs[1]}]}}
                when 3
                    item    = {'ActSecs'=> {'multi_select'=> [{'name'=> actsecs[0]},{'name'=> actsecs[1]},{'name'=> actsecs[2]}]}}
                when 4
                    item    = {'ActSecs'=> {'multi_select'=> [{'name'=> actsecs[0]},{'name'=> actsecs[1]},{'name'=> actsecs[2]},{'name'=> actsecs[3]}]}}
                when 5
                    item    = {'ActSecs'=> {'multi_select'=> [{'name'=> actsecs[0]},{'name'=> actsecs[1]},{'name'=> actsecs[2]},{'name'=> actsecs[3]},{'name'=> actsecs[4]}]}}
                end
            end
            bodyadd.merge!(item)

            gsm = statement['GSM']
            if gsm != ''
                gsm = "+#{gsm}"     if gsm.include?('+')==false
                item    = {'Gsm'=> {'phone_number'=> gsm}}
                bodyadd.merge!(item)
            end

            telephone   = statement['Téléphone']
            if telephone != ''
                telephone   = "+#{telephone}"   if telephone.include?('+')==false
                item    = {'Téléphone'=> {'phone_number'=> telephone}}
                bodyadd.merge!(item)
            end
            
            mail    = statement['Mails']
            if mail != ''
                item    = {'Mails'=> {'email'=> mail}}
                bodyadd.merge!(item)
            end

            va  = statement['V-A']
            if va != ''
                item    = {'V-A'=> {'select'=> {'name'=> va}}}
                bodyadd.merge!(item)
            end

            datedeces   = statement['Date Deces']
            if datedeces.nil? == false
                item    = {'date'=> {'start'=> atedeces}}
            end

            # add to db
            ### pp bodyadd
            result  = _upd.addPage('',bodyadd)          #add record
            code    = result['code']                    #check code
            _com.step("AddPage with RC>>>#{member} => #{code}")
            _com.step("AddPage with RC>>>#{result}")      if code != '200'

            exit 9

        else    #<IF2>
            _com.step("3C-"+member+" REQ:"+demande)
        end #<IF2>
    end #<L1>

    #Display counters
    #================
    _com.step("6-Counters::RECS:#{count_all} - SEL:#{count_sel}")
    _com.stop(program,"Bye bye")
#<EOS>