#
=begin
    # => Class - ClCommon_2.rb
    # => +++++++++++++++++++
    #   Build: 2-1-0    <250309-1243>
    # => Functions :
            #initialize
            #instcount :: return count of instances
            #debug :: print up to 5 strings
            #start :: get values, dispatch & start the script
            #step ::
            #stop ::
            #exit ::
            #currentDir ::
            #chkvalues ::
            #execprog ::
            #repyn ::
            #debug ::
            #wait ::

=end
#Requires
#--------
require 'rubygems'
require 'timeout'
require 'date'
require 'pp'
require 'logger'
require 'mail'
require 'json'
#
class Common_2
#*************
#Include modules
#===============
#
#def accessors
#=============
    attr_accessor :_prog
#
#class variables
#===============
    @@instcount     = 0
    @@currentdir    = Dir.pwd

    @@not_secrets   = {}
    @@not_dbids     = {}
    @@classname     = 'Common_2'
    @@log_handle    = nil
    @@dbglevel      = 'DEBUG'
#
#instance variables
#==================
    @_prog      = ''
    @dbflag     = false
    @timefrom   = 0
    @timeto     = 0
    @program    = ''
    @log_handle    = nil
    @dbglevel      = 'DEBUG'

    @json_file  = ''
    @json_data  = {}
#
#Constructor
#===========
    def initialize(p_prog='None',p_dbg=false,p_level='None')
    #+++++++++++++
       #instance variables
       @dbgflag    = p_dbg
       @dbglevel   = p_level
       @program    = p_prog
       logData("*****")
       logData("Common_2"+"::Initialized for program: #{@program}, debug: #{@dbgflag}, level: #{@dbglevel}")
    end
#
#Accessor
#========
    def currentDir()
    #+++++++++++++
        return @@currentdir
    end
    #
    def otherDirsX()
    #++++++++++++++
    #INP:
    #OUT: {mode=>,b1=>,b2=>,b3=>,pa=>,pb=>,pc=>,downloads=>,lists=>,work=>,send=>}
        logData("Common_2"+"::otherDirsX called")
        exec    = 'N'   #None
        exec    = 'B'   if @@currentdir.include?('Dvlps')
        exec    = 'P'   if @@currentdir.include?('Prod')
        result  = {
          'exec'=>"#{exec}",
          'b1'=>'',
          'b2'=>'',
          'b3'=>'/users/Gilbert/pCloudSync/Progs/Dvlps/MembersV2-3/',
          'pa'=>'',
          'pb'=>'/users/Gilbert/pCloudSync/Progs/Prod/PartB/',
          'pc'=>'/',
          'downloads'=>'/users/Gilbert/Library/Mobile Documents/com~apple~CloudDocs/Downloads/',
          'lists'=>'/users/Gilbert/pCloudSync/MemberLists/',
          'work'=>'/users/Gilbert/pCloudSync/MemberLists/Works/',
          'send'=>'/users/Gilbert/pCloudSync/MemberLists/ToSend/'
        }
        logData("Common_2"+"::otherDirsX result: #{result.inspect}")
        return  result
    end #<def>
#
#Class methods
#=============
    def self.logData_cl(p_data='***')
#   +++++++++++++++++++
        #INP:   nothing
        #OUT:   log record
        #
        if @@log_handle.nil? #<IF1>
            @@log_handle = Logger.new("/users/Gilbert/Public/Logs/Classes_2.log",'daily')
            @@log_handle.formatter = proc do |severity, datetime, progname, msg|
                "#{datetime}: #{severity} -> #{msg}\n"
            end

            case    @@dbglevel   #<SW2>
            when   'DEBUG'
                @@log_handle.level = Logger::DEBUG
            when    'INFO'
                @@log_handle.level = Logger::INFO
            when    'WARM'
                @@log_handle.level = Logger::WARM
            when    'ERROR'
                @log_handle.level = Logger::ERROR
            when    'FATAL'
                @@log_handle.level = Logger::FATAL
            when    'UNKNOWN'
                @@log_handle.level = Logger::UNKNOWN
            end #<SW2>
        end#<IF1>
        @@log_handle.debug(p_data)
    end #<def>
