#
=begin
    # =>    PrvLoadStatements_file
    # =>    VRP: 4-1-1  <250512-1830>
    # =>    Function : save all CBC statements into Notion DB
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
#

#***** Directories management *****
# Start of block
    require_dir = Dir.pwd
    ### puts    "dirREQUIRE:"+require_dir
require "#{require_dir}/ClDirectories.rb"
    _dir    = Directories.new(false)
# End of block
#***** Directories management *****
#
#
#   Parameters
#   ==========
begin
    _debug  = ARGV[0]       #Y or N or 1..9
    _mode   = ARGV[1]       #L for log or E for Execute
rescue
    _debug  = false
    _mode   = 'L'
end
    _debug  = true if _debug == 'Y'
    _debug  = false if _debug == 'N'
#
#***** Exec environment *****
# Start of block
    program = 'PrvLoadStatements_CBC'
    exec_mode   = 'P'                                   #change B or P
    dbglevel    = 'DEBUG'
    arrdirs = _dir.otherDirs(exec_mode)                 #=>{exec,private,membres,common,send,work}
require "#{arrdirs['common']}/ClCommon_2.rb"
    _com    = Common_2.new(program,_debug,dbglevel)
    private_dir     = arrdirs['private']
    member_dir      = arrdirs['membres']                #members directory
    common_dir      = arrdirs['common']                 #common directory
    work_dir        = arrdirs['work']
    send_dir        = arrdirs['send']
    downloads_dir   = arrdirs['idown']                  #iDrive/Downloads
require "#{arrdirs['common']}/ClNotion.rb"
# End of block
#***** Exec environment *****
#
#
#   Internal functions
#   ==================
    #
    def readFileLine(p_row=[])
    #+++++++++++++++
    #   INP::   row array 1 string to split(;)
    #   OUT::   row hash into @csv_array
        #check
        return  false   if p_row.length == 0
        row     = p_row.split(";")          #split into fields
        #   pp  row
        #load array
        @csv_array  = {}                    #clear array
        @csv_fields.each do |field| #<L1>   #load array
            name    = field[0]
            index   = field[1]
            type    = field[2]
            value   = row[index]            #
            #   puts    "Fields::NAME:#{name}-INDEX:#{index}-TYPE:#{type}-VAL:#{value}"
            case    type    #<SW2>          #<SW1>for conversion
            when    'T'     #<SW2>          #text
                value   = "*"   if value.nil? or value.size == 0
            when    'D'     #<SW2>          #date
                value   = "#{value[6,4]}-#{value[3,2]}-#{value[0,2]}"
            when    'N'                     #number
                value   = value.gsub(',','.').to_f
            when    'TA'                    #text to adapt
                value   = 'Colruyt-mmdd'    if value.include?('COLRUYT')
                value   = 'Pharmacie'       if value.include?('NIVELPHARMA')
                value   = 'Hôpital'         if value.include?('NIVELLES ACCUEIL POLYC')
                value   = 'Frais'           if value.include?('FORFAIT')
                value   = 'Relevé MC'       if value.include?('DECOMPTE CARTE DE CREDIT CBC')
                value   = 'Retrait'         if value.include?('RETRAIT')
            else                            #others
            end #<SW2>  #<SW1>
            #load array
            @csv_array[name]    = value     #add entry {name=>value}
        end #<L1>
       #
       return   true
    end #<def>
    #
#   Variables
#   =========
    program     = 'PrvLoadStatements_CBC'
    integr      = 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3'  #    #https://www.notion.so/cssghe/12372117082a8054aad7ffb0513b5a61?v=12372117082a803480f5000c9ba48bb6&pvs=4
    db_name     = 'enct.Fin-Trans_CBC'
                    #https://www.notion.so/cssghe/12372117082a801daa1feb1ef00ffa9d?v=12372117082a8059adb5000cbae6f76c&pvs=4
    db_id       = '12372117082a801daa1feb1ef00ffa9d'
    cbc_id      = '511dea44b6ef41f18029830e1b8e224c'    #https://www.notion.so/cssghe/CBC-Commun-511dea44b6ef41f18029830e1b8e224c?pvs=4
    sem_00      = ''
    mois_00     = ''
    count_page      = 0

