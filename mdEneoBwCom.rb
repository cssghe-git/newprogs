#
=begin
    Build: 0.1.1    <231118-0741> 
=end
module EneoBwCom
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

require_dir = Dir.pwd
#    puts    "dirREQUIRE:"+require_dir
=begin
require "#{require_dir}/ClDirectories.rb"
#
    exec_mode   = 'P'                                   #change B or P
    _dir    = Directories.new('N')
    arrdirs = _dir.otherDirs(exec_mode)                 #=>{exec,private,membres,common,send,work}
require "#{arrdirs['common']}/ClCommon_2.rb"
    @_com    = Common_2.new(false)
#
    downloads_dir   = arrdirs['work']
    send_dir        = arrdirs['send']
=end
#require "#{arrdirs['membres']}/MdEneoBwCom.rb"
require "#{require_dir}/MdEneoBwCom_ALL.rb"
require "#{require_dir}/MdEneoBwCom_OFF.rb"
require "#{require_dir}/MdEneoBwCom_NIV.rb"
#
#Variables
#+++++++++
    @_debug     = 'N'   #NO(N),Steps(S),All(Y)
    ####################
    # Common
    @com_mbrid  = ''    #
    @com_modid  = ''    #
    @com_logid  = '099789954b434bc1abd6b82bb2d40d7d'    #https://www.notion.so/eneobw/099789954b434bc1abd6b82bb2d40d7d?v=b412e8d5dd2f48c69d073e963016002d&pvs=4
    ####################
    # Activities
    @act_key    = 'mbr24.activites'
    @act_load   = true
    @act_emails = {}                                    #act => value,...
    #
    @arrfields  = []
    @arrprops   = []
    @arrblocks  = []
    @arrcdc     = {
                'BLA'=>'$',
                'BLH'=>'$',
                'CSE'=>'$',
                'EXT'=>'$',
                'GNP'=>'$',
                'JOD'=>'$',
                'LAS'=>'$',
                'NIV'=>'$',
                'OTT'=>'$',
                'PER'=>'$',
                'REB'=>'$',
                'RIX'=>'$',
                'TUB'=>'$',
                'VIL'=>'$',
                'WAL'=>'$',
                'WAT'=>'$',
                'WAV'=>'$'
                }
#
#Module vars
#+++++++++++
    @_dbgmsg    = ""
    @act_max    = 19
#
#Functions
#+++++++++
#   Init some variables
    def EneoBwCom.load(p_cdc='ALL')
    #=================
    #   Inp: cdc
    #   Out: array [mbrid,modid,logid,[cdc,activités,f_fields],arrcdc]
        case p_cdc    #<SW1>
        when 'NIV'  #<SW1>
            values  = EneoBwCom_NIV.load()  #=>[cdc,activities,f_fields]
                    #*******************
        end #<SW1>
        pp values                                   if @_debug == 'Y'
        @com_cdc        = values[0]
        @com_act        = values[1]
        @com_f_fields   = values[2]
        @com_mbrid      = values[3]
        @com_modid      = values[4]
        results         = [@com_mbrid,@com_modid,@com_logid,values,@arrcdc]
    end #<def>
