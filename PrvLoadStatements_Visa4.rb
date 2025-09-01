#
=begin
    # =>    PrvLoadStatements_Visa
    # =>    VRP: 1-1-1 241102-1401
    # =>    Function : save all Visa credit statements into Notion DB
    # =>        
    # =>    Parameters :
    #           P1: Y or N
    #           P2: Mode => E or L
    #
    # =>    Process :
                ?
    #
=end
require 'rubygems'
require 'timeout'
require 'net/http'
require 'net/smtp'
require 'uri'
require 'json'
require 'csv'
require 'pp'
#   require 'dir'
#
require '/users/Gilbert/Public/Progs/Prod/Common/ClDirectories.rb'
    exec_mode   = 'P'                                   #change B or P
    _dir    = Directories.new('N')
    arrdirs = _dir.otherDirs(exec_mode)                 #=>{exec,private,membres,common,send,work}
require "#{arrdirs['common']}/ClCommon_2.rb"
    _com    = Common_2.new(false)
#
require "#{arrdirs['common']}/ClNotion.rb"
    downloads_dir   = arrdirs['work']
#
#   Parameters
#   ==========
begin
    _debug  = ARGV[0]       #Y or N or 1..9
    _mode   = ARGV[1]       #L for log or E for Execute
rescue
    _debug  = 'N'
    _mode   = 'L'
end
    _dbgflag    = 'N'
    _dbglvl     = 0
    _mode   = _mode.upcase
    if _debug.class == 'String'
        _debug  = _debug.upcase
        if _debug == 'Y'
          _dbglvl   = 9
          _dbgflag  = 'Y'
        else
          _dbglvl   = 0
        end
    else
        _dbglvl   = 0
        _dbgflag  = 'N'
    end
#
#   Internal functions
#   ==================
    #
    def readVisaLine(p_row=[])
    #+++++++++++++++
    #   INP::   row array 1 string to split(;)
    #   OUT::   row hash into @csv_array
        #check
        return  false   if p_row.length == 0
        row     = p_row.split(";")          #split into fields
        #    pp row
        #load array
        @csv_array  = {}                    #clear array
        @csv_fields.each do |field| #<L1>   #load array
            name    = field[0]
            index   = field[1]
            type    = field[2]
            value   = row[index]            #
        #    puts    "Fields::NAME:#{name}-INDEX:#{index}-TYPE:#{type}-VAL:#{value}"
            case    type    #<SW2>          #<SW1>for conversion
            when    'T'     #<SW2>          #text
                value   = "*"   if value.nil? or value.size == 0
                value   = value.gsub('"','')
            when    'TA'     #<SW2>          #text
                value   = "*"   if value.nil? or value.size == 0
                value   = value.gsub('"','')
            when    'D'     #<SW2>          #date
                value   = "#{value[6,4]}-#{value[3,2]}-#{value[0,2]}"
            when    'DA'     #<SW2>          #date with ""
                value   = value.gsub('"','')
                value   = "#{value[6,4]}-#{value[3,2]}-#{value[0,2]}"
            when    'N'                     #number
                value   = value.gsub(',','.').to_f
            when    'NA'                     #number with space
                value   = value.gsub('"','')
                value   = value.gsub(/\s/, "")
                value   = value.gsub(',','.').to_f
            when    'TB'                    #text to adapt
                value   = 'Retrait'         if value.include?('RETRAIT')
            else                            #others
            end #<SW2>  #<SW1>
            #load array
        #    puts    "Fields::NAME:#{name}-INDEX:#{index}-TYPE:#{type}-VAL:#{value}"
            @csv_array[name]    = value     #add entry {name=>value}
        end #<L1>
       #
       return   true
    end #<def>
    #
#   Variables
#   =========
    program     = 'PrvLoadStatements'
#####Variables#####
    integr      = 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3'  #
    db_name     = 'enct-Fin.Trans.Visa'
                    #https://www.notion.so/cssghe/13172117082a80e0899ecded20a10c6a?v=caab27e82aee4d38904b068fdb546799&pvs=4
    db_id       = '13172117082a80e0899ecded20a10c6a'
