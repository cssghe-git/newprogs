#
=begin
    #Function:  upload files to Notion
    #Call:      ruby PrvUpload_File4.rb N
    #Parameters::
        #P1:    Debug       => true/Y=>debug / false/N=>None
        #P2:    Mode        => L for log only / E for execute
        #P3:    Function    => # / @i / @p / @a / @f
        #P4:    path of file if P3 = '@f'
    #Actions:
        #Create date: 20250614.1500 with Build: 01.01.01
        #Updates:
            #Build: ? <>    Logs: ?
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
require 'fileutils'
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
#    _funct  = ARGV[2]
#    _file   = ARGV[3]
rescue
    _debug  = false
    @_mode  = 'L'
    _funct  = '*'
    _file   = ''
end
    _debug  = true if _debug == 'Y'
    _debug  = false if _debug == 'N'
#    @_mode  = 'L'   if @_mode != 'E'
    _funct  = '*'
    _file   = ''

# Check parameters
#*****************
    if _debug
        puts "Debug mode: #{_debug}"
    end

#
#***** Exec environment *****
# Start of block
    program = 'PrvUpload_File4'
    dbglevel    = 'DEBUG'
require "#{arrdirs['common']}/ClCommon_2.rb"
    @_com    = Common_2.new(program,_debug,dbglevel)
    private_dir = arrdirs['private']
    member_dir   = arrdirs['membres']                   #members directory
    common_dir   = arrdirs['common']                    #common directory
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
    @typeoffiles = [
        'txt', 
        'pdf', 
        'json', 
        'csv',
        'rb'
    ] #types of files to process

    not_key     = 'filesupload'                         #key for mdCommon_Dbs
    not_code =  ''                                      #api return-code
    body_add    = {}                                    #body for add page
    page_id     = ''                                    #ID of the page created in Notion
    result      = {}                                    #api result

    directory   = ''
    dir_flag    = false
    dir_index   = 0
    dir_start   = ''
    dir_select  = ''
    dir_list    = []
    # predefined locations
    dir_pre = {
        '#gilbert.uptonotion'               => '/users/Gilbert/UpToNotion',
        '#icloud.documents'                 => '/users/Gilbert/Library/Mobile Documents/com~apple~CloudDocs/Documents',
        '#icloud.downloads'                 => '/users/Gilbert/Library/Mobile Documents/com~apple~CloudDocs/Downloads',
        '#pcloud.backups'                   => '/users/Gilbert/pCloud Drive/Backups/kDrive',
        '#pcloud.documents.informatic'      => '/users/Gilbert/pCloud Drive/Documents/Informatic',
        '#pcloud.eaglefiler_temptemp'       => '/users/Gilbert/pCloud Drive/EagleFiler_Temp',
        '#pcloud.ighe/ghe-dos_etc.rapports' => '/users/Gilbert/pCloud Drive/iGhe/Ghe-Dos_etc/Rapports',
        '#public.members.tosend'            => '/users/Gilbert/Public/MembersLists/ToSend'
    }
    arr_dir = [
        '/users/Gilbert/UpToNotion',
        '/users/Gilbert/Library/Mobile Documents/com~apple~CloudDocs/Documents',
        '/users/Gilbert/Library/Mobile Documents/com~apple~CloudDocs/Downloads',
        '/users/Gilbert/pCloud Drive/Backups/kDrive',
        '/users/Gilbert/pCloud Drive/Documents/Informatic',
        '/users/Gilbert/pCloud Drive/EagleFiler_Temp',
        '/users/Gilbert/pCloud Drive/iGhe/Ghe-Dos_etc/Rapports',
        '/users/Gilbert/Public/MembersLists/ToSend'
]
    dir_exclude = [
        'Library'
    ]
    arr_files           = []                            #all files in the directory
    arr_files_mtime     = []                            #with mtime
    arr_files_sorted    = []                            #sorted as reverse order
    arr_files_range     = []                            #range to process
#
# Internal functions
#*******************
#
# Main code
#**********
    @_com.debug(program," Start at #{Time.now} with DEBUG: #{_debug} MODE: #{@_mode}")
