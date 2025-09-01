#
=begin
    #Function:  upload files to Notion
    #Call:      ruby PrvUpload_File.rb N
    #Parameters::
        #P1:    Debug       => true/Y=>debug / false/N=>None
        #P2:    Mode        => L for log only / E for execute
        #P3:    Function    => # / @i / @p / @a / @f
        #P4:    path of file if P3 = '@f'
    #Actions:
        #Create date: 20250530 with Build: 01.01.01
        #Updates:
            #Build: 01.02.01 <>     Logs:   add P3 & P4
            #Build: 01.02.01 <>     Logs:   add Private dirs
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
###require 'pdfkit'
#
#***** Directories management *****
# Start of block
    require_dir = Dir.pwd
    common_dir  = "/users/gilbert/public/progs/prod/common/"
require "#{common_dir}/ClDirectories.rb"
    _dir    = Directories.new(false)
    Dir.chdir(common_dir)
    exec_mode   = 'B'                                   #change B or P
    arrdirs = _dir.otherDirs(exec_mode)                 #=>{exec,private,membres,common,send,work}
    Dir.chdir(require_dir)
# End of block
#***** Directories management *****
#

#
# Input parameters
#*****************
begin
    _debug  = ARGV[0]
    @_mode  = ARGV[1]
    _funct  = ARGV[2]
    _file   = ARGV[3]
rescue
    _debug  = false
    @_mode  = 'L'
    _funct  = '*'
    _file   = ''
end
    _debug  = true if _debug == 'Y'
    _debug  = false if _debug == 'N'
    @_mode  = 'L'   if @_mode != 'E'

# Check parameters
#*****************
    if _debug
        puts "Debug mode: #{_debug}"
    end

#
#***** Exec environment *****
# Start of block
    program = 'PrvUpload_File2'
    dbglevel    = 'DEBUG'
require "#{arrdirs['common']}/ClCommon_2.rb"
    @_com    = Common_2.new(program,_debug,dbglevel)
    private_dir = arrdirs['private']
    member_dir   = arrdirs['membres']                     #members directory
    common_dir   = arrdirs['common']                     #common directory
    work_dir    = arrdirs['work']
    send_dir    = arrdirs['send']
require "#{arrdirs['common']}/ClNotion_2F.rb"
# End of block
#***** Exec environment *****
#

#
# Variables
#**********
    @reply_ok   = 'X'                                   #reply for processing
    @count       = 0                                    #counter for uploaded files
    @count_sel   = 0                                    #counter for sequence file

    not_key     = 'filesupload'                         #key for mdCommon_Dbs
    not_code =  ''                                      #api return-code
    body_add    = {}                                    #body for add page
    page_id     = ''                                    #ID of the page created in Notion
    result      = {}                                    #api result

    directory   = ''
    dir_include = [
        'txt',
        'pdf',
        'json',
        'csv',
        'rb'
    ]
#
# Internal functions
#*******************
#
# Main code
#**********
    @_com.debug(program," Start at #{Time.now} ")
    @_com.logData(" Start at #{Time.now} ")

    # Check
    #++++++
    exit    if _file.nil? or _file.size < 5

    # Initialize
    #+++++++++++
    # Notion class
    @_not    = ClNotion_2F.new('Private')               # Private DBs familly

    @_com.debug("1-Initialize Notion")
    rc  = @_not.loadParams(_debug,@_not)                #load params to Notion class
    @_com.debug("1A-loadParams => #{rc}")
    rc  = @_not.initNotion(not_key)                     #init new cycle for 1 DB
    @_com.debug("1B-initNotion for #{not_key}=> #{rc}")

    #
    # Processing
    #+++++++++++
    @_com.debug("2-Processing")

    # Get infos
    file_path   = _file
    file_name   = File.basename(file_path)      #get file name
    file_size   = File.size(file_path)          #get file size
    file_type   = File.extname(file_name).delete('.') #get file type without dot
    file_tags   = "upload,#{file_type}"         #set tags for the file
    file_data   = File.read(file_path)          #read file data

    # Get content
    if dir_include.none?{ |ex| file_path.include?(ex) }
        file_content    = file_data[0,100]
    else
        file_content    = 'Type not processed'
    end

    # Get tags
    file_tags   = "upload,#{file_type}"             #default tags
    file_tags   = file_tags.split(',').map(&:strip) #split tags by comma and remove spaces

    # Create a new page in Notion
    @_com.debug("4-Process page for: #{file_name}")
    @_com.debug("4A-Creating page for: #{file_name}")
    body_add    = {
        'Reference'     => {'title' => [{'text' => {'content' => file_name}}]},
        'FileName'      => {'rich_text' => [{'text' => {'content' => file_path}}]},
        'Tags'          => {'multi_select' => file_tags.map { |tag| {'name' => tag} }},
        'Type'          => {'select' => {'name' => file_type}},
        'FileSize'      => {'number' => file_size.to_i}
    }
    if @_mode == 'E' #<IF2>
        result      = @_not.addPage('', body_add)    #get result
        not_code    = result['code']                #extract code
        page_id     = result['id']                  #extract ID
    else    #<IF2>
        not_code = '900'
    end #<IF2>
    @_com.debug("4B-Notion add page result: #{not_code} [900 = Log only]")

    # Upload to Notion
    @_com.debug("5-Uploading: #{file_name} (#{file_size} bytes)")
    if @_mode == 'E' #<IF2>
        rc = @_not.upLoadFile(page_id, file_path, file_data, file_size)
        if rc   #<IF3>
            @_com.debug("5A-Upload successful for #{file_name}")
            @_com.logData("5A-Upload successful for #{file_name}")
            @count += 1
        else    #<IF3>
            @_com.debug("###ERR>5B-Upload failed for #{file_name}")
        end #<IF3>
    else    #<IF2>
        @_com.debug("5C-Upload skipped for #{file_name} (Log only mode)")
    end #<IF2>

    #Display counters
    #================
    @_com.debug("6-Counters::Files selected:#{@count_sel} uploaded:#{@count}")
    @_com.logData("6-Counters::Files selected:#{@count_sel} uploaded:#{@count}")
    @_com.debug(program,"Done at #{Time.now} ")
#<EOS>