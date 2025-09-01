#
=begin
    #Function:  update MBR from csv file
    #Call:      ruby ?.rb N
    #Parameters::
        #P1:    true/Y=>debug false/N=>None
        #P2:    ?
        #P3:    ?
    #Actions:
        #   select csv file to process
        #   checks csv <> MB
        #   update or not
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
    common_dir  = "/users/gilbert/public/progs/dvlps/common/"   if exec_mode == 'B'
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

    _p1     = prm_hash[1]   if prm_count > 1
    #etc...
# End of block
#
#***** Exec environment *****
# Start of block
    program     = '?'

    #classes
require "#{common_dir}/ClCommon_2.rb"
    _com    = Common_2.new(program,_debug,0)
require "#{common_dir}/ClNotion_2F.rb"

    #directories
    private_dir     = arrdirs['private']                #private directory
    member_dir      = arrdirs['membres']                #members directory
    work_dir        = arrdirs['work']
    send_dir        = arrdirs['send']
    download_dir    = arrdirs['idown']                  #download iCloud
    process_dir     = arrdirs['process']

require "#{member_dir}/mdEneoBwCom.rb"
# End of block
#***** Exec environment *****
#
#
# Variables
#**********
#   Notion
    not_key     = 'membres_v24'
    not_fields  = ['ALL']


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
    @csv_array      = {}
    @csv_statements = []

    status_val  = ['Nouveau','Modification','Suppression','Arrêt','Décès']
    count_all   = 0
    count_sel   = 0
#
# Internal functions
#*******************
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

# Main code
#**********
    _com.start(program,"PRM:#{prm_count} => DEBUG:#{_debug} ")
    _com.logData(" ")

    # Initialize
    #+++++++++++
    _com.step("1-Initialize>")
    t           = Time.now                              #get time
    currtime    = t.strftime("%Y-%m-%dT%H:%M").strip    #extract YYYY-MM-DD HH:MM
    currdate    = t.strftime("%Y-%m-%d").strip          #extract YYYY-MM-DD

    # Notion class
    _not    = ClNotion_2F.new('Mbr24')                #Private DBs familly
    rc  = _not.loadParams(_debug,_not)                  #load params to Notion class
    _com.step("1A-loadParams => #{rc}")
    rc  = _not.initNotion(not_key)                      #init new cycle for 1 DB
    _com.step("1B-initNotion for #{not_key}=> #{rc}")

    # Activity
    response    = EneoBwCom.reqAct('NIV')               #=>[rep,acts[rep]]
    activity    = response[1]                           #extract act

    #
    # Processing
    #+++++++++++
    _com.step("2-Processing")

    # Select file to read
    #====================
    _com.step("2A-List of .csv files")
    Dir.chdir(process_dir)                              #goto dir
    allfiles    = Dir.glob("*.csv")                     #get all files
    allfiles.each_with_index do |file,index|    #<L1>
        puts    "#{index+1}.#{file}"
    end #<L1>
    print   "2B-Please select file to process by N° => "
    fileindex   = $stdin.gets.chomp.to_i                #select file
    fileselect  = allfiles[fileindex-1]
    _com.step("2C-File selected: #{fileselect}")

    # Loop all rows & columns
    # =======================
    _com.step("3A-Extract all rows")
    csv_flag    = false                                 #to skip 1st line (titles)
    CSV.foreach(fileselect) do |row|     #<L1> => @csv_array
        if csv_flag #<IF2>
            if  readCsvLine(row)    #<IF3>
                puts    "DBG>>CSV:#{@csv_array}"    #if _debug == 'Y'
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

    # Display request, checks & update db
    #====================================
    _com.step("3B-Display requests")
    @csv_statements.each do |statement| #<L1>loop all statements
        count_all   +=1
        # display
        _com.step("STATEMENT:#{statement}")

        # check request
        #--------------
        x_reference = statement['Référence']            #extract fields
        x_status    = statement['Statut'].strip

        if status_val.include?(x_status)  #<IF2>        #if status correct
            count_sel   +=1
            flag_newprc = false
            flag_newsec = false
            flag_update = false
            flag_stop   = false
            flag_dead   = false

            # check member
            #-------------
            mbr_filter  = {
                'and'=> [
                    {'property'=> 'RefID','formula'=> {'string'=> {'contains'=> x_reference}}}
                ]
            }
            response    = _not.runPages(mbr_filter,'',not_fields) do |state,data|   #<L3>
                if state == true    #<IF4> member exists
                    flag_member = true
                    pageid      = data['id']
                    properties  = _not.loadProperties(data,not_fields)
                    y_reference = properties['Référence']

                    # extract fields
                    #---------------
                    # common
                    y_cdc       = properties['CDC']
                    y_actprc    = properties['ActivitéP']
                    y_actsec    = properties['AcitivtéS']
                    # following status
                    case x_status   #<SW4>
                    when    'Nouveau'
                    when    'Modification'
                    when    'Arrêt'
                    when    'Décès'
                    else    #<SW4>
                    end #<SW4>

                else                #<IF4> member not exists
                    flag_member = false
                    y_cdc       = ''
                    y_actprc    = ''
                    y_actsec    = ''
                end #<IF4>

                # extract csv values
            #-------------------
            # common
            x_cdc       = statement['CDC']
            x_actprc    = statement['ActivitéP']
            x_actsec    = statement['ActivitéS']
            # following status
            case x_status   #<SW3>
            when    'Nouveau'
                flag_newprc = flag_member == false and x_cdc.size == 3 and x_actprc.size > 3 and y_actprc.size == 0
                flag_newsec = flag_newprc == false and x_cdc.size == 3 and x_actsec.size > 3 and x_actsec != y_actsec
                if flag_newprc  #<IF4>
                    x_adresse   = statement['Rue']
                    x_canton    = statement['Canton']
                    x_ville     = statement['Ville']
                    x_naissance = statement['Date naissance']
                    flag_newprc = x_adresse.size > 0 and x_canton.size == 4 and x_ville.size > 0 and x_naissance.size > 0
                end #<IF4>

            when    'Modification'
            else    #<SW3>
            end #<SW3>

            # processing
            #-----------
            # flag newprc
            if flag_newprc  #<IF3>
                # Display
                puts    "<br>*"
                puts    "<br>Member : #{reference}"
                puts    "<br>CDC        => #{x_cdc}     #{y_cdc}"
                puts    "<br>ActPrc     => #{x_actprc}  #{y_actprc}"
                puts    "<br>ActSec     => #{x_actsec}  #{y_actsec}"
                puts    "<br>Flags : #{flag_newprc} - #{flag_newsec} - #{flag_update} - #{flag_stop} - #{flag_dead}"
                print   "Your choice ? "
                choice  = $stdin.gets.chomp
                exit    if choice.upcase == "Q"
            end #<IF3>

            # flag newsec
            if flag_newsec  #<IF3>
            end #<IF3>
        end #<IF2>
    end #<L1>




    #Display counters
    #================
    _com.step("9-Counters::?:#{count}")
    _com.stop(program,"Bye bye")
#<EOS>