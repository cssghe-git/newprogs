#
=begin
*   Class:      ClNotion_2F
*   ++++++++++++++++++++++
*   Goal:       API to Notion.so
*   Build:         <>
*
*   Functions:
#               initialize:     create new instance
*               loadParams:     define some variables
#               initNotion:     create new cycle to Notion
#               runDB:          exec block with yield
#               getBlock:       get 1 or more pages within 1 block with filter & sort
#               getPage:        get 1 page with ID
#               addPage:        add new page
#               updPage:        update 1 page with ID
#               getBlocks:      get all blocks within an ID
#
#               UploadFile:     upload file to Notion page property
#
#               loadProperties: load all or requested properties
#               allProperties:  extract properties field
#               extrProperty:   extract 1 property#
#               extrBlock:      extract 1 block
#
#               runDB:          read block of pages & yield bloc
#               runPages:       read pages & yield each page
#               runProperties:  read pages-properties & yield bloc
#   Updates:
#               020201=>  250527-1634
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
require '/users/Gilbert/Public/Progs/Prod/Common/ClCommon_2.rb'
require '/users/Gilbert/Public/Progs/Prod/Common/mdCommon_Dbs.rb'
#
class   ClNotion_2F<Common_2
#       ***********
    #def accessors
    #=============
    #
    #Class variables
    #===============
    @@classname = 'ClNotion_2F'
    @@instcount = 0

    #
    #Instance variables
    #==================
    @_debug     = false
    
    @not_inst   = ''
    @not_size   = 1000 * 1000 

    @db_infos   = {}
    @db_integr  = ''
    @db_id      = ''
    @db_fields  = []

    @req_hash       = {}
    @req_response   = ''
    @req_code       = ''
    @req_body       = ''
    @req_object     = ''
    @req_results    = ''
    @req_nxtcursor  = ''
    @req_hasmore    = false
    @req_id         = ''
    @req_properties = {}
    @req_data       = []
    @req_fields     = {}
    @req_filter     = ''
    @req_sort       = ''
    @req_upload     = ''
    @req_filename   = ''
    @req_status     = ''

    @pag_id         = ''
    @pag_properties = {}
    @pag_created    = ''
    @pag_updated = ''

    @get_hash       = {}
    @get_id         = ''
    @get_response   = ''
    @get_code       = ''
    @get_body       = ''
    @get_object     = ''
    @get_results    = ''
    @get_hasmore    = false
    @get_nxtcursor  = ''

    @blk_properties = ''
    @blk_children   = false
    @blk_result     = {}
    @blk_data       = []
    @blk_count      = 0

    @sch_hash       = {}
    @sch_id         = ''
    @sch_response   = ''
    @sch_code       = ''
    @sch_body       = ''
    @sch_object     = ''
    @sch_results    = ''
    @sch_properties = ''
    @sch_hasmore    = false
    @sch_nxtcursor  = ''
    @sch_flag       = false

#
#Constructor
#===========
    def initialize(p_env='Private')
    #+++++++++++++
        @@instcount += 1
        case    p_env
        when    'Private'
        when    'Eneo'
        when    'Mbr24'
        when    'Cyber'
        end
    end #<def>
    #
