#
=begin
    Progr:      EneoBwCom_ChecksXl6
    Function:   check contents before add to modifications
    Build:      2-4-1   <250111-0730>
    Call:       ruby EneoBwCom_ChecskXl6.rb  N
    Input:      csv file
    Output:     Errors
    Parameters:
        P1: debug => N or Y
    explains:
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
#Parameters
#++++++++++
    _debug  = ARGV[0]       #debug
    _debug  = _debug.upcase
    _debug  = false     if _debug == 'N'
    _debug  = true      if _debug == 'Y'
    @_debug = _debug

#
#***** Exec environment *****
# Start of block
    program     = 'EneoBwCom_AddUpd6'
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

    #check Référence, Nom, Prénom
    def checkReference(p_nom='',p_prenom='')
    #-----------------
        puts    "DBG>>REFERENCE: #{p_nom}-#{p_prenom}"  if @_debug
        return  false   if p_nom.nil? or p_nom.size == 0
        return  false   if p_prenom.nil? or p_prenom.size == 0
        ref     = "#{p_nom}-#{p_prenom}"
        return  false   if ref != @reference
        char    = @reference[1]     #check D'h
        if char == "'"  #<IF1>
            @reference[2]    = @reference[2].upcase
        end #<IF1>
        return true
    end #<def>
    #
    #check gsm/phone number
    def checkPhone(p_type='',p_num='')
    #-------------
        puts    "DBG>>PHONE: #{p_num}"  if @_debug
        case    p_type  #<SW1>
        when    'Gsm'   #<SW1>
            len = 12
        when    'Phone' #<SW1>
            len = 11
        end #<SW1>
        if p_num == '*' or p_num == '+' #<IF1>
            addLogfile("PHONE::#{p_num}",true)
        else
            p_num   = "+#{p_num}"   if p_num[0] != "+"
            flag_phone  = false
            flag_phone  = true  if p_num.size != len
            flag_phone  = true  if p_num.index("+32").nil?
        end #<IF1>
        if flag_phone #<IF1>
            addLogfile("PHONE::#{p_num}",false)
        else    #<IF1>
            addLogfile("PHONE::#{p_num}",true)
        end #<IF1>
    end #<def>
    #
    #checl email
    def checkEmail(p_str='')
    #-------------
        puts    "DBG>>EMAIL: #{p_str}"  if @_debug
        flag_mail   = false
        flag_mail   = true      if p_str.index("@").nil?
        if flag_mail #<IF2>
            addLogfile("MAIL::#{p_str}",false)
        else    #<IF2>
            addLogfile("MAIL::#{p_str}",true)
        end #<IF2>
    end #<def>
    #
    #check cotisation
    def checkCotisation(p_val='')
    #------------------
        puts    "DBG>>COTIS: #{p_val}"  if @_debug
        if p_val != '*' #<IF2>
            case    p_val  #<SW3>
            when    '0'
                addLogfile("COTISATION::#{p_val}",true)
            when    '17'
                addLogfile("COTISATION::#{p_val}",true)
            when    '9'
                addLogfile("COTISATION::#{p_val}",true)
            else    #<SW3>
                addLogfile("COTISATION::#{p_val}",false)
            end #<SW3>
        else    #<IF2>
            addLogfile("COTISATION::#{p_val}",false)
        end #<IF2>
    end #<def>
    #
    #check date
    def checkDate(p_date='')
    #------------
        puts    "DBG>>DATE: #{p_date}"  if @_debug
        type        = p_date.class
    #    puts    "checkDate:: DATE: #{p_date} CLASS: #{type}"
        flag_date   = false
        flag_date   = true      if  p_date.index("-")==0 and
                                    p_date.index("/")==0
        flag_date   = true      if p_date.size != 10
        if flag_date    #<IF2>
            addLogfile("DATE::#{p_date}",false)
        else    #<IF2>
            addLogfile("DATE::#{p_date}",true)
        end #<IF2>
    end #<def>
    #
    #checl address
    def checkAdresse(p_adr='',p_can='',p_loc='')
    #---------------
        puts    "DBG>>ADR: #{p_adr}-#{p_can}-#{p_loc}"  if @_debug
        flag_adr    = false
        flag_adr    = true      if p_adr.size == 0
        flag_adr    = true      if p_can.size == 0
        flag_adr    = true      if p_loc.size == 0
        if flag_adr #<IF1>
            addLogfile("ADRESSE::#{p_adr} / #{p_can} / #{p_loc}",false)
        else    #<IF1>
            addLogfile("ADRESSE::#{p_adr} / #{p_can} / #{p_loc}}",true)
        end #<IF1>
    end #<def>
    #
    #check Eneo/EneoSport
    def checkEneo(p_str='',p_ctrl='')
    #------------
        puts    "DBG>>ENEO: #{p_ctrl}"  if @_debug
        flag_eneo   = false
        if p_ctrl == 'EneoSport'   #<IF1>
            flag_eneo   = true          if p_str != p_ctrl
        end #<IF1>
        if p_ctrl == 'Eneo'   #<IF1>
            flag_eneo   = true          if p_str != p_ctrl
        end #<IF1>
        if flag_eneo    #<IF1>
            addLogfile("ENEO::#{p_ctrl} -> #{p_str}",false)
        else    #<IF1>
            addLogfile("ENEO::#{p_ctrl} -> #{p_str}",true)
        end #<IF1>
    end #<def>
    #
    #check activities
    def checkActivities(p_prc,p_sec)
    #------------------
        puts    "DBG>>ACTS: #{p_prc}-#{p_sec}"  if @_debug
        if p_prc.size == 0 and p_sec.size == 0  #<IF1>
            addLogfile("ACTIVITES::#{p_prc} / #{p_sec}",false)
        else    #<IF1>
        #    puts    "DBG>#{p_prc} - #{p_sec}"
            if p_prc != '*' #<IF2>
                if @arreneo.key?(p_prc)   #<IF3>
                    addLogfile("ACTPRC::#{p_prc} / ",true)
                else    #<IF3>
                    addLogfile("ACTPRC::#{p_prc} / ",false)
                end #<IF3>
            end #<IF2>

            if p_sec != '*' #<IF2>
                results = EneoBwCom.split(p_sec,'*',',')
                count   = results[0].to_i
                if count > 0    #<IF3>
                    arritems    = results[1]
                    arritems.each do |item| #<L4>
                        if @arreneo.key?(item)   #<IF5>
                            addLogfile("ACTSECS::/ #{item}",true)
                        else    #<IF5>
                            addLogfile("ACTSECS::/ #{item}",false)
                        end #<IF5>
                    end #<L4>
                end #<IF3>
           end #<IF2>
        end #<IF1>
    end #<def>


    #add item to logfile
    def addLogfile(p_text='None',p_ok=true)
    #-------------
        if @reference != @oldreference
            @content.concat(">>>######<br>")
            @contentx.concat(">>>######\n")
            @oldreference   = @reference
        end
        if p_ok == true #<IF1>
        #    statut  = "OK"
        #    @count_ok   += 1
        #    @content.concat("ENREG::#{@count_rec} REFERENCE::#{@reference} #{p_text} -> #{statut}<br>")
        #    @contentx.concat("ENREG::#{@count_rec} REFERENCE::#{@reference} #{p_text} -> #{statut}\n")
        elsif p_ok == false    #<IF1>
            statut  = "Valeur invalide <<<<<<######<<<<<<"
            @count_syntax    += 1
            @content.concat(">>>>><br>")
            @contentx.concat(">>>>>\n")
            @content.concat("ENREG::#{@count_rec} REFERENCE::#{@reference} #{p_text} -> #{statut}<br>")
            @contentx.concat("ENREG::#{@count_rec} REFERENCE::#{@reference} #{p_text} -> #{statut}\n")
            @content.concat(">>>>><br>")
            @contentx.concat(">>>>>\n")
        else    #<IF1>
            statut  = "#{p_ok}<<<<<<######<<<<<<"
            @content.concat(">>>>><br>")
            @contentx.concat(">>>>>\n")
            @content.concat("ENREG::#{@count_rec} REFERENCE::#{@reference} #{p_text} -> #{statut}<br>")
            @contentx.concat("ENREG::#{@count_rec} REFERENCE::#{@reference} #{p_text} -> #{statut}\n")
            @content.concat(">>>>><br>")
            @contentx.concat(">>>>>\n")
        end #<IF1>
        @flag_error      = true
    end #<def>
    #