#
#   Get filter values
    def EneoBwCom.filters(p_filter='N',p_auto='Y')
    #====================
    #   Inp:
    #   Out: {CDC=>?,ActCDC=>,Activity=>[num,txt],EnCours,Cotisation,Cnci,Seagma}
        if p_auto != 'Y'    #<IF0>
            if p_filter == 'N'  #<IF1
                puts    "*****"
                puts    "*Choices :"
                puts    "*"
                print   "*  CDC for Activities:: (CDC) [NIV] : "
                actcdc  = $stdin.gets.chomp.upcase
                actcdc  = 'NIV'     if actcdc.size == 0
            else    #<IF1>
                actcdc  = 'ALL'
            end #<IF1>
            EneoBwCom.load(actcdc)                                          #load values for this cdc

            print   "*  Check EnCours:: (Y) or (N) [Y]: "
            repexp  = $stdin.gets.chomp
            repexp  = 'Y'   if repexp.size == 0
            repexp  = repexp.upcase

            if p_filter == 'Y'      #<IF1>
                print   "*  Is your filter ready ? "
                repflt  = $stdin.gets.chomp.upcase

                repact  = [99,'None']
                repcdc  = 'ALL'
                repcot  = 99
                repcnc  = '?'
                repsgm  = 'Y'
            else    #<IF1>
                item    = EneoBwCom.reqAct(actcdc)                          #request activity
                actnum  = item[0].to_i                                      #number
                acttxt  = item[1]                                           #text
                repact  = [actnum,acttxt]

                print   "*  CDC for Extract:: (ALL or CDC) [ALL] : "
                repcdc  = $stdin.gets.chomp.upcase
                repcdc  = 'ALL'     if repcdc.size == 0

                print   "*  Select Cotis:: (99 or 17 or 9 or 0) [99] : "
                repcot  = $stdin.gets.chomp
                repcot  = 99        if repcot.size == 0

                print   "*  Select Cnci:: (? or Y or N) [?] : "
                repcnc  = $stdin.gets.chomp
                repcnc  = '?'       if repcnc.size == 0
                repcnc  = repcnc.upcase

                print   "*  Display Seagma:: (Y or N) [Y] : "
                repsgm  = $stdin.gets.chomp
                repsgm  = 'Y'       if repsgm.size == 0
                repsgm  = repsgm.upcase
            end #<IF1>
        else
            repcdc  = 'ALL'
            actcdc  = 'NIV'
            EneoBwCom.load('NIV')                                          #load values for this cdc
            item    = EneoBwCom.reqAct('NIV')                          #request activity
            actnum  = item[0].to_i                                      #number
            acttxt  = item[1]                                           #text
            repact  = [actnum,acttxt]

            repexp  = 'Y'
            repcot  = 99
            repcnc  = '?'
            repsgm  = 'Y'
        end #<IF0>
        #
        prms    = {                                                     #make results hash
            'MbrID'=>@com_mbrid,
            "CDC"=>repcdc,
            "ActCDC"=>actcdc,
            "Activity"=>repact,
            "EnCours"=>repexp,
            "Cotisation"=>repcot,
            "Cnci"=>repcnc,
            "Seagma"=>repsgm,
            "LstCDC"=>@arrcdc
        }
        puts ">>>Filters:: #{prms}"                     if @_debug == 'Y'
        return  prms
    end #<def>
#
#   Request activity's emails
    def EneoBwCom.reqActMail(p_act='')
    #=======================
        #INP::  act : activity
        #OUT:   emails
        #load table if first time
        if act_load
        end
    end #<def>
#
#   Request activity
    def EneoBwCom.reqAct(p_cdc='COM')
    #===================request activity n° to process
    #   Inp: cdc
    #   Out: array [actnum,acttxt]

        EneoBwCom.load('NIV')   if p_cdc == 'NIV'       #load values for this cdc
        
        ind     = 0
        acts    = ''
        #
        acts    = @com_act
        len     = @com_act.length
        @com_act.each do |act|  #<L1>                   #display all activities
                puts "N°: #{ind} Act: #{act}"
                ind += 1
        end #<L1>
        #
        grp = [0,'None']
        print 'Your choice ? '
        rep = $stdin.gets.chomp.to_i
        rep = @act_max  if rep.size == 0
        grp = [rep,acts[rep]]        if rep > 0 && rep <= len
        #
        return grp
    end #<def>