#    @_com.logData(" Start at #{Time.now} ")

    # List files modified
    #++++++++++++++++++++
    @_com.debug("1-Initialize Files")
    check_dir   = "/users/Gilbert/Public/MemberLists/ToSend"

    @_com.step("1A-Select directory")
    arr_dir.each_with_index do |dir,index|  #<L1>
        puts    "#{index+1}.#{dir}"
    end #<L1>
    print   "Select directory to scan by N° => "
    dir_index   = $stdin.gets.chomp.to_i
    @_com.exit("No directory selected") if dir_index == 0
    exit                                if dir_index == 0
    check_dir  = arr_dir[dir_index-1]
    @_com.step("1B-Directory selected : #{check_dir}")

    @_com.step("1C-List files")
    arr_files = Dir.glob("#{check_dir}/**/*").select{|entry| File.directory?(entry)==false}
    @_com.debug("1D-List files => #{arr_files.size} files")
    @_com.debug("1E-Get mtime")
    arr_files.each do |ff|  #<L1>
        file_name = File.basename(ff)
        file_ext = File.extname(ff).delete('.').downcase
        ###puts "ff => #{ff} => #{file_name} - #{file_ext} - #{file_ext.size}"
        next if file_name == '.' or file_name == '..'
        next if file_ext.size < 1
        next if dir_exclude.include?(file_name)
        if @typeoffiles.include?(file_ext)  #<IF2>
            arr_files_mtime.push([ff, File.mtime(ff)])
        end #<IF2>
    end #<L1>
    @_com.debug("1C-List files => #{arr_files_mtime.size} files")
    exit 7 if arr_files_mtime.size < 1
    @_com.debug("1F-Sort files")
    arr_files_sorted = arr_files_mtime.sort_by{ |ff,mtime| mtime }.reverse
    @_com.debug("1G-List files for select")
    index   = 0
    arr_files_sorted.each do |ff,mtime| #<L1>
        puts "#{index+1} => #{ff.ljust(80," ")} : #{mtime}"
        index += 1
    end #<L1>

    # Select range of files to upload
    #++++++++++++++++++++++++++++++++
    print "Select range of files to upload (1_#{index}): "
    reply   = $stdin.gets.chomp.to_s                    #get range
    exit    if reply.include?('-') == false             #error '_'
    arr_files_range = reply.split('_').map(&:to_i)      #split from to
    exit    if arr_files_range[0] < 1                   #error from
    arr_files_range[0]  -=1                             #

    # Initialize
    #+++++++++++
    # Notion class
    @_not    = ClNotion_2F.new('Private')               # Private DBs familly

    @_com.debug("1-Initialize Notion")
    rc  = @_not.loadParams(true,@_not)                  #load params to Notion class
    @_com.debug("1A-loadParams => #{rc}")
    rc  = @_not.initNotion(not_key)                     #init new cycle for 1 DB
    @_com.debug("1B-initNotion for #{not_key}=> #{rc}")

    #
    # Processing
    #+++++++++++
    @_com.debug("2-Processing")

    for index in arr_files_range[0]...arr_files_range[1]    #<L1>
        # Get infos
        file_path   = arr_files_sorted[index][0]        #get filepath

        if file_path.size > 99  #<IF2>                  #eeror : size
            @_com.step("ERR: size too high for #{file_path}")
            file_name   = File.basename(file_path)      #get file name
            file_ext    = File.extname(file_name)       #get file type without dot
            FileUtils.cp(file_path,"/users/Gilbert/UpToNotion/#{file_name}#{file_ext}")
            @_com.step("File copied to UpToNotion")
            next                                        #skip this file
        end #<IF2>

        file_dir    = File.dirname(file_path)           #get directory of the file
        file_name   = File.basename(file_path)          #get file name
        file_size   = File.size(file_path)              #get file size
        file_type   = File.extname(file_name).delete('.') #get file type without dot
        file_tags   = "upload,#{file_type}"             #set tags for the file
        file_data   = File.read(file_path)              #read file data
        file_rename = false

        # Rename rb files to avoid conflict
        if file_type == 'rb' or file_type == 'csv'  #<IF2>
            file_path2  = "#{file_path}.txt"
            File.rename(file_path, file_path2)
            @_com.step("Renamed #{arr_files_sorted[index][0]} to #{file_path2}.txt")
            file_name   = File.basename(file_path2)     #get file name
            file_size   = File.size(file_path2)         #get file size
            file_type   = File.extname(file_name).delete('.') #get file type without dot
            file_tags   = "upload,#{file_type}"         #set tags for the file
            file_data   = File.read(file_path2)         #read file data
            file_rename = true
        else    #<IF2>
            file_path2  = file_path
        end #<IF2>

        # Get content
        if @typeoffiles.none?{ |ex| file_path2.include?(ex) }   #<IF2>
            file_content    = file_data[0,100]
        else    #<IF2>
            file_content    = 'Type not processed'
        end #<IF2>

        # Get tags
        file_tags   = "upload,#{file_type}"             #default tags
        file_tags   = file_tags.split(',').map(&:strip) #split tags by comma and remove spaces

        # Create a new page in Notion
        @_com.debug("4-Process page for: #{file_path2}")
        @_com.debug("4A-Creating page for: #{file_name}")
        body_add    = {
            'Reference'     => {'title' => [{'text' => {'content' => file_name}}]},
            'FileName'      => {'rich_text' => [{'text' => {'content' => file_path2}}]},
            'Tags'          => {'multi_select' => file_tags.map { |tag| {'name' => tag} }},
            'Type'          => {'select' => {'name' => file_type}},
            'FileSize'      => {'number' => file_size.to_i}
        }
        if @_mode == 'E' #<IF2>
            result      = @_not.addPage('', body_add)   #get result
            not_code    = result['code']                #extract code
            page_id     = result['id']                  #extract ID
        else    #<IF2>
            not_code = '900'
        end #<IF2>
        @_com.debug("4B-Notion add page result: #{not_code} [900 = Log only]")

        # Upload to Notion
        @_com.debug("5-Uploading: #{file_name} (#{file_size} bytes)")
        if @_mode == 'E' #<IF2>
            rc = @_not.upLoadFile(page_id, file_path2, file_data, file_size)
            if rc   #<IF3>
                @_com.debug("5A-Upload successful for #{file_name}")
#                @_com.logData("5A-Upload successful for #{file_name}")
                @count += 1
            else    #<IF3>
                @_com.debug("###ERR>5B-Upload failed for #{file_name}")
            end #<IF3>
        else    #<IF2>
            @_com.debug("5C-Upload skipped for #{file_name} (Log only mode)")
        end #<IF2>

        # Rename if requested
        if file_rename  #<IF2>
            File.rename(file_path2, file_path)
            puts "Renamed #{file_path2} back to #{file_path}"
        end #<IF2>
    end #<L1>

    #Display counters
    #================
    @_com.debug("6-Counters::Files selected:#{@count_sel} uploaded:#{@count}")
#    @_com.logData("6-Counters::Files selected:#{@count_sel} uploaded:#{@count}")
    @_com.debug(program,"Done at #{Time.now} ")
#<EOS>