#
#Instance
#========
    # Missing
    #========
    def method_missing(name, *args)
    #+++++++++++++++++
        puts    "DBG>>>ClNotion_2F>>Method>#{name} is missing with args>#{args.inspect}"
        exit 999
        dbgprint("ClNotion_2F::method missing called with NAME:#{name} ARGS:#{args.inspect}")
    end #<def>
    #
    # Load parameters
    #================
    def loadParams(p_dbg=false,p_inst='')
    #+++++++++++++
    # load some parameters within instance
        #INP::  debug Y or N
        #       instance handle
        #OUT:   true
        #
        @_debug     = p_dbg                             #save debug
        dbgPrint("ClNotion_2F::loadParams-started with DEBUG: #{p_dbg}")
        @not_inst   = p_inst                            #save instance handle
        dbgPrint("ClNotion_2F::loadParams-done")
        return  true
    end #<def>
    #
    # Init Notion cycle
    #==================
    def initNotion(p_db='')
    #+++++++++++++
    # init for a new cycle
        #INP::  db key
        #OUT:   true
        #
        dbgPrint("ClNotion_2F::initNotion-started for #{p_db}")
        @db_infos   = Common_Dbs.loadInfos(p_db)        #load db infos
        @db_integr  = @db_infos['dbsecret']             #extract secret
        @db_id      = @db_infos['dbid']                 #extract DB id

        @req_hasmore    = true                          #init hasmore
        @req_nxtcursor  = ''                            #init cursor
        dbgPrint("ClNotion_2F::initNotion-done")
        return  true
    end #<def>
    #
    #
    # Process DB
    #===========
    # Execute block code with yield instruction

    def runDb(p_filter={},p_sort=[],p_prop=[])
    #++++++++
    # process a DB after filter & sort, exec bloc of code
        #INP::  Filter
        #       Sort
        #       properties to process => [p,p,...]
        #OUT::  full block
        #
        dbgPrint("ClNotion_2F::runDb-started") 
        @req_filter     = p_filter                      #save filter
        @req_sort       = p_sort                        #save sort
        @req_properties = p_prop                        #save properties requested

        # Loop all records
        # ****************
        while   @req_hasmore    #<L1>
            # get pages
            response        = getBlock(p_filter,p_sort) #=>{code=>,data=>,hasmore=>}
            code            = response['code']          #extract code
            @req_hasmore    = response['hasmore']       #extract hasmore
            @req_data       = response['data']          #extract data
            # check if more pages
            if code == '200'    #<IF2>
                data    = response['data']              #extract data (all pages)

                # loop all pages from this block
                data.each do |page| #<L3>               #process each page
                    yield(page) if block_given?         #exec block for full page
                end #<L3>
            else    #<IF2>
                yield(response) if block_given?         #exec response
            end #<IF2>
        end #<L1>
        dbgPrint("ClNotion_2F::runDb-done")
    end #<def>

    def runPages(p_filter={},p_sort=[],p_prop=[])
    #+++++++++++
    # process a DB after filter & sort, exec bloc of code
        #INP::  Filter
        #       Sort
        #       properties to process => [p,p,...]
        #OUT::  full page

        #
        dbgPrint("ClNotion_2F::runPages-started")
        @req_filter     = p_filter                      #save filter
        @req_sort       = p_sort                        #save sort
        @req_properties = p_prop                        #save properties requested

        # Loop all records
        # ****************
        while   @req_hasmore    #<L1>
            # get pages
            response        = getBlock(p_filter,p_sort) #=>{code=>,data=>,hasmore=>}
            #   pp response
            code            = response['code']          #extract code
            @req_hasmore    = response['hasmore']       #extract hasmore
            @req_data       = response['data']          #extract data
            # check if more pages
            if code == '200'    #<IF2>
                infos   = response['data']              #extract data (all pages)
                if infos.nil? or infos.size == 0        #no data
                    yield(false,response) if block_given?     #exec response
                else
                    # loop all pages from this block
                    infos.each do |page| #<L3>          #process each page
                        yield(true,page) if block_given?    #exec block for full page
                    end #<L3>
                end
            else    #<IF2>
                yield(false,response) if block_given?   #exec response
            end #<IF2>
        end #<L1>
        dbgPrint("ClNotion_2F::runPages-done")
    end #<def>

    def runProperties(p_filter={},p_sort=[],p_prop=[])
    #++++++++++++++++
    # process a DB after filter & sort, exec bloc of code
        #INP::  Filter
        #       Sort
        #       properties to process => [p,p,...]
        #OUT::  all properties if request is ALL
        #       some properties following request
        #
        dbgPrint("ClNotion_2F::runProperties-started")
        @req_filter     = p_filter                      #save filter
        @req_sort       = p_sort                        #save sort
        @req_properties = p_prop                        #save properties requested

        # Loop all records
        # ****************
        while   @req_hasmore    #<L1>
            # get pages
            response        = getBlock(p_filter,p_sort) #=>{code=>,data=>,hasmore=>}
            code            = response['code']          #extract code
            @req_hasmore    = response['hasmore']       #extract hasmore
            @req_data       = response['data']          #extract data
            # check if more pages
            if code == '200'    #<IF2>
                data    = response['data']              #extract data (all pages)
                # loop all pages from this block
                data.each do |page| #<L3>               #process each page
                    @pag_id = page['id']                #save page ID
                    fields  = loadProperties(page,@req_properties)  #extract properties
                    fields['pageid']    = @pag_id   #save page ID within return
                    if @req_properties[0] == 'ALL'  #<IF5>  #All properties
                        yield(fields)   if block_given? #exec block for all properties
                    else    #<IF5>                      #some properties
                        @req_fields = {}                #init
                        @req_properties.each do |field| #<L6>   #process each property
                            @req_fields[field]  = fields[field] #add
                        end
                        yield(@req_fields)  if block_given? #exec block for properties requested
                    end #<IF5>
                end #<L3>
            else    #<IF2>
                yield(response) if block_given?         #exec response
            end #<IF2>
        end #<L1>
        dbgPrint("ClNotion_2F::runProperties-done")
    end #<def>
    #
    # Get DB fields
    #==============
    def getDbFields(p_dbid=@db_id)
        #INP::  db ID
        #OUT::  {code=>,fields=>[]}
        dbgPrint("ClNotion_2F::getDbFields-started for DB: #{p_dbid}")
        uri = URI.parse("https://api.notion.com/v1/databases/#{p_dbid}")
        request = Net::HTTP::Get.new(uri)
        #set http
        request.content_type        = "application/json"
        request["Authorization"]    = "Bearer #{@db_integr}"
        request["Notion-Version"]   = "2022-06-28"
        req_options                 = {use_ssl: uri.scheme == "https",}
        #send request
        @req_response   = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            http.request(request)
        end
        #
        #result
        @req_code   = @req_response.code
        @req_body   = @req_response.body
        dbgPrint("ClNotion_2F::getDbFields-response=> CODE:#{@req_code} BODY:#{@req_body}")
        @db_fields  = []
        #checks
        if @req_code == '200'   #<IF1>
            @req_hash       = JSON.parse(@req_body)
            @req_object     = @req_hash['object']
            @req_id         = @req_hash['id']
            @req_properties = @req_hash['properties']
            #make fields array
            @req_properties.each do |property|  #<L2>
                name    = property[0]
                @db_fields.push(name)
            end #<L2>
        else    #<IF1>
            @req_code   = 101
        end #<IF#>
        dbgPrint("ClNotion_2F::getDbFields-done")
        return  {'code'=>@req_code,'data'=>@db_fields}
    end #<def>
    #
    #Get pages within a block
    #========================
    def getBlock(p_filter={},p_sort=[])
        #INP::  filter => {}
        #       sort => {}
        #OUT::  {code=>,data=>}
        #make body
        dbgPrint("ClNotion_2F::getBlock-started")
        #check if next data
        if @req_hasmore == 'false'  #<IF1>
            return  {'code'=>'1','data'=>'None'}
        end #<IF1>
        #
        body    = {}
        if p_filter.length > 0  #<IF1>
            body['filter']  = p_filter
        end #<IF1>
        if p_sort.length > 0    #<IF1>
            body['sorts']   = p_sort
        end #<IF1>
        #
        if @req_hasmore == true and @req_nxtcursor.size > 0 #<IF1>
            body['start_cursor']    = @req_nxtcursor
        end #<IF1>
        #
        body['page_size']   = 20

        #API
        rc  = execApiPost('DB',body)
        dbgPrint("ClNotion_2F::getBlock-done with RC: #{@req_code}")
        return  {'code'=>@req_code,'data'=>@req_results,'hasmore'=>@req_hasmore}
    end #<def>
    #
    #Get page
    #========
    def getPage(p_pgid='')
        #INP::  pageid
        #OUT::  {code=>,data=>,id=>}
        dbgPrint("ClNotion_2F::getPage-started for ID:#{p_pgid}")
        #API
        @pag_id = p_pgid
        #exec
        rc  = execApiPost('PGR')
        if @req_code == '200'   #<IF1>
            result  = {'code'=>@req_code,'data'=>@req_body,'id'=>@req_id}
        else    #<IF1>
            result  = {'code'=>@req_code,'data'=>@req_body,'id'=>''}
        end #<IF1>
        dbgPrint("ClNotion_2F::getPage-done with RC: #{@req_code}")
        return  result
    end #def>
    #
    #Add page
    #========
    def addPage(p_dbid='',p_body={})
        #INP::  DB ID
        #       body
        #OUT::  {code=>,data=>,id=>}
        dbgPrint("ClNotion_2F::addPage-started with KEY: #{@db_integr}")
        #set values
        body    = {}
        body['parent']      = {'database_id'=> @db_id}
        body['properties']  = p_body
        dbgPrint("ClNotion_2F::addPage-set BODY: #{body}")  if @_debug
        #API
        rc  = execApiPost('PGA',body)
        if @req_code == '200'   #<IF1>
            result  = {'code'=>@req_code,'data'=>@req_body,'id'=>@req_id}
        else    #<IF1>
            result  = {'code'=>@req_code,'data'=>@req_body,'id'=>''}
        end #<IF1>
        dbgPrint("ClNotion_2F::addPage-done with RC: #{@req_code}")
        return  result
    end #<def>
    #
    #Update page
    #===========
    def updPage(p_pgid='',p_body={})
        #INP::  page ID
        #       body
        #OUT::  {code=>,data=>}
        dbgPrint("ClNotion_2F::updPage-started")
        #set values
        @pag_id = p_pgid
        dbgPrint("ClNotion_2F::updPage-set ID: #{@pag_id}")
        body    = {}
        body['properties']  = p_body
        dbgPrint("ClNotion_2F::updPage-set BODY: #{body}")
        #API
        rc  = execApiPatch('PGU',body)
        if @req_code == '200'   #<IF1>
            result  = {'code'=>@req_code,'data'=>@req_body}
        else    #<IF1>
            result  = {'code'=>@req_code,'data'=>@req_body}
        end #<IF1>
        dbgPrint("ClNotion_2F::updPage-done with RC: #{@req_code}")
        return  result
    end #<def>
    #
    #Get blocks
    #==========
    def getBlocks(p_id='')
        #INP::  page ID
        #OUT::  {code=>,count=>,data=>[[value],...]}
        dbgPrint("ClNotion_2F::getBlocks-started")
        @blk_result     = {}
        @blk_data       = []
        @blk_count      = 0
        @get_id         = p_id
        @get_hasmore    = true
        while   @get_hasmore    #<L1>
            #API
            rc  = execApiGetInf(@get_id)
            @blk_result['code']     = @get_code
            @blk_result['count']    = @blk_count
            if @get_code == '200'   #<IF2>
                @get_results.each do |block|    #<L3>
                    @get_object     = block['object']
                    @get_id         = block['id']
                    @blk_children   = block['has_children']
                    @blk_data.push(extrBlock(block))
                    @blk_count      += 1
                end #<L3>
            else    #<IF2>
            end #<IF2>
            @blk_result['count']    = @blk_count
            @blk_result['data']     = @blk_data
            dbgPrint("ClNotion_2F::getBlocks-done")
            return  {'code'=>@get_code,'data'=>@blk_data}
        end #<L1>
    end #<def>
    #
    #Search ID
    #=========
    def schTitle(p_req='',p_sch='None')
        #INP::  req: 'database' or 'page' constants
        #OUT::  {code=>,ID=>}
        dbgPrint("ClNotion_2F::schTitle-started for #{p_req}")
        body    = {}
        p_req   = p_req.downcase
        filter  = {
            'value'=> p_req,
            'property'=> 'object'
        }
        body['query']   = p_sch
        body['filter']  = filter
        rc  = execApiSchTitle(body)
        if @sch_code == '200'   #<IF1>
        #    pp @sch_results
            @sch_results.each do |page|     #<L2>
                object  = page['object']
                if object == 'page'     #<IF3>
                    @sch_id         = page['id']
                    @sch_properties = page['properties']
                    @sch_properties.each do |property|      #<L4>
                        name    = property[0]
                        if name == 'title'  #<IF5>
                            string  = property[1]
                            type    = string['type']
                            if type == 'title'   #<IF6>
                                string  = string[type]
                                string  = string[0]
                                type    = string['type']
                                string  = string[type]
                                if type == 'text'  #<IF7>
                                    content = string['content']
                                    puts    "TITLE:#{content}"
                                    if content == p_sch #<IF8>
                                        @sch_flag   = true
                                        break
                                    end #<IF8>
                                end #<IF7>
                            end #<IF6>
                        end #<IF5>
                    end #<L4>
                elsif object == 'database'  #<IF3>
                    @sch_id = page['id']
                    string  = page['title']
                    string  = string[0]
                    type    = string['type']
                    string  = string[type]
                    if type == 'text'  #<IF7>
                        content = string['content']
                        puts    "TITLE:#{content}"
                    #    @sch_properties.push(content)   if content.size > 0
                    end #<IF7>
                end #<IF3>
                break   if @sch_flag
            end #<L2>
        end #<IF1>
        dbgPrint("ClNotion_2F::schTitle-done")
        return  {'code'=>@sch_code,'ID'=>@sch_id,'result'=>@sch_properties}
    end #<def>
    #
    #Load properties
    #===============
    def loadProperties(p_page={},p_keys=[])
        #INP::  [key or ALL,key,...]
        #OUT::  {key=>value,...}
        #get all properties
        rc  = allProperties(p_page)
        result  = {}
        if p_keys[0] == 'ALL'   #<IF1>
            @pag_properties.each do |property|  #<L2>
                key = property[0]
                result[key] = extrProperty('None',property)
            end #<L2>
        else    #<IF1>
            p_keys.each do |name|   #<L2>
                dbgPrint("Extract #{name}")
                key = name
                result[key] = extrProperty(name,'None')
            end #<L2>
        end #<IF1>
        return  result
    end #<def>
    #
    #Extract properties
    #==================
    def allProperties(p_page={})
        #OUT:   {property,...}
        @pag_properties = p_page['properties']
        return  @pag_properties
    end
    #
    #Extract one property
    #====================
    def extrProperty(p_name='None',p_propitems='None')
        #INP: [Name,Property]
        #OUT: field content
        content = 'None'
        if p_name == 'None' #<IF1>
            dbgPrint("Extract:: NAME: #{p_name} PROP:#{p_propitems}")   if @_debug
            name    = p_propitems[0]
            data    = p_propitems[1]
            p_type  = data['type']
            string  = data[p_type]
        else    #<IF1>
            dbgPrint("Extract:: NAME: #{p_name} PROP:#{@pag_properties[p_name]}")   if @_debug
            name    = p_name
            data    = @pag_properties[name]
            p_type  = data['type']
            return content      if p_type.nil? or p_type.size == 0
            string  = data[p_type]
        end #<IF1>
        case p_type #<SW1>
        when 'checkbox'                         #"checkbox"=>true or false
            content = string

        when 'created_time'                     #"created_time"=>"2023-09-12T10:23:00.000Z"
            return content      if string.nil? or string.size == 0
            tstart  = string['start']
            tend    = string['end']
            tzone   = string['time_zone']
            content = {'start'=>tstart,'end'=>tend,'zone'=>tzone}

        when 'date'                             #"date"=>{"start"=>"2023-09-14T13:57:00.000+00:00", "end"=>nil, "time_zone"=>nil}
            return content      if string.nil? or string.size == 0
            tstart  = string['start']
            tend    = string['end']
            tzone   = string['time_zone']
            content = {'start'=>tstart,'end'=>tend,'zone'=>tzone}

        when 'email'                            #"email"=>xyz
            return content      if string.nil? or string.size == 0
            content = string

        when 'files'                            #"files"=>[{"name"=>xyz,"external"=>{"url"=>xyz}}]
            return content      if string.nil? or string.size == 0
            names   = []
            string.each do |file|   #<L2>
                vname   = file['name']
                vextr   = file['file']
                vurl    = vextr['url']
                value   = [vname,vurl]
                names.push(value)
            end #<L2>
            content = names                     #[[f1],[f2],...]
            
        when 'formula'                          #"formula"=>{"type"=>"boolean", "boolean"=>false}
                                                #"formula"=>{"type"=>"string", "string"=>"EneoBW"}
            return content      if string.nil? or string.size == 0
            type    = string['type']
            content = string[type]

        when 'last_edited_by'                   #"last_edited_by"=>{"object"=>"user", "id"=>"265acec2-56f6-433f-bab3-e63cc2f6fd57"}

        when 'last_edited_time'                 #"last_edited_time"=>"2023-09-23T17:16:00.000Z"}
            return content      if string.nil? or string.size == 0
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
            return content      if string.nil? or string.size == 0
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
            return content      if string.nil? or string.size == 0
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
            return content      if string.nil? or string.size == 0
            title   = string[0]                 #[type,'type']
            type    = title['type']             #[type,'type']
            text    = title[type]               #[arg,arg...]
            content = text['content']

        when 'unique_id'                        #"unique_id"=>{"prefix"=>"EXC-INF", "number"=>1}
            prefix  = string['prefix']
            number  = string['number']

        when 'URL'                              #"url"=>xyz
            return content      if string.nil? or string.size == 0
            content = string

        else    #<SW1>
            content = '*'
        end #<SW1>
        return content
    end #<def>
    #
    #Extract one block
    #=================
    def extrBlock(p_block='')
        #INP::  block
        #OUT::  value
        value   = []
        type    = p_block['type']
        field   = p_block[type]
        case    type    #<SW1>
        when    'bookmark'
            #=>[content,...]
        when    'chil_database'
            #=>
        when    'breadcrump'
            #=>{}
        when    'bulleted_list_item'
            #=>[content,...]
        when    'callout'
            #=>[content,...]
        when    'child_page'
            #=>content
        when    'code'
            #=>content
        when    'embed'
            #=>url
        when    'equation'
            #=>content
        when    'file'
            #=>[url,name]
        when    'heading_1','heading_2','heading_3'
            #=>content
            string  = field['rich_text']
            string  = string[0]
            type    = string['type']
            string  = string[type]
            value   = string['content']
            puts    "extrBlock:: STRING:#{string} VALUE:#{value}"   if @_debug
        when    'image'
            #=>url
        when    'numbered_list_item'
            #=>[content,...]
        when    'paragraph'
            #=>[content,...]
            string  = field['rich_text']
            string.each do |paragraph|  #<L2>
                type        = paragraph['type']
                string      = paragraph[type]
                value.push(string['content'])
                puts    "extrBlock:: STRING:#{string} VALUES:#{value}"  if @_debug
            end #<L2>
        when    'pdf'
            #=>url
        when    'quote'
            #=>[content,...]
        when    'synced_block'
            #=>[content,...]
        when    'table'
            #=>number
        when    'table_row'
            #=>[content,...]
        when    'to_do'
            #=>[content,...]
        end #<SW1>
        return  value
    end #<def>