#
#   Check value
    def EneoBwCom.checkValue(p_cdc='COM',p_type='None',p_val='None')
    #+++++++++++++++++++++++check value following type
        case p_type #<SW1>
        when 'Activity' #<SW1>
            val = p_val[4,99]
            if @com_act.include?(val) #<IF2>
                return true
            else    #<IF2>
            end #<IF2>

        when 'Cotisation'   #<SW1>
            val = p_val.to_i
            if val == 0 or val == 9 or val == 17  #<IF2>
                return true
            else    #<IF2>
                return false
            end #<IF2>

        when 'Certificat'   #<SW1>
            if p_val == 'Non' or p_val == '23-24' or p_val == '24-24'   #<IF2>
                return true
            else    #<IF2>
                return false
            end #<IF2>
        else    #<SW1>
        end #<SW1>
    end #<def>
#
#   Format field type date
    def EneoBwCom.makeDate(p_field,p_def='2000-01-01')
    #=====================
        return  p_def if p_field.is_a?(String) == false
        y_field = p_field.to_s
        if y_field.nil? || y_field == 'None'    #<IF1>
            return p_def
        else    #<IF1>
            if y_field.size == 10 #jj/mm/aaaa   #<IF2>
                return "#{p_field[6,4]}-#{p_field[3,2]}-#{p_field[0,2]}"
            else    #<IF2>
                return p_def
                #old algo
                if y_field.size == 9  #j/mm/aaaa or jj/m/aaaa   #<IF3>
                    if p_field[1,1] == '/'   #j/mm/aaaa #<IF4>
                        jour    = "0#{p_field[0,1]}"
                        mois    = p_field[2,2]
                        an      = p_field[5,4]
                    else    #<IF4>
                        jour    = p_field[0,2]
                        mois    = "0#{p_field[3,1]}"
                        an      = p_field[5,4]
                    end #<IF4>
                    return "#{an}-#{mois}-#{jour}"
                else    #<IF3>
                    if y_field.size == 8  #j/m/aaaa #<IF4>
                        jour    = "0#{p_field[0,1]}"
                        mois    = "0#{p_field[2,1]}"
                        an      = p_field[4,4]
                        return "#{an}-#{mois}-#{jour}"
                    else    #<IF4>
                        return p_def
                    end #<IF4>
                end #<IF3>
            end #<IF2>
        end #<IF1>
    end #<def>
#
#   format field type number
    def EneoBwCom.makeNumber(p_field=0,p_def=0)
    #=======================
        p_field = p_field.to_i
        if p_field.nil? or p_field == 0 #<IF1>
            return p_def.to_i
        else    #<IF1>
            return p_field
        end #<IF1>
    end #<def>
#
#   format field type text
    def EneoBwCom.makeEmpty(p_field)
    #======================
        p_field = p_field.to_s
        return false    if p_field.nil? or p_field.size == 0
        return true
    end
#
    def EneoBwCom.makeField(p_field='',p_def='*')
    #======================
        return  p_def   if p_field.is_a?(String) == false
        return  p_def   if p_field.nil? or p_field.size == 0
        p_field = p_field.to_s
        if p_field.size == 0    #<IF1>
            return p_def
        else    #<IF1>
            field   = p_field.to_s.strip
            len     = field.size                                                                #trim spaces L R
        end #<IF1>
    #    puts "Makefield:: Value: #{field} Len: #{len}"
        if len < 1  #<IF1
            return p_def
        else    #<IF1>
            return field
        end #<IF1>
    end #<def>
#
#   Split field into x parts
    def EneoBwCom.split(p_field,p_def='*',p_sep=' ')
    #++++++++++++++++++
        #OUT: [count,[values]]
        if p_field.is_a?(Array)
            return  [0,p_def]   if p_field.length == 0
            return  [p_field.length,p_field]
        end

        if p_field.nil? or p_field=="*"#<IF1>
            return [0,p_def]
        else    #<IF1>
            items   = p_field.split(p_sep)
            count   = items.length
            return [count,items]
        end #<IF1>
    end #<def>
