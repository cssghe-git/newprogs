#
=begin
    Progr:      EneoBwCom_UpdSeagma6
    Function:   update Segma nr on main DB
    Build:      2-6-1   <250801-0636>
    Call:       ruby EneoBwCom_UpdSeagma4.rb   N L/E
    Input:      csv file
    Output:     Members table
    Parameters:
        P1: debug => N or Y
        P2: mode => E for exec OR L for log
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
#
#***** Directories management *****
# Start of block
    exec_mode   = 'P'                                   #change B or P
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

    _debug  = _debug.upcase
    _debug  = true  if _debug == 'Y'
    _debug  = false if _debug == 'N'
    _mode   = _mode.upcase

#
#***** Exec environment *****
# Start of block
    program = 'EneoBwCom_UpdSeagma6'
    dbglevel    = 'DEBUG'
    arrdirs = _dir.otherDirs(exec_mode)                 #=>{exec,private,membres,common,send,work}
require "#{arrdirs['common']}/ClCommon_2.rb"
    _com    = Common_2.new(program,_debug,dbglevel)
    private_dir = arrdirs['private']
    member_dir   = arrdirs['membres']                   #members directory
    common_dir   = arrdirs['common']                    #common directory
    work_dir    = arrdirs['work']
    send_dir    = arrdirs['send']
require "#{arrdirs['common']}/ClNotion_2.rb"
    ### pp arrdirs  
# End of block
#***** Exec environment *****
#
    Dir.chdir(member_dir)
require "#{member_dir}/mdEneoBwCom.rb"
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
            ###    puts    "DBG>>Fields::NAME:#{name}-INDEX:#{index}-TYPE:#{type}-VAL:#{value}"
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
    hasmore     = ''

    count_rec       = 0
    count_next      = 0
    count_mbrok     = 0
    count_mbrerr    = 0
    count_mbradd    = 0
    count_stop      = 5

    mbr_key         = 'membres_v24'
    mbrproperties   = {}
    mbrfields       = {}
    mbrpageid       = ''
    mbrresult       = {}
    mbrcode         = ''

    avance          = ''
    avance_old      = ''
#   csv infos
    @csv_fields     = [
        ['Seagma',0,'T'],
        ['Nom',1,'T'],
        ['Prénom',2,'T']
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
    _file       = "All"
    activity    = "All"
    #
    #make filename
    fileread    = "/users/Gilbert/Public/MemberLists/ToProcess/#{currentcdcx}ListeMembres_#{_file}-Retour.csv"
    #
    #Starting
    _com.start(program," with Debug:#{_debug} Mode:#{_mode} Activity:#{activity} File:#{fileread}")
    _com.step("1-Initialize")

    #Check file
    rc  = File.file?(fileread)
    if rc == false
        _com.step("1A-File doesn't exist")
        exit 1
    end

    #Client instances
    mbrcli  = ClNotion_2.new('Mbr24')
    #
    rc  = mbrcli.loadParams(_debug,mbrcli)
    rc  = mbrcli.initNotion(mbr_key)                    #init cycle
    hasmore   = true
#
#   Loop all rows & columns
#   =======================
    _com.step("2-Extract all rows")
    csv_flag    = false                                         #to skip 1st line (titles)
    CSV.foreach(fileread) do |row|     #<L1> => @csv_array
        if csv_flag #<IF2>
            if  readCsvLine(row)    #<IF3>
                _com.debug("2A-DBG>>CSV:#{@csv_array}")
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

    _com.step("3-Process all rows")
    @csv_statements.each do |statement| #<L1>loop all statements
        count_rec   += 1

        # Get fields (cols)
        #++++++++++++++++++
        #checks
        x_nom       = statement['Nom']
        x_prenom    = statement['Prénom']
        x_reference = "#{x_nom}-#{x_prenom}"
        if x_nom.nil? or x_prenom.nil?  #<IF2>
            break   #cancel iteration <L1>
        end #<IF2>
        #extract
        x_prefix    = x_nom[0,1]
        x_seagma    = statement['Seagma'].to_i

        #Print for checks
        #++++++++++++++++
    #    puts    "DBG>Checks::   INDEX:#{count_rec}"
    #    puts    "               Ref:#{x_reference}"
    #    puts    "               SEAGMA:#{x_seagma}"

        # Make filter/sort to load Members
        #+++++++++++++++++++++++++++++++++
        mbrfilter  = {
            'or'=> [
                {'property'=>'Reference','formula'=>{'string'=>{'starts_with'=> x_reference}}}
            ]
        }
        mbrsort     = [
            {'property'=> 'Référence', 'direction'=> 'descending'}
        ]
        _com.debug("3B-REQ::Nom:#{x_reference},Seagma:#{x_seagma}")

        #
        # Processing
        #+++++++++++

        #Check Member
        #++++++++++++
        _com.debug("3A-Load members")                        if _debug == 'Y'
        ###pp  mbrfilter                                       if _debug == 'Y'
        #get members
        mbrresult   = mbrcli.getBlock(mbrfilter, mbrsort)
        mbrcode     = mbrresult['code']              #extract code
        hasmore     = mbrresult['hasmore']           #extract hasmore
        pp mbrresult                                        if _debug == 'Y'
        
        # Member exists or not
        #+++++++++++++++++++++
        mbrdata     = mbrresult['data']
        if mbrcode == '200' #<IF2>
            #member exists
            #+++++++++++++
            count_mbrok += 1
            _com.debug("3B-MBR: #{x_reference} exists")
            mbrflag     = true
            mbrdata.each do |page|  #<L3>loop all pages
                pp page                                     if _debug == 'Y'
                #extract values
                mbrpageid           = page['id']
                mbrpagecreatedtime  = page['created_time']
                mbrpageeditedtime   = page['last_edited_time']
                mbrproperties       = mbrcli.allProperties(page)

                #Load fields
                #+++++++++++
                y_seagma    = mbrcli.extrProperty('Seagma').to_i
                
                #Process Modifications
                #+++++++++++++++++++++
                mbrproperties = {
                    'Seagma'=> { 'number'=> x_seagma}
                }
                #check MBR <> XL/csv
                if x_seagma != y_seagma #<IF4>
                    #update MBR
                    _com.debug("3D-MBR: Update page")
                    count_mbradd    += 1
                    if _mode == 'E'
                        result  = mbrcli.updPage(mbrpageid, mbrproperties)
                        rc      = result['code']
                        _com.step("3C-Update Seagma::Ref:#{x_reference}-Old:#{y_seagma}-New:#{x_seagma} with RC: #{rc}")
                        ###exit 9
                    else
                        _com.step("3C-Update Seagma::Ref:#{x_reference}-Old:#{y_seagma}-New:#{x_seagma}")
                    end
                else    #<IF4>
                    _com.debug("3E-Same Seagma::Ref:#{x_reference}-Old:#{y_seagma}-New:#{x_seagma}")
                end #<IF4>
            end #<L3>

        else    #<IF2>  
            #member doesn't exists
            #+++++++++++++++++++++
            count_mbrerr    += 1
            _com.step("3E-MBR: #{x_reference} does not exists")

        end #<IF2>
    end #<L1>
    #
    _com.step("5-Log process")
    text    = "For ACT: #{activity} with MODE: #{_mode} Counters:: Rec:#{count_rec} - MbrOK:#{count_mbrok} - MbrUpd:#{count_mbradd} - MbrErr:#{count_mbrerr}"
    timeto      = Time.now.to_i
    timediff    = timeto - timefrom
    _com.step(text)
#
    _com.stop(program,"ByeBye")
#   <EOF>