#
#Variables
#+++++++++
    @content        = "*****Start*****<br><br>"
    @contentx       = "*****Start*****\n"
    @count_rec      = 0
    @count_next     = 0
    @count_ok       = 0
    @count_stop     = 5
    @count_syntax   = 0
    @flag_error     = false
    @reference      = ''
    @oldreference   = ''
    @arreneo        = {}
    @arrmail        = {}
    @arrcdc         = {}
#
    program     = 'EneoBwCom_CheckXl4'

    arrfields   = ['object','id','created_time','last_edited_time','properties']
    arrprops    = ['Référence','Auteur','Texte']
    arrblocks   = []

    integr      = 'secret_2XXOYzX5JThHqZviHGZpPna5ihVU2o3knCvrCu76RjS'
    repnext     = ''
    actprc      = ""
    actsecs     = ""
    actsec1     = ""
    actsec2     = ""
    actsec3     = ""
    actsec4     = ""
    actsec5     = ""

    flag_check      = false
    flag_extrn      = false
    flag_minim      = false

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
        #old certificat
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
#   *   *   *   *   *   *   *   *   *   *   *   *   *   *   *   *
#Main code
#+++++++++
#   Initialisation
#   ==============
    timefrom    = Time.now.to_i
    timenow     = Time.now

    #Get values
    #++++++++++
    currentcdc  = 'NIV'
    currentcdcx = currentcdc + "-"
    #
    #
    #get values for this cdc
    #+++++++++++++++++++++++
    item        = EneoBwCom.load(currentcdc)     #[mbrid,modid,logid,[cdc,act,f_fields]]
                #***************
    mbrid       = item[0]                                       #members db
    modid       = item[1]                                       #modifications db
    logid       = item[2]                                       #logfile db
    values      = item[3]
    arract      = values[1]                                     #activities for this cdc
    arrf_       = values[2]                                     #fields position
    @arreneo    = values[5]                                     #Eneo/EneoSport (act=>value)
    @arrmail    = values[6]                                     #Emails (act=>value)
    @arrcdc     = item[4]
    pp  @arrf_                                                  if _debug == 'Y'

    #get activity
    #++++++++++++
    item    = EneoBwCom.reqAct(currentcdc)                      #request activity
            #*****************
    actnum  = item[0]                                           #number
    acttxt  = item[1]                                           #text
    activity    = "#{currentcdcx}#{acttxt}"                     #activity in use
    puts ">>>Act:: Num: #{actnum} Txt: #{acttxt} => #{activity}"
    exit 5                  if actnum == 0
    _file       = acttxt    #if _file == 'X'                    #file in use

    #make filenames
    #++++++++++++++
    fileread    = "#{process_dir}/#{currentcdcx}ListeMembres_#{_file}-Retour.csv"
    filewrite   = "#{send_dir}/#{currentcdcx}ListeMembres_#{_file}-Erreurs.pdf"