#
#   extract properties
    def EneoBwCom.extrProperty(p_type='None',p_propitems='None')
    #=========================
        #INP: [Fieldname,Fieldproperty]
        #OUT: field content
        ###pp p_propitems 
        content = 'None'
        if p_type == 'None'
            name    = p_propitems[0]
            data    = p_propitems[1]
            p_type  = data['type']
            string  = data[p_type]
            return  content     if string.nil?
        else
            p_type  = p_propitems['type'] 
            string  = p_propitems[p_type]
        end
        ### puts "DBG>TYPE:#{p_type} STRING:#{string}"
        case p_type #<SW1>
        when 'checkbox'                         #"checkbox"=>true or false
            content = string

        when 'created_time'                     #"created_time"=>"2023-09-12T10:23:00.000Z"
            content = string

        when 'date'                             #"date"=>{"start"=>"2023-09-14T13:57:00.000+00:00", "end"=>nil, "time_zone"=>nil}
            tstart  = string['start']
            tend    = string['end']
            tzone   = string['time_zone']
            content = [tstart,tend,tzone]

        when 'email'                            #"email"=>xyz
            content = string

        when 'files'                            #"files"=>[{"name"=>xyz,"external"=>{"url"=>xyz}}]
            names   = []
            string.each do |file|   #<L2>
                vname   = file['name']
                vextr   = file['external']
                vurl    = vextr['url']
                value   = [vname,vurl]
                names.push(value)
            end #<L2>
            content = names                     #[[f1],[f2],...]
        when 'formula'                          #"formula"=>{"type"=>"boolean", "boolean"=>false}
                                                #"formula"=>{"type"=>"string", "string"=>"EneoBW"}
            type    = string['type']
            content = string[type]

        when 'last_edited_by'                   #"last_edited_by"=>{"object"=>"user", "id"=>"265acec2-56f6-433f-bab3-e63cc2f6fd57"}

        when 'last_edited_time'                 #"last_edited_time"=>"2023-09-23T17:16:00.000Z"}
            content = string

        when 'multi_select'                     #"multi_select"=>{"options"=>[{"name"=>"TypeScript"},{"name"=>"JavaScript"},{"name"=>"Python"}]}
            names       = []                    #erase output
            string.each do |option| #<L2>       #loop options
                value   = option['name']        #extract option
                names.push(value)
            end #<L2>
            content = names                     #[opt1,opt2,...]

        when 'number'                           #"number"=>xyz
            content = string

        when 'people'                           #

        when 'phone_number'                     #"phone_number"=>xyz
            content = string

        when 'relation'                         #"relation"=>[{"id"=>"7943da60-2cdd-44e6-bbf0-6ce000a5bf2d"}]
            if string.length > 0
                string  = string[0]
                content = string['id']
            end

        when 'rich_text'                        #"rich_text"=>[{"type"=>"text","text"=>{"content"=>"Pour tests", 
                                                    #"link"=>nil},"annotations"=>{"bold"=>false,"italic"=>false,
                                                    #"strikethrough"=>false,"underline"=>false,"code"=>false,
                                                    #"color"=>"default"},"plain_text"=>"Pour tests","href"=>nil}]
            rich_text   = string[0]
            if rich_text.nil? or rich_text.size==0  #<IF2>
            else    #<IF2>
                type        = rich_text['type']
                text        = rich_text[type]
                content     = text['content']
            end #<IF2>

        when 'select'                           #"select"=>{"name"=>xyz}
            if string.nil? or string.size == 0
                content = 'None'
            else
                content = string['name']
            end

        when 'status'                           #"status"=>{"id"=>"0071c364-9852-45df-8cc1-cc04662f7c73",
                                                    #"name"=>"Non validé","color"=>"yellow"}
            content = string['name']

        when 'title'                            #"title"=>[{"type"=>"text","text"=>{"content"=>"Ref 1", "link"=>nil},
                                                    #"annotations"=>{"bold"=>false,"italic"=>false,"strikethrough"=>false,
                                                    #"underline"=>false,"code"=>false,"color"=>"default"},
                                                    #"plain_text"=>"Ref 1","href"=>nil}]
            title   = string[0]                 #[type,'type']
            return  content     if title.nil?
            type    = title['type']             #[type,'type']
            text    = title[type]               #[arg,arg...]
            content = text['content']

        when 'unique_id'                        #"unique_id"=>{"prefix"=>"EXC-INF", "number"=>1}
            prefix  = string['prefix']
            number  = string['number']

        when 'URL'                              #"url"=>xyz
            content = string

        else    #<SW1>
        end #<SW1>
        return content
    end #<def>