#####Variables#####

#   csv infos
    @csv_fields     = [
        ['Extrait',0,'TA'],
        ['Date',1,'DA'],
        ['Date valeur',2,'DA'],
        ['Description',4,'TA'],
        ['Montant',5,'NA'],
        ['Devise',6,'TA']
    ]
    @csv_array      = {}
    @csv_statements = []

#   row infos

#   BD infos

#   Internal
    count_line      = 0
    count_statement = 0
    count_page      = 0
#
#   Init
#   ====
    #Notion class
    _not    = ClNotion.new()
    rc      = _not.loadParams(_debug)
    rc      = _not.initNotion(integr,db_id)             #init cycle

    #FILE class

    _com.start(program,'Start of Script -> Load statements')
    _com.step("Prms::Prod: Debug:#{_debug}/#{_dbgflag}/#{_dbglvl} Mode:#{_mode}")
    _com.step("DBID: #{db_id} - Key: #{integr}")

    #
    t           = Time.now                                      #get time
    currtime    = t.strftime("%Y-%m-%dT%H:%M").strip            #extract YYYY-MM-DD

#    Main code
#   ==========
#
    #Select file to read
    #+++++++++++++++++++
    _com.step("List of .csv files")
        #/Users/gilbert/Library/Mobile Documents/com~apple~CloudDocs/Downloads/V8767-statements.pdf
#    Dir.chdir("/users/Gilbert/Library/Mobile Documents/com~apple~CloudDocs/Downloads")
    Dir.chdir(downloads_dir)
    allfiles    = Dir.glob("*.csv")
    allfiles.each_with_index do |file,index|    #<L1>
        puts    "#{index+1}.#{file}"
    end #<L1>
    print   "Please select file to process by N° => "
    fileindex   = $stdin.gets.chomp.to_i
    fileselect  = allfiles[fileindex-1]
    _com.step("File selected: #{fileselect}")

    #loop all rows fo extract fields
    #+++++++++++++++++++++++++++++++
    _com.step("Extract statements")
    csv_flag    = false
    File.foreach(fileselect) do |row|    #<L1> => @csv_array
        #    pp row
        if csv_flag #<IF2>
            count_line  +=1
            readVisaLine(row)
            _com.step("LINE:#{count_line} => #{@csv_array}")     if _mode == 'L'
            _com.step("*")  if _mode == 'L'
            @csv_statements.push(@csv_array)    #add to statements
        else    #<IF2>
            csv_flag    = true
            next
        end #<IF2>
    end #<L1>
    
    #Write to BD
    #+++++++++++
    _com.step("Add statements to DB")
    @csv_statements.each do |statement| #<L1>loop all statements
        count_statement +=1
        _com.step("STATEMENT:#{count_statement} => #{statement}")     if _mode == 'L'
        _com.step("*")  if _mode == 'L'
        bodyadd = {
            'Titre'=>{'title'=>[{'text'=>{'content'=> statement['Extrait']}}]},
            'Extrait'       =>{'rich_text'=>[{'text' => {'content'=> statement['Extrait']}}]},
            'Date'          =>{'date'=>{'start' => statement['Date']}},
            'Date valeur'   =>{'date'=>{'start' => statement['Date valeur']}},
            'Description'   =>{'rich_text'=>[{'text' => {'content'=> statement['Description']}}]},
            'Montant'       =>{'number'=> statement['Montant']},
            'Devise'        =>{'rich_text'=>[{'text' => {'content'=> statement['Devise']}}]}
        }
        count_page  += 1
        if _mode == 'E' #<IF2>
            result  = _not.addPage(db_id,bodyadd)   #add record
            code    = result['code']                #check code
            _com.step("RC>>>#{count_page} => #{statement['Description']}")
            _com.step("RC>>>#{result}")      if code != '200'
        else    #<IF2>
            _com.step("REC:#{count_page} => #{bodyadd}")
        end #<IF2>
    end #<L1>
    #
    _com.stop(program,"Byebye")
#