#
#Instance methods
#================
    # Missing
    #========
    def method_missing(name, *args)
    #+++++++++++++++++
        puts    "DBG>>>ClCommon_2>>Method>#{name} is missing "
    end #<def>
    #
    #load parameters
    def params(p_prog='None',p_dbg=false)
    #+++++++++
       #instance variables
    end #<def>
    #
    #start a script
    def start(p_script='None',p_text='None',p_p1='*',p_p2='*',p_p3='*',p_p4='*',p_p5='*')
    #++++++++
        prmp1   = '*'
        prmp2   = '*'
        prmp3   = '*'
        prmp4   = '*'
        prmp5   = '*'
        @timefrom   = Time.now()
        logData("Common_2"+":: Starting: "+p_script)

        puts "###"
        step("Start #{p_script} -> #{p_text}")

        if p_p1 != '*'
            puts "###For #{p_script} -> enter parameters"
            print "###For P1: #{p_p1} ? : "
            prmp1 = $stdin.gets.chomp
            if p_p2 != '*'
                print   "###For P2: #{p_p2} ? : "
                prmp2 = $stdin.gets.chomp
                if p_p3 != '*'
                    print "###For P3: #{p_p3} ? : "
                    prmp3 = $stdin.gets.chomp
                    if p_p4 != '*'
                        print "###For P4: #{p_p4} ? : "
                        prmp4 = $stdin.gets.chomp
                        if p_p5 != '*'
                            print "###For P5: #{p_p5} ? : "
                            prmp5 = $stdin.gets.chomp
                        end
                    end
                end
            end
        end
        puts "###"
        prms    = [prmp1,prmp2,prmp3,prmp4,prmp5]
        return prms
    end
    #
    #print a step
    def step(p_step="None")
    #+++++++
            puts ">>>Step:: #{p_step}"                      if @_debug != 'N'
        end #<def>
    #
    #stop a script
    def stop(p_prog='*',p_text='Byebye')
    #+++++++
        @timeto = Time.now()
        @program    = p_prog    if p_prog != '*'
        logData("Common_2"+":: "+p_prog+": Stopped")
        step("End of #{@program} with #{p_text} * }")
        ###exit 0
    end
    #
    #Exit a script
    def exit(p_prog='*',p_text='Byebye')
    #+++++++
        logData("Common_2"+":: "+p_prog+": Forced exit")
        puts "Forced exit of #{p_prog} with status: #{p_text}"
    end

    #check CDC & acts
    def chkvalues(p_act='None',p_acts=[])
    #++++++++++++
        if (ind = p_acts.index(p_act))
            return true
        else
            return false
        end
        return false
    end

    #start program
    def execProg(p_prog='None')
    #+++++++++++
        #INP::  Prog:   fullpath with args (ruby fullpath/prog.rb args)
        #OUT::
        #
        if p_prog != 'None'
            _time   = Time.new.inspect
            _dbgmsg = "PROG>#{_time}>>"
            puts "#{_dbgmsg}ExecProg>>Module <#{p_prog}> in progress..."
            rc  = system("#{p_prog}")
            if rc != 0
                _time   = Time.new.inspect
                _dbgmsg = "PROG>#{_time}>>"
                puts "#{_dbgmsg}ExecProg>>Module <#{p_prog}> Status: #{rc}"
            end
            puts "#{_dbgmsg}ExecProg>>Module <#{p_prog}> done"
            logData("Common_2"+":: "+p_prog+": Executing")
        else
            _time   = Time.new.inspect
            _dbgmsg = "PROG>#{_time}>>"
            puts "#{_dbgmsg}ExecProg>>Module <#{p_prog}> invalid"
            logData("Common_2"+":: "+p_prog+": execProg error")
        end
    end

    #debug print
    def debug(p_pa,p_pb='*',p_pc='*',p_pd='*',p_pe='*',p_flag='N')
    #++++++++
        if @dbgflag or p_flag == 'Y'
            _time   = Time.new.inspect
            _dbgmsg = ">>>Debug>#{_time}>>"
            print   "\n"
            print _dbgmsg
            print ">#{p_pa}"
            if @pb != '*'
                print " \ #{p_pb}"
                if @pc != '*'
                    print " \ #{p_pc}"
                    if @pd != '*'
                        print " \ #{p_pd}"
                        if @pe != '*'
                            print " \ #{p_pe}"
                        end
                    end
                end
            end
            print "\n"
        end
    end

    #repyn
    def repyn(p_txt='Coucou',p_rep='N')
    #   +++++
        #INP::  text to display
        #       reply values
        #OUT::  response
        #PRMS:: yY  nN  aA  qQ
        arryn   = p_rep                     #spec
        arryn   = "ANQY"    if p_rep == 'N' #default
        while true
            print "#{p_txt}(#{arryn} ? ) "
            repyn   = $stdin.gets.chomp     #get input
            repyn   = repyn.upcase
            puts    "#{arryn} - #{repyn}"
            break   if arryn.include?(repyn)
        end
        return  repyn
    end #<def>

    #wait
    def wait(p_timeout=60,p_reply=false)
    #   +++++
        #INP::  time to wait
        #       accept reply or not
        #OUT::  reply Go, n, q [def: Go]
        answer  = 'Go'
        if p_reply  #<IF1>
            begin
                answer  = 'x'
                status = Timeout::timeout(p_timeout) { answer = $stdin.gets.chomp.downcase until answer == 'q' or answer == 'n' }
            rescue Timeout::Error
                answer  = 'Go'
            end
        else    #<IF1>
            sleep   p_timeout
        end #<IF1>
        return  answer
    end #<def>

    #Continue
    def continue()
    #+++++++++++
        #OUT:   true or false
        print "Press Y to continue (Y/N): "
        repnext = $stdin.gets.chomp.upcase
        if repnext != 'Y'
            puts "Exiting without processing."
            return false
        end
        return true
    end #<def>

    def sendEmails(p_arrto=[],p_data={})
    #+++++++++++++
        #INP:   arrto => array of emails
        #       data => hash of data : Object=>?,Header=>?,Body=>?,
        #                               Trailer=>?,Sign=>?
        arrto   = []
        arrto   = p_arrto
        arrto.each do |recip|   #<L1>
            #To
            recip   = "eneo@heintje.net"    #for tests only
            logData("Common_2"+":: Email sent to: "+recip)
            #Msg
            message = "From: GHE <software@heintje.net>\nTo: #{recip}\nMIME-Version: 1.0\nContent-type: text/html\nSubject: p_data['Object']\n\n"
            message = message + "<h3>SUJET::#{p_data['Object']}</h3>"
            message = message + "<h4>ENTETE::</h4>#{p_data['Header']}<br>"
            message = message + "<h4>MESSAGE::</h4>#{p_data['Body']}<br>"
            message = message + "<h4>FIN::</h4>#{p_data['Trailer']}<br><br>"
            message = message + "***Signature***: #{p_data['Sign']}"

            #send email
                Net::SMTP.start('smtp.fastmail.com','587','fastmail.com','gheintje@xsmail.com','4n3t7e6n9e2c5a6z','PLAIN') do |smtp|    #server, port, domain, account, password, authtype
                    smtp.send_message message, "eneo@heintje.net","#{recip}"
                end #<NET>        end #<IF3>
        end #<L1>
    end #<def>

    def htmlEmails(p_from="software@heintje.net", p_to="support@heintje.net", p_hdr="", p_body="", p_tlr="",p_file="")
    #+++++++++++++
        #INP:   from:   sender (1)
        #       to:     receiver (x)
        #       hdr:    header
        #       body:   body
        #       tlr:    trailer
        #       file:   complete filepath (1)
        #OUT:   mail
        #FLOW:
        # Configuration SMTP  
        Mail.defaults do  
            delivery_method :smtp, {
                address: "smtp.votre-fournisseur.com", # Remplace par ton SMTP  
                port: 587, # ou 465 pour SSL  
                user_name: "gheintje@xsmail.com", # Ton email  
                password: "4n3t7e6n9e2c5a6z", # Ton mot de passe  
                authentication: 'PLAIN', # ou 'login'
                enable_starttls_auto: true  
            }
        end
        # Création du message  
        mail = Mail.new do  
            from    p_from
            to      p_to
            subject p_obj

            # Partie HTML  
            html_part do  
                content_type 'text/html; charset=UTF-8'
                body            p_hdr + p_body + p_tlr
            end
            # Ajout d'une pièce jointe  
            add_file p_file # Remplace par le chemin de ton fichier  
        end
        # Envoi  
        mail.deliver!
    end #<def>

    def setReminder(p_date='',p_name='',p_body='')
    +++++++++++++++
        #INP:   date (weekday day month(char) year hour:min:00)
        #       name : name of reminder
        #       body : text of reminder
        #OUT:   true or false
    #    return  false   if p_date.nil? or p_date.size==0
    #    return  false   if p_name.nil? or p_name.size==0
    #    return  false   if p_body.nil? or p_body.size==0

        system("osascript CreateReminder.scpt #{p_date} #{p_name} #{p_body}")
        logData("Common_2"+":: Reminder created with args: #{p_date}, #{p_name} , #{p_body}")
        return  true
    end #<def>

    def setDate(p_date='',p_frm=0,p_nil='')
    #++++++++++
        #INP:   date to convert
        #       format : 0=>none, 1=>reverse, 2=>YYYY/MM/DDTHH:mm to 'weekday day month year HH:00:00'
        #                3=>from Notion=>YYYY/MM/DD, 4=>from Notion=>DD/MM/YYYY
        #OUT:   date formatted
        result  = p_nil
        return  result  if p_date.nil? or p_date.size==0 or p_date == 'None'
        case    p_frm   #<SW1>
        when    0
            return  p_date
        when    1
            result  = p_date[8,2]+"/"+p_date[5,2]+"/"+p_date[0,4]
        when    2
        when    3 
            date    = p_date['start']
        when    4
            date    = p_date['start']
            return  result  if date.nil?
            result  = date[8,2]+"/"+date[5,2]+"/"+date[0,4]
        end #<SW1>
        return  result
    end #<def>