=begin
    #compute range of rows
    #+++++++++++++++++++++
    print ">>>Rows to read : Header(s)[0] ? "
    rephdr      = $stdin.gets.chomp
    rephdr      = '0'       if rephdr.size == 0
    rephdr      = rephdr.to_i
    print ">>>Rows to read : first row[2] ? "                      #0 => skip headers >0 => first row -2
    repfirst    = $stdin.gets.chomp
    repfirst    = '2'       if repfirst.size == 0
    repfirst    = repfirst.to_i
    print ">>>Rows to read : Last row ? "
    replast     = $stdin.gets.chomp.to_i                        #
    firstrow    = repfirst
    firstrow    = rephdr    if repfirst == 0
    lastrow     = replast - 1
=end
    #
    #Starting
    #++++++++
    _com.start(program," with Debug:#{_debug} Activity:#{activity} File:#{fileread}")
    _com.step("1-Initialize")

    _com.step("1A-List of .csv files")
#    Dir.chdir("/users/Gilbert/Library/Mobile Documents/com~apple~CloudDocs/Downloads")
    Dir.chdir(process_dir)
    allfiles    = Dir.glob("*.csv")
    allfiles.each_with_index do |file,index|    #<L1>
        puts    "#{index+1}.#{file}"
    end #<L1>
    #   print   "1B-Please select file to process by N° => "
    #   fileindex   = $stdin.gets.chomp.to_i
    #   fileselect  = allfiles[fileindex-1]
    #   _com.step("1C-File selected: #{fileselect}")

    #Check file
    #++++++++++
    rc  = File.file?(fileread)
    if rc == false
        _com.step(">>>File doesn't exist => #{fileread}")
        exit 1
    end

    #Open xlsx file
    #++++++++++++++
#old    workbook    = RubyXL::Parser.parse(fileread)
#old    worksheet   = workbook.worksheets[0]                        #first sheet only

    #pdf
    header      = "
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
    body        = ''

    #Client instances
    #++++++++++++++++
    #