#
    #
    # Upload file
    #============
    def upLoadFile(p_pagid='',p_filename='None',p_filedata='None',p_size=0)
    #++++++++++++++
        #INP:   page_id
        #       filename
        #       filedata
        #       filesize
        #OUT:   ?
        dbgPrint("ClNotion_2F::upLoadFile-started for ID:#{p_pagid} FILE:#{p_filename}")
        @pag_id         = p_pagid
        @req_filename   = p_filename
        @not_size       = 10 * 1000 * 1000              #10M

        # 1-get chunks of file
        body    = {}                                    #default : 1 chunk
        if p_size > @not_size   #<IF1>
            chunk_count   = (p_size / @not_size).ceil   #get chunk count
            body    = {
                'mode'     => 'multi_part',
                'number'   => chunk_count,
                'filename' => p_filename
            }
        else
            body    = {
                'mode'     => 'single_part',
                'number'   => 1,
                'filename' => p_filename
            }
        end #<IF1>

        # 2-get unique ID & URL
        rc  = execApiFileObject(body)   #=>req_id & req_upload
        return  rc if rc != '200'
        dbgPrint("ClNotion_2F::upLoadFile-get URL & ID done with RC: #{rc}")

        # 3-upload file
        if p_size <= @not_size  #<IF1>
            chunk_index   = 1
            File.open(p_filename, 'rb') do |file|  #<L2>
                chunk_data    = file.read(@not_size)   #read 10M
                rc  = execApiLargeFile(1,chunk_data)
                return  rc if rc != '200'
                dbgPrint("ClNotion_2F::upLoadFile-uploaded all #{chunk_index} done with RC: #{rc}")
            end #<L2>
        else    #<IF1>
            chunk_index   = 1
            File.open(p_filename, 'rb') do |file|  #<L2>
                chunk_data    = file.read(@not_size)   #read 10M
                rc  = execApiLargeFile(chunk_index,chunk_data)
                dbgPrint("ClNotion_2F::upLoadFile-uploaded part #{chunk_index} done with RC: #{rc}")
                chunk_index   += 1
                break  if chunk_index > chunk_count
            end #<L2>
        end #<IF1>
        dbgPrint("ClNotion_2F::upLoadFile-uploaded file done with RC: #{rc}")
        
        # 4-attach file to file property on created page
        body    = {
            'properties'=> {
                'FileContent'=> {
                    'type'=> 'files',
                    'files'=> [
                        {
                            'type'=> 'file_upload',
                            'file_upload'=> {
                                'id'=> @req_id
                            },
                            'name'=> p_filename
                        }
                    ]
                }
            }
        }
        rc  = execApiPatch('PGU',body)
        dbgPrint("ClNotion_2F::upLoadFile-attach on property done with rc: #{rc}")

        # 5-attach file to children block on created page
        body    = {
            'children'=> [
                {
                    'type'=> 'file',
                    'file'=> {
                        'type'=> 'file_upload',
                        'file_upload'=> {
                            'id'=> @req_id
                        }
                    }
                }
            ]
        }
        rc  = execApiPatch('PBL',body)
        dbgPrint("ClNotion_2F::upLoadFile-attach on block done with rc: #{rc}")

        dbgPrint("ClNotion_2F::upLoadFile-Done with RC: #{@req_code}")
        return  rc
    end #<def>
    #

    #
    # Upload image
    #=============
    def upLoadImage(p_pagid='',p_filename='None',p_filedata='None',p_size=0)
    #++++++++++++++
        #INP:   page_id
        #       filename
        #       filedata
        #OUT:   ?
        dbgPrint("ClNotion_2F::upLoadImage-started for ID:#{p_pagid} FILE:#{p_filename}")
        @pag_id         = p_pagid
        @req_filename   = p_filename
        @not_size       = 1000000 

        # 1-get chunks of file
        body    = {}                                    #default : 1 chunk
        if p_size > @not_size   #<IF1>
            chunk_count   = (p_size / @not_size).ceil      #get chunk count
            body    = {
                'mode'     => 'multi_part',
                'number'   => chunk_count,
                'filename' => p_filename
            }
        end #<IF1>

        # 2-get unique ID & URL
        rc  = execApiFileObject(body)   #=>req_id & req_upload
        return  rc if rc != '200'
        dbgPrint("ClNotion_2F::upLoadImage-get URL & ID done with RC: #{rc}")

        # 3-upload file
        if p_size <= @not_size  #<IF1>
            rc  = execApiLargeFile(1,p_filedata)
            return  rc if rc != '200'
        else    #<IF1>
            chunk_index   = 1
            File.open(p_filename, 'rb') do |file|  #<L2>
                chunk_data    = File.read(@not_size)   #read 10M
                rc  = execApiLargeFile(chunk_index,chunk_data)
                dbgPrint("ClNotion_2F::upLoadImage-uploaded part #{chunk_index} done with RC: #{rc}")
                chunk_index   += 1
                break  if chunk_index > chunk_count
            end #<L2>
        end #<IF1>
        dbgPrint("ClNotion_2F::upLoadImage-uploaded file done with RC: #{rc}")
        
        # 4-attach image to media property on created page

        # 5-attach image to children block on created page
        body    = {
            'children'=> [
                {
                    'type'=> 'image',
                    'image'=> {
                        'caption'=> [],
                        'type'=> 'file_upload',
                        'file_upload'=> {
                            'id'=> @req_id
                        }
                    }
                }
            ]
        }
        rc  = execApiPatch('PBL',body)
        dbgPrint("ClNotion_2F::upLoadImage-attach on block done with rc: #{rc}")

        dbgPrint("ClNotion_2F::upLoadImage-Done with RC: #{@req_code}")
        return  rc
    end #<def>
    #