#   csv infos
    @csv_fields     = [
        ['Numéro de compte',0,'T'],
        ['Nom rubrique',1,'T'],
        ['Nom',2,'T'],
        ['Devise',3,'T'],
        ['Numéro extrait',4,'T'],
        ['Date',5,'D'],
        ['Description',6,'TA'],
        ['Date valeur',7,'D'],
        ['Montant',8,'N'],
        ['Solde',9,'N'],
        ['Crédit',10,'N'],
        ['Débit',11,'N'],
        ['Numéro de compte contrepartie',12,'T'],
        ['BIC contrepartie',13,'T'],
        ['Contrepartie',14,'T'],
        ['Adresse contrepartie',15,'T'],
        ['CommStruct',16,'T'],
        ['CommLibre',17,'T']
    ]
    @csv_array      = {}
    @csv_statements = []

#   row infos

#   BD infos

#
#   Init
#   ====
    #Notion class
    _not    = ClNotion.new()
    rc      = _not.loadParams(_debug)
    rc      = _not.initNotion(integr,db_id)             #init cycle

    #FILE class
    
    _com.start(program,'Start of Script -> Load statements for CBC')
    _com.step("Prms::Prod: Debug:#{_debug} Mode:#{_mode}")

    #
    t           = Time.now                                      #get time
    currtime    = t.strftime("%Y-%m-%dT%H:%M").strip            #extract YYYY-MM-DD

#    Main code
#   ==========
#
    #Select file to read
    #+++++++++++++++++++
    _com.step("List of .csv files")
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
        pp  row     if _debug
        if csv_flag #<IF2>
            readFileLine(row)
            _com.debug("LINE:#{@csv_array}")
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
        _com.debug("STATEMENT:#{statement}")
        bodyadd = {
            'Titre'=>{'title'=>[{'text'=>{'content'=> "CBC-Opération"}}]},
            'Numéro de compte'  =>{'rich_text'=>[{'text' => {'content'=> statement['Numéro de compte']}}]},
            'Nom rubrique'      =>{'rich_text'=>[{'text' => {'content'=> statement['Numéro de compte']}}]},
            'Nom'               =>{'rich_text'=>[{'text' => {'content'=> statement['Nom']}}]},
            'Devise'            =>{'rich_text'=>[{'text' => {'content'=> statement['Devise']}}]},
            'Numéro extrait'    =>{'rich_text'=>[{'text' => {'content'=> statement['Numéro extrait']}}]},
            'Date'              =>{'rich_text'=>[{'text' => {'content'=> statement['Date']}}]},
            'Description'       =>{'rich_text'=>[{'text' => {'content'=> statement['Description']}}]},
            'Date valeur'   =>{'date'=>{'start' => statement['Date valeur']}},
            'Montant'   =>{'number'=> statement['Montant']},
            'Solde'     =>{'number'=> statement['Solde']},
        #    'Crédit'    =>{'number'=> statement['Crédit']},
        #    'Débit'     =>{'number'=> statement['Débit']},
            'Numéro de compte contrepartie'  =>{'rich_text'=>[{'text' => {'content'=> statement['Numéro de compte contrepartie']}}]},
            'BIC contrepartie'  =>{'rich_text'=>[{'text' => {'content'=> statement['BIC contrepartie']}}]},
            'Adresse contrepartie'      =>{'rich_text'=>[{'text' => {'content'=> statement['Adresse contrepartie']}}]},
            'Communication libre'       =>{'rich_text'=>[{'text' => {'content'=> statement['CommLibre']}}]},
            'Communication structurée'  =>{'rich_text'=>[{'text' => {'content'=> statement['CommStruct']}}]},
            'rlbComptes'    =>{'relation'=>[{'id'=>cbc_id}]}
        }
        count_page  += 1
        if _mode == 'E' #<IF2>
            result  = _not.addPage(db_id,bodyadd)   #add record
            code    = result['code']                #check code
            _com.step("RC>>>#{count_page} => #{code} : #{statement['Description']}")
            _com.step("RC>>>#{result}")      if code != '200'
        else    #<IF2>
            _com.step("LOG:#{count_page} => #{bodyadd}")
        end #<IF2>
    end #<L1>
    #
    _com.stop(program,"Byebye")
#