#
    def logData(p_data='***')
#   ++++++++++++
        #INP:   nothing
        #OUT:   log record
        #
        if @log_handle.nil? #<IF1>
            @log_handle = Logger.new("/users/Gilbert/Public/Logs/#{@program}.log",'daily')
            @log_handle.formatter = proc do |severity, datetime, progname, msg|
                "#{datetime}: #{severity} -> #{msg}\n"
            end

            case    @dbglevel   #<SW2>
            when   'DEBUG'
                @log_handle.level = Logger::DEBUG
            when    'INFO'
                @log_handle.level = Logger::INFO
            when    'WARM'
                @log_handle.level = Logger::WARM
            when    'ERROR'
                @log_handle.level = Logger::ERROR
            when    'FATAL'
                @log_handle.level = Logger::FATAL
            when    'UNKNOWN'
                @log_handle.level = Logger::UNKNOWN
            end #<SW2>
        end#<IF1>
        @log_handle.debug(p_data)
    end #<def>

    #
    def envGetParams(p_appli='None')
    #+++++++++++++++
        #INP:   appli:  application key
        #OUT:   parameters
        #
        if appli_flag == false                          #read json file
            file_content    = File.read(@json_file)     #read content
            @json_data      = JSON.parse(file_content)  #save as json format
        end
        #
        return  @json_data['p_appli']
    end #<def>envGetParams
    #
    def envUpdParams(p_appli='None',p_prms={})
    #+++++++++++++++
        #INP:   appli:  application key
        #       prms:   new parameters
        #OUT:   file json updated
        #
        @json_data['p_appli']   = p_prms                #update values
        File.open(@json_file, 'w') do |f|
            f.write(JSON.pretty_generate(@json_data))   #write file
        end    
    end #<def>envUpdParams
    #
end #<Class>
#<>