#
#Private
#=======
    private
    #
    # Executes an API request with POST method
    #
    # @param p_req [String] The type of request (e.g., 'DB', 'PGR', 'PGA')
    # @param p_body [Hash, nil] The body of the request
    #
    # @return [String] The HTTP response code
    #
    def execApiPost(p_req='None',p_body='None')
        dbgPrint("ClNotion_2F::execApiPost-started with REQ:#{p_req} ID:#@db_id")

        # Set values
        dbgPrint("ClNotion_2F::execApiPost-request=> #{p_req}")
        case p_req
        when 'DB'
            dbgPrint("ClNotion_2F::execApiPost-started with ID:#@db_id")
            uri     = URI.parse("https://api.notion.com/v1/databases/#{@db_id}/query")
            request = Net::HTTP::Post.new(uri)
        when 'PGR'
            dbgPrint("ClNotion_2F::execApiPost-started with ID:#@pag_id")
            uri = URI.parse("https://api.notion.com/v1/pages/#{@pag_id}")
            request = Net::HTTP::Get.new(uri)
        when 'PGA'
            uri     = URI.parse("https://api.notion.com/v1/pages")
            request = Net::HTTP::Post.new(uri)
        else
            return '101'
        end

        # Set HTTP headers
        request.content_type        = "application/json"
        request["Authorization"]    = "Bearer #{@db_integr}"
        request["Notion-Version"]   = "2022-06-28"

        # Set body
        dbgPrint("ClNotion_2F::execApiPost-body=> #{p_body}")
        case p_body
        when 'None'
            request.body    = ''
        else
            jdump           = JSON.dump(p_body)
            request.body    = jdump
        end

        req_options         = {use_ssl: uri.scheme == "https",}

        # Send request
        @req_response   = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            dbgPrint("ClNotion_2F::execApiPost-Net=> #{http}")
            http.request(request)
        end

        # Process response
        @req_code   = @req_response.code
        @req_body   = @req_response.body
        dbgPrint("ClNotion_2F::execApiPost-response=> CODE:#{@req_code} BODY:#{@req_body}")

        # Check response
        if @req_code == '200'
            @req_hash       = JSON.parse(@req_body)
            @req_object     = @req_hash['object']
            @req_id         = @req_hash['id']
            @req_results    = @req_hash['results']
            @req_nxtcursor  = @req_hash['next_cursor']
            @req_hasmore    = @req_hash['has_more']
        end

        dbgPrint("ClNotion_2F::execApiPost-done with MORE:#{@req_hasmore} NEXT:#{@req_nxtcursor}")
        return  @req_code
    end

    #Exec API with PATCH mode
    #========================
    # Executes an API request with PATCH method.
    #
    # @param p_req [String] The type of request.
    # @param p_body [Hash] The body of the request.
    #
    # @return [String] The response code from the API request.
    #
    def execApiPatch(p_req='None',p_body='None')
        # Set values
        dbgPrint("ClNotion_2F::execApiPatch-request=> #{p_req}")
        case    p_req   # Switch case for request type
        when    'DB'
            dbgPrint("ClNotion_2F::execApiPatch-started with REQ:#{p_req} ID:#@db_id")
            uri = URI.parse("https://api.notion.com/v1/databases/#{@db_id}/query")
        when    'PGU'
            dbgPrint("ClNotion_2F::execApiPatch-started with REQ:#{p_req} ID:#@pag_id")
            uri = URI.parse("https://api.notion.com/v1/pages/#{@pag_id}")
        when    'PBL'
            dbgPrint("ClNotion_2F::execApiPatch-started with REQ:#{p_req} ID:#@pag_id")
            uri = URI.parse("https://api.notion.com/v1/blocks/#{@pag_id}/children")
        else    # Default case
            return  '101'
        end # End of switch case

        # Set HTTP
        request                     = Net::HTTP::Patch.new(uri)
        request.content_type        = "application/json"
        request["Authorization"]    = "Bearer #{@db_integr}"
        request["Notion-Version"]   = "2022-06-28"

        # Set body
        dbgPrint("ClNotion_2F::execApiPatch-set BODY=> #{p_body}")
        case    p_body  # Switch case for body
        when    'None'
            request.body    = ''
        else    # Default case
            jdump           = JSON.dump(p_body)
            request.body    = jdump
        end # End of switch case

        req_options         = {use_ssl: uri.scheme == "https",}

        # Send request
        @req_response   = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            dbgPrint("ClNotion_2F::execApiPatch-Net=> #{http}")
            http.request(request)
        end

        # Process response
        @req_code   = @req_response.code
        @req_body   = @req_response.body
        dbgPrint("ClNotion_2F::execApiPatch-response=> CODE:#{@req_code} BODY:#{@req_body}")

        # Check response code
        if @req_code == '200'   # If response code is 200
            @req_hash       = JSON.parse(@req_body)
            @req_object     = @req_hash['object']
            @req_results    = @req_hash['results']
            @req_nxtcursor  = ''
            @req_hasmore    = false
        end # End of if

        dbgPrint("ClNotion_2F::execApiPatch-done with MORE:#{@req_hasmore} NEXT:#{@req_nxtcursor}")
        return  @req_code
    end # End of method
    
    #Exec API with GET mode
    #======================
    # Executes an API request to retrieve information about a specific block in Notion.
    #
    # @param p_id [String] The ID of the block for which information is requested.
    #
    # @return [String] The HTTP response code from the API request.
    #
    # @note The response code '200' indicates a successful request.
    #
    def execApiGetInf(p_id='')
        dbgPrint("ClNotion_2F::execApiGetInf-request=> #{p_id}")

        uri = URI.parse("https://api.notion.com/v1/blocks/#{p_id}/children")

        # Set HTTP
        request                     = Net::HTTP::Get.new(uri)
        request.content_type        = "application/json"
        request["Authorization"]    = "Bearer #{@db_integr}"
        request["Notion-Version"]   = "2022-06-28"

        req_options                 = {use_ssl: uri.scheme == "https",}

        # Send request
        @get_response   = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            dbgPrint("ClNotion_2F::execApiGetInf-Net=> #{http}")
            http.request(request)
        end

        # Process response
        @get_code   = @get_response.code
        @get_body   = @get_response.body

        dbgPrint("ClNotion_2F::execApiGetInf-response=> CODE:#{@get_code} BODY:")

        # Check response code
        if @get_code == '200'
            @get_hash       = JSON.parse(@get_body)
            @get_object     = @get_hash['object']
            @get_results    = @get_hash['results']
            @get_nxtcursor  = @get_hash['next_cursor']
            @get_hasmore    = @get_hash['has_more']
        end

        dbgPrint("ClNotion_2F::execApiPatch-done with MORE:#{@get_hasmore} NEXT:#{@get_nxtcursor}")

        return  @get_code
    end # End of method
    
    # Executes an API request to search for a specific title in Notion.
    #
    # @param p_body [Hash] The body of the API request containing the search query.
    #
    # @return [String] The HTTP response code from the API request.
    #
    # @note The response code '200' indicates a successful request.
    #
    def execApiSchTitle(p_body)
        dbgPrint("ClNotion_2F::execApiSch-started")

        # Set values
        uri     = URI.parse("https://api.notion.com/v1/search")
        request = Net::HTTP::Post.new(uri)

        # Set HTTP headers
        request.content_type        = "application/json"
        request["Authorization"]    = "Bearer #{@db_integr}"
        request["Notion-Version"]   = "2022-06-28"

        # Set request body
        dbgPrint("ClNotion_2F::execApiPost-body=> #{p_body}")
        case p_body
        when 'None'
            request.body    = ''
        else
            jdump           = JSON.dump(p_body)
            request.body    = jdump
        end

        req_options         = {use_ssl: uri.scheme == "https"}

        # Send request
        @sch_response   = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            dbgPrint("ClNotion_2F::execApiSch-Net=> #{http}")
            http.request(request)
        end

        # Process response
        @sch_code   = @sch_response.code
        @sch_body   = @sch_response.body

        dbgPrint("ClNotion_2F::execApiSch-response=> CODE:#{@sch_code} BODY:")

        # Check response code
        if @sch_code == '200'
            @sch_hash       = JSON.parse(@sch_body)
            @sch_object     = @sch_hash['object']
            @sch_id         = @sch_hash['id']
            @sch_results    = @sch_hash['results']
            @sch_nxtcursor  = @sch_hash['next_cursor']
            @sch_hasmore    = @sch_hash['has_more']
        end

        dbgPrint("ClNotion_2F::execApiSch-done with MORE:#{@sch_hasmore} NEXT:#{@sch_nxtcursor}")

        return @sch_code
    end
    #
    # exec API for File object
    #=========================
    #
    # This function is used to initiate a file upload process to Notion API.
    # It sends a POST request to the file_uploads endpoint with the necessary headers and body.
    #
    # Parameters:
    # p_body (Hash): A hash containing the necessary information for the file upload request.
    #
    # Returns:
    # (String): The HTTP response code from the API request. A '200' response code indicates a successful request.
    #
    def execApiFileObject(p_body={})
        #INP:   ?
        #OUT:   ?
        dbgPrint("ClNotion_2F::execApiFileObject-started")
        #set values
            uri     = URI.parse("https://api.notion.com/v1/file_uploads")
            request = Net::HTTP::Post.new(uri)
        
        # Set http
        request.content_type        = "application/json"
        request["Authorization"]    = "Bearer #{@db_integr}"
        request["Notion-Version"]   = "2022-06-28"

        # Set body
        body    = p_body
        jdump   = JSON.dump(body)
        #request.body    = jdump
        req_options     = {use_ssl: uri.scheme == "https",}

        # Send request
        @req_response   = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            dbgPrint("ClNotion_2F::execApiFileObject-Net=> #{http}")
            http.request(request)
        end

        # Process response  (upload url, status, id)  #id is used for upload file, upload_url for file upload
        @req_code   = @req_response.code
        @req_body   = @req_response.body
        dbgPrint("ClNotion_2F::execApiFileObject-response=> CODE:#{@req_code} BODY:#{@req_body}")

        # Checks
        if @req_code == '200'
            @req_hash       = JSON.parse(@req_body)
            @req_object     = @req_hash['object']
            @req_id         = @req_hash['id']
            @req_upload     = @req_hash['upload_url']   #use in upload
            @req_status     = @req_hash['status']
        end
        dbgPrint("ClNotion_2F::execApiFileObject-done")

        return  @req_code
    end #<def>
    #
    # exec API to upload small file
    #==============================
    #
    # This method is used to upload a small file to Notion API.
    # It sends a POST request to the file_uploads endpoint with the necessary headers and body.
    #
    # Parameters:
    # p_data (String): The content of the file to be uploaded. If 'None' is provided, a default message is used.
    #
    # Returns:
    # (String): The HTTP response code from the API request. A '200' response code indicates a successful request.
    #
    def execApiSmallFile(p_data='None')
        #INP:   file contents
        #OUT:   code
        dbgPrint("ClNotion_2F::execApiSmallFile-started page ID:#@pag_id")

        # Set values
        uri     = URI.parse(@req_upload)
        request = Net::HTTP::Post.new(uri)
        boundary = "*****RubySinglepartPost******#{Time.now.to_i}"

        # Set http
        request.content_type        = "multiplepart/form-data"
        request["Authorization"]    = "Bearer #{@db_integr}"
        request["Notion-Version"]   = "2022-06-28"

        # Set body
        file_content = p_data == 'None' ? "Ceci est le contenu de votre fichier." : p_data
        body    = ""
        body << "--#{boundary}\r\n"
        body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{@req_filename}\"\r\n"
        body << "Content-Type: text/plain\r\n"
        body << "\r\n"
        body << file_content
        body << "\r\n--#{boundary}--\r\n"
        request.body    = body
        request["Content-Length"] = body.bytesize.to_s
        #
        dbgPrint("ClNotion_2F::execApiSmallFile-request=> #{request}")
        dbgPrint("ClNotion_2F::execApiSmallFile-Body=> #{body}")
        request.each do |key,value|  #<L1>
            dbgPrint("ClNotion_2F::execApiSmallFile-KEY:#{key} VALUE:#{value}")
        end #<L1>

        req_options     = {use_ssl: uri.scheme == "https",}

        # Send request
        @req_response   = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            dbgPrint("ClNotion_2F::execApiSmallFile-Net=> #{http}")
            http.request(request)
        end

        # Process response  (upload url, status, id)  #id is used for upload file, upload_url for file upload
        @req_code   = @req_response.code
        @req_body   = @req_response.body
        dbgPrint("ClNotion_2F::execApiSmallFile-response=> CODE:#{@req_code} BODY:#{@req_body}")
        #checks
        if @req_code == '200'
            @req_hash       = JSON.parse(@req_body)
            @req_object     = @req_hash['object']
            @req_id         = @req_hash['id']
            @req_status     = @req_hash['status']
        end #<IF>
        dbgPrint("ClNotion_2F::execApiSmallFile-done")

        return  @req_code
    end #<def>
    #
    # exec API to upload chunk of file
    #=================================
    #
    # This method is used to upload a chunk of a file to the Notion API.
    # It sends a POST request to the file_uploads endpoint with the necessary headers and body.
    #
    # Parameters:
    # p_index (Integer): The index of the chunk being uploaded. Default is 0.
    # p_data (String): The content of the chunk being uploaded. If 'None' is provided, a default message is used.
    #
    # Returns:
    # (String): The HTTP response code from the API request. A '200' response code indicates a successful request.
    #
    def execApiLargeFile(p_index=0,p_data='None') 
        #INP:   chunk index
        #       chunk data
        #OUT:   ?
        dbgPrint("ClNotion_2F::execApiLargeFile-started page ID:#@pag_id")

        # Set values
            uri     = URI.parse(@req_upload)
            request = Net::HTTP::Post.new(uri)
        boundary = "*****RubyMultipartPost******#{Time.now.to_i}"

        #   Set http
        request.content_type        = "multipart/form-data; boundary=#{boundary}"
        request["Authorization"]    = "Bearer #{@db_integr}"
        request["Notion-Version"]   = "2022-06-28"

        # Set body
        begin
            file_content = p_data == 'None' ? "Ceci est le contenu de votre fichier." : p_data
            body    = ""
            body << "--#{boundary}\r\n"
            body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{@req_filename}\"\r\n"
            body << "Content-Type: text/plain\r\n"
            body << "\r\n"
            body << file_content
            body << "\r\n--#{boundary}--\r\n"
            request.body    = body
            request["Content-Length"] = body.bytesize.to_s
            request['part_number'] = p_index.to_s

            dbgPrint("ClNotion_2F::execApiLargeFile-request=> #{request}")
            dbgPrint("ClNotion_2F::execApiLargeFile-Body=> #{body}")
            request.each do |key,value|  #<L1>
                dbgPrint("ClNotion_2F::execApiLargeFile-KEY:#{key} VALUE:#{value}")
            end #<L1>

            req_options     = {use_ssl: uri.scheme == "https",}

            # Send request
            @req_response   = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
                dbgPrint("ClNotion_2F::execApiLargeFile-Net=> #{http}")
                http.request(request)
            end
            
            # Result
            @req_code   = @req_response.code
            @req_body   = @req_response.body
            dbgPrint("ClNotion_2F::execApiLargeFile-response=> CODE:#{@req_code} BODY:#{@req_body}")

            # Checks
            if @req_code == '200'
                @req_hash       = JSON.parse(@req_body)
                @req_object     = @req_hash['object']
                @req_id         = @req_hash['id']
                @req_status     = @req_hash['status']
            end #<IF>
            dbgPrint("ClNotion_2F::execApiLargeFile-done")
            return  @req_code

        rescue StandardError => e
            dbgPrint("ClNotion_2F::execApiLargeFile-ERROR: #{e.message}")
            dbgPrint("ClNotion_2F::execApiLargeFile-ERROR: #{e.backtrace.join("\n")}")
            @req_code   = '500'
            @req_body   = e.message
            dbgPrint("ClNotion_2F::execApiLargeFile-response=> CODE:#{@req_code} BODY:#{@req_body}")
        end
    end #<def>
    #
    #Debug
    #=====
    def dbgPrint(p_text='None')
        return  false   if @_debug == false
        puts    p_text
        puts    "*"
        Common_2.logData_cl("ClNotion_2F"+":: #{p_text}")
        return  true
    end #<def>
#
#
end #<end of class>
#<eoc>