#
#   Extract block
    def EneoBwCom.extrBlock(p_type='None',p_blockitems='None')
    #======================
        content = 'None'
        case p_type #<SW1>
        when 'h_1'                              #"heading_1"=>{"rich_text"=>[{"type"=>"text","text"=>{"content"=>"Titre 1", "link"=>nil},
                                                    #"annotations"=>{"bold"=>false,"italic"=>false,"strikethrough"=>false,"underline"=>false,
                                                    #"code"=>false,"color"=>"default"},"plain_text"=>"Titre 1","href"=>nil}],
                                                    #"is_toggleable"=>false,"color"=>"default"}
        when 'h_2'                              #"heading_2"=>{"rich_text"=>[{"type"=>"text","text"=>{"content"=>"Titre 2", "link"=>nil},
                                                    #"annotations"=>{"bold"=>false,"italic"=>false,"strikethrough"=>false,"underline"=>false,
                                                    #"code"=>false,"color"=>"default"},"plain_text"=>"Titre 2","href"=>nil}],
                                                    #"is_toggleable"=>false,"color"=>"default"}
        when 'h_3'                              #"heading_3"=>{"rich_text"=>[{"type"=>"text","text"=>{"content"=>"Titre 3", "link"=>nil},
                                                    #"annotations"=>{"bold"=>false,"italic"=>false,"strikethrough"=>false,"underline"=>false,
                                                    #"code"=>false,"color"=>"default"},"plain_text"=>"Titre 3","href"=>nil}],
                                                    #"is_toggleable"=>false,"color"=>"default"}
        when 'paragragraph_'                        #"paragraph"=>{"rich_text"=>[{"type"=>"text","text"=>{"content"=>"This a block text.", "link"=>nil},
                                                    #"annotations"=>{"bold"=>false,"italic"=>false,"strikethrough"=>false,"underline"=>false,
                                                    #"code"=>false,"color"=>"default"},"plain_text"=>"This a block text.","href"=>nil}],
                                                    #"color"=>"default"}
        when 'heading_1','heading_2','heading_3','paragraph'
            items   = p_blockitems[p_type]                  #[rich_text,is_toggleable,color]
            if items.nil?   #<IF2>
            else    #<IF2>
                rich_text   = items['rich_text']            #[]
                if rich_text.nil?   #<IF3>
                else    #<IF3>
                    rich_text   = rich_text[0]              #[type,'type']
                    if rich_text.nil?   #<IF4>
                    else    #<IF4>
                        type        = rich_text['type']     #[type]
                        if type == 'text'   #<IF5>
                            text    = rich_text['text']     #[text]
                            content = text['content']
                        end #<IF5>
                    end #<IF4>
                end #<IF3>
            end #<IF2>
        else    #<SW1>
        end #<SW1
        return content
    end #<def>