#
#   Loop all rows & columns
#   =======================
    _com.step("2-Extract all rows")
    csv_flag    = false                                         #to skip 1st line (titles)
    CSV.foreach(fileread) do |row|     #<L1> => @csv_array
        puts    "DBG>CSVREAD:#{row}"
        if csv_flag #<IF2>
            if  readCsvLine(row)    #<IF3>
                puts    "DBG>>CSV:#{@csv_array}"    if _debug == 'Y'
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
        @count_rec  += 1
        @flag_error = false
        flag_check  = false

        #Break or Next on Reference and Statut
        #*************************************
        begin
            if _debug == 'Y'
                x_reference = statement['Référence']
                puts    "DBG>REF:#{x_reference}"
            else
                x_reference = statement['Référence']
            end
        rescue
            addLogfile("REFERENCE::#{x_reference}",false)
            next
        end
        if x_reference == "*"  #<IF2>
            break   #cancel iteration <L1>
        end #<IF2>
        @reference  = x_reference
        #
        begin
            x_statut    = statement['Statut']
            x_statut    = x_statut.strip
            x_statut    = x_statut.capitalize
        rescue
            x_statut    = '*'
        end
        _com.step("STEP-XL1::REF:#{x_reference} STA:#{x_statut}")
        if x_statut == "*"  #<IF2>
            next    #go to next iteration
        end #<IF2>
        case    x_statut    #<SW2
        when    'Nouveau','Suppression','Modification','Arrêt','Décès'
            addLogfile("STATUT::#{x_statut}",true)
        else    #<SW2>
            addLogfile("STATUT::#{x_statut}",false)
        end #<SW2>

        #OK
        _com.step("STEP-XL2::REF:#{x_reference} Statut:#{x_statut}")

        #load fields for syntax checking
        #+++++++++++++++++++++++++++++++
        begin
            x_nom       = statement['Nom']
        rescue
            addLogfile("NOM::",false)
            next
        end

        begin
            x_prenom    = statement['Prénom']
        rescue
            addLogfile("PRENOM::",false)
            next
        end

        begin
            x_cdc       = statement['CDC']
        rescue
            addLogfile("CDC::",false)
            next
        end

        begin
            x_civilite  = statement['Civilité']
        rescue
            addLogfile("CIVILITE::",false)
            next
        end

        begin
            x_adresse   = statement['Adresse']
            x_canton    = statement['Canton']
            x_localite  = statement['Ville']
        rescue
            addLogfile("ADRESSE::Rue ou Canton ou Localite",false)
            next
        end

        begin
            x_gsm       = statement['GSM']
            x_telephone = statement['Téléphone']
            x_mail      = statement['Mails']
        rescue
            addLogfile("COMMUNICATION::Gsm ou Telephone ou Mail",false)
            next
        end

        begin
            x_naissance = statement['Date Naissance']
        rescue
            addLogfile("NAISSANCE::",false)
            next
        end

        begin
            x_cotisation= statement['Cotisation']
            x_eneo      = statement['EneoSport']
        rescue
            addLogfile("ENEO::Cotisation ou EneoSport",false)
            next
        end
    
        begin
            x_entree    = statement['Date Entrée']
            x_sortie    = statement['Date Sortie']
            x_paiement  = statement['Date Paiement']
            x_deces     = statement['Date Décès']
        rescue
            addLogfile("ENTREE-SORTIE::",false)
            next
        end
        
        begin
            x_actprc    = statement['ActPrc']
            x_actsecs   = statement['ActSecs']
        rescue
            addLogfile("PRINCIPAL-SECONDAIRE::",false)
            next
        end

        begin
            x_va    = statement['V-A']
        rescue
            addLogfile("V-A::",false)
            next
        end
        #
        #puts for checks
        #+++++++++++++++
        puts    "DBG>Checks::   CDC:#{x_cdc}"
        puts    "               STATUT:#{x_statut} #{x_va}"
        puts    "               NOM-PRENOM:#{x_civilite} #{x_nom} #{x_prenom}"
        puts    "               COMM:#{x_gsm} #{x_telephone} #{x_mail}"
        puts    "               ADR:#{x_adresse} #{x_canton} #{x_localite}"
        puts    "               ENEO:#{x_cotisation} #{x_eneo}"
        puts    "               DATES:#{x_naissance} #{x_entree} #{x_paiement} #{x_sortie} #{x_deces}"
        puts    "               ACTS:#{x_actprc} - #{x_actsecs}"

        #make CPE
        #++++++++
        if x_actprc != '*'  #<IF2> actprc
            x_cpe   = "Cotisant"
        elsif x_actsecs != '*'  #<IF2>
            x_cpe   = "Participant"
            x_cpe   = "Extérieur"   if x_cdc != currentcdc
        end #<IF2>

        #set states
        #++++++++++
        #   Statut          CDC     Check
        #   -----------------------------
        #   Nouveau         NIV     true
        #   Nouveau         XYZ     false
        #   Modification    NIV     true
        #   Modification    XYZ     Error
        #   Arrêt           XYZ     false
        #   Décédé          XYZ     false
        #   -----------------------------
        #   flag_check  = Principal & Nouveau / Modification
        #   flag_extrn  = Secondaire & Nouveau / Modification
        #   **************************************************
        #
        flag_check  = true      if x_statut == 'Nouveau' and x_cdc == currentcdc
        flag_check  = true      if x_statut == 'Modification' and x_cdc == currentcdc
        flag_extrn  = true      if x_statut == 'Nouveau' and x_cdc != currentcdc
        flag_extrn  = true      if x_statut == 'Modification' and x_cdc != currentcdc