#
#   Make body filter with Q/R
    def EneoBwCom.body(p_prms)
    #+++++++++++++++++
    #   INP: [cdc,actCDC,act,exp,cnci,cotis]
    #   OUT: body
        prms        = p_prms
    #    pp prms
        selcdc      = prms[0]
        actcdc      = prms[1]
        selact      = prms[2]
        selEnCours  = prms[3]
        selcnci     = prms[4]
        selcotis    = prms[5]

        actnum      = selact[0]
        acttxt      = selact[1]
        actcdcx     = actcdc + '-'
        activity    = "#{actcdcx}#{acttxt}"     #activity in use or ALL for all activities

        body    = {}
        puts ">>>Filter:: CDC:#{selcdc}, ACT:#{actnum}##{acttxt}##{activity}, EXP:#{selEnCours}, CNCI:#{selcnci}, COT:#{selcotis}"
        #
        if actnum < 20 and actnum > 0   #<IF1>
            if selEnCours == 'Y'     #<IF2>
                body  = {
                    'and'=> [
                        {'property'=> 'EnCours', 'checkbox'=>{'equals'=>true}},
                        {'property'=> 'AllActs', 'formula'=> {'string'=> {'contains'=> activity}}}
                    ]
                }
            else    #<IF2>
                body  = {
                    'and'=> [
                        {'property'=> 'EnCours', 'checkbox'=>{'equals'=>false}}
                    ]
                }
            end #<IF2>
        elsif actnum == 20  #<IF1>
            if selEnCours == 'Y'     #<IF2>
                body  = {
                    'and'=> [
                        {'property'=> 'EnCours', 'checkbox'=>{'equals'=>true}}
                    ]
                }
            else    #<IF2>
                body  = {
                    'and'=> [
                        {'property'=> 'EnCours', 'checkbox'=>{'equals'=>false}}
                    ]
                }
            end #<IF2>
        else    #<IF1>
            body    = "Error"
        end #<IF1>
        #
        return body
    end #<def>
#
#   Make body filter with Q/R
    def EneoBwCom.body2(p_prms)
        #+++++++++++++++++++++
        #   INP: [cdc,actCDC,act,exp,cnci,cotis]
        #   OUT: body
        prms        = p_prms
        selEnCours   = prms[3]

        body    = {}
        puts ">>>Filter:: see Filter on DB & EXP:#{selEnCours}"

        if selEnCours == 'Y'     #<IF1>
            body  = {
                'and'=> [
                    {'property'=> 'EnCours', 'checkbox'=>{'equals'=>true}},
                    {'property'=> 'Filter_OK','checkbox'=>{'equals'=>true}}
                ]
            }
        else    #<IF1>
            body  = {
                'and'=> [
                    {'property'=> 'EnCours', 'checkbox'=>{'equals'=>false}},
                    {'property'=> 'Filter_OK','checkbox'=>{'equals'=>true}}
                ]
            }
        end #<IF1>
    #
        return body
    end #<def>
#
#   Make body filter with Q/R
def EneoBwCom.body4(p_prms)
    #+++++++++++++++++++++
    #   INP: [field to select]
    #   OUT: body
    prms        = p_prms

    body    = {}
    puts ">>>Filter:: see Filter on DB & EXP: true"
    case    prms        #<SW1>
    when    'Seagma'    #<SW1>
        body  = {
            'and'=> [
                {'property'=> 'EnCours', 'checkbox'=>{'equals'=>true}},
                {'property'=> 'exCDC','formula'=>{'string'=>{'equals'=>"NIV"}}},
                {'property'=> 'Seagma','number'=>{'is_empty'=>true}}
            ]
        }
    end #<SW1>
end #<def>
#
#   Make body filter with Q/R
def EneoBwCom.bodyAll(p_prms)
    #+++++++++++++++++++++
    #   INP: [field to select]
    #   OUT: body
    prms        = p_prms

    body    = {}
    puts ">>>Filter:: see Filter on DB & all fields"
    body  = {
        'or'=> [
            {'property'=> 'EnCours', 'checkbox'=>{'equals'=>true}},
            {'property'=> 'EnCours', 'checkbox'=>{'equals'=>false}}
        ]
    }
#
    return body
end #<def>
#
end #<end of module>