#        flag_extrn  = true      if x_statut == 'Suppression' and x_cdc != currentcdc
        flag_minim  = true      if flag_check && flag_extrn

        #full service
        #++++++++++++
        #check class
        addLogfile("COHERENCE-CANTON: pas au bon format",false) if x_canton.is_a?(String) == false
        addLogfile("COHERENCE-COTIS: pas au bon format",false)  if x_cotisation.is_a?(String) == false
        addLogfile("COHERENCE-GSM: pas au bon format",false)    if x_gsm.is_a?(String) == false
        addLogfile("COHERENCE-PHONE: pas au bon format",false)  if x_telephone.is_a?(String) == false
        addLogfile("COHERENCE-MAIL: pas au bon format",false)   if x_mail.is_a?(String) == false
        addLogfile("COHERENCE-NAISS: pas au bon format",false)  if x_naissance.is_a?(String) == false
        addLogfile("COHERENCE-ENTREE: pas au bon format",false) if x_entree.is_a?(String) == false
        addLogfile("COHERENCE-PAIEM: pas au bon format",false)  if x_paiement.is_a?(String) == false
        addLogfile("COHERENCE-SORTIE: pas au bon format",false) if x_sortie.is_a?(String) == false
        addLogfile("COHERENCE-DECES: pas au bon format",false)  if x_deces.is_a?(String) == false

        if x_cdc == currentcdc
            addLogfile("CDC: #{x_cdc}",true)
        else
            addLogfile("CDC: #{x_cdc}","CDC correct ?")
        end

        if flag_check or flag_extrn#<IF2>
            if  checkReference(x_nom,x_prenom)  #<IF3>
                addLogfile("NON + PRENOM::#{x_nom}-#{x_prenom}",true)
            else    #<IF3>
                addLogfile("NOM + PRENOM::#{x_nom}-#{x_prenom}",false)
            end #<IF3>
        end #<IF2>
        #
        if flag_check   #<IF2>
            #gsm
            checkPhone('Gsm',x_gsm)             if x_gsm != '*'

            #phone
            checkPhone('Phone',x_telephone)     if x_telephone != '*'

            #mail
            checkEmail(x_mail)                  if x_mail != '*'

            #cotis
            checkCotisation(x_cotisation)       if x_cotisation != '*'

            #birthday
            checkDate(x_naissance)              if x_naissance != "*"

            #input date
            checkDate(x_entree)                 if x_entree != "*"

            #output date
            checkDate(x_sortie)                 if x_sortie != "*"

            #eneosport/eneo
            checkEneo(x_eneo,@arreneo[activity])

            #fields spec 2 activities
            checkActivities(x_actprc,x_actsecs)

            #address
            checkAdresse(x_adresse,x_canton,x_localite) if x_adresse != '*'

            #cohérences
            #++++++++++
            #Common
            if  x_cotisation != "0" and x_paiement == "*" or
                x_cotisation == "0" and x_paiement != "*"

                addLogfile("COHERENCE-COTIS::CDC:#{x_cdc} / #{x_cotisation}/#{x_paiement}",false)
            end
            if  x_va.include?('V') and
                x_cdc != currentcdc

                addLogfile("COHERENCE-VA::CDC:#{x_cdc} / #{x_va}",false)
            end
            case x_statut   #<SW3>
            when    'Nouveau'
                if  x_adresse == "*" or #<IF3>
                    x_canton == "*" or
                    x_localite == "*" or
                    x_entree == "2000-01-01" or
                    (x_cdc == currentcdc and x_naissance == "2000-01-01") or
                    (x_cdc == currentcdc and x_actprc == "*") or
                    (x_cdc != currentcdc and x_actsecs == "*")

                        addLogfile("COHERENCE-NOUVEAU::CDC:#{x_cdc} / ADR:#{x_adresse}/#{x_canton}/#{x_localite} /NAIS:#{x_naissance} /INSCR:#{x_entree} /ACT:#{x_actprc}/#{x_actsecs}",false)
                end #<IF3>
            when    'Modification'

            when    'Suppression'

            when    'Arrêt'
                if  x_cdc != currentcdc or
                    x_sortie == "*"

                    addLogfile("COHERENCE-ARRET:CDC:#{x_cdc} /SORTIE:#{x_sortie}",false)
                end
            when    'Décès'
                if  x_cdc != currentcdc or
                    x_deces == "*"

                    addLogfile("COHERENCE-ARRET:CDC:#{x_cdc} /DECES:#{x_deces}",false)
                end
            end #<SW3>

        end #<IF2>
        #
        addLogfile("**********","<>")

        if @flag_error   #<IF2>
            @count_ok    += 1 
        else    #<IF2>
            _com.step("STEP-REQ::REF:#{x_reference},REQ:#{x_statut},CDC:#{x_cdc},ActPrc:#{x_actprc},ActSecs:#{x_actsecs},CPE:#{x_cpe}")
        end #<IF2>
        #

        #exit 9

    end #<L1>
    #
    @reference  = "RESULTATS"
    text    = "For ACT: #{activity} with Counters:: Rec:#{@count_rec} - Ok:#{@count_ok} - Errors:#{@count_syntax} "
    @texth  = "Pour ACTIVITE: #{activity} COMPTEURS:: Enregistrements:#{@count_rec} - Ok:#{@count_ok} - Erreurs:#{@count_syntax} <br>"
    addLogfile("*****Resultat*****","<>")
    addLogfile("#{text}","<>")
    addLogfile("*****Resultat*****","<>")
    
    #print Ok or Errors
    #++++++++++++++++++
    puts "#{@contentx}"

    #Create pdf
    #++++++++++
    _com.step("3:: Create pdf")
    body    = "<body> #{@content} </body>"
    html    = "#{header} #{body}"
    _pdf    = PDFKit.new(html)
    _pdf.to_file(filewrite)

    #send emails
    #+++++++++++
    print   "*  Send email ? : "
    reply   = $stdin.gets.chomp.upcase
    if reply == 'Y' #<IF1>
        arrto   = @arrmail[activity]
        arrto.each do |recip|   #<L2>

            recip   = "eneo@heintje.net"

            message = "From: EneoBW Listes <eneo@heintje.net>\nTo: #{recip}\nMIME-Version: 1.0\nContent-type: text/html\nSubject: Erreurs\n\n"
            message = message + "<h3>Des erreurs se trouvent dans votre dernier tableau.</h3>"
            message = message + "<h4>RESULTAT:</h4>#{@texth}"
            message = message + "<h4>TEXTE:</h4>#{@content}"
            message = message + "<h4>Merci de corriger</h4><br><br>"
            message = message + "Fin du contrôle syntaxique #"
            #send email
            print   "Send email to: #{recip} ? "
            reply2  = $stdin.gets.chomp.upcase
            if reply2 == 'Y'    #<IF3>
                    Net::SMTP.start('smtp.fastmail.com','587','fastmail.com','gheintje@xsmail.com','4t788f362m7v493f','PLAIN') do |smtp|    #server, port, domain, account, password, authtype
                        smtp.send_message message, "eneo@heintje.net","#{recip}"
                    end #<NET>
            end #<IF3>
        end #<L2>
    end #<IF1>


    #exit & logout
    #+++++++++++++
    _com.step("4:: Log process")
    timeto      = Time.now.to_i
    timediff    = timeto - timefrom
    _com.step(text)
    #
    logproperties   = {
        'Function'=> {'title'=> [{'text'=> {'content'=> "EneoBwCom_CheckXL"}}]},
        'Text'=> {'rich_text'=> [{'text' => {'content'=> text}}]},
        'Time'=> {'number'=> timediff}
    }
#
    _com.stop(program,"ByeBye, counters: REC:#{@count_rec}")
#   <EOF>
