#
=begin
    #Function:  upload files to Notion
    #Call:      ruby PrvUpload_File.rb N
    #Parameters::
        #P1:    Debug       => true/Y=>debug / false/N=>None
        #P2:    Mode        => L for log only / E for execute
    #Actions:
        #Create date: 20250530 with Build: 01.01.01
        #Updates:
            #Build: 01.02.01 <>    Logs: ?
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
    require_dir = Dir.pwd
    ### puts    "dirREQUIRE:"+require_dir
require "#{require_dir}/ClDirectories.rb"
    _dir    = Directories.new(false)
# End of block
#***** Directories management *****
#

#
# Input parameters
#*****************
begin
    _debug  = ARGV[0]
    @_mode  = ARGV[1]
rescue
    _debug  = false
    @_mode   = 'L'
end
    _debug  = true if _debug == 'Y'
    _debug  = false if _debug == 'N'

# Check parameters
#*****************
    if _debug
        puts "Debug mode: #{_debug}"
    end

#
#***** Exec environment *****
# Start of block
    program = 'PrvUpload_File'
    exec_mode   = 'B'                                   #change B or P
    dbglevel    = 'DEBUG'
    arrdirs = _dir.otherDirs(exec_mode)                 #=>{exec,private,membres,common,send,work}
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
    @typeoffiles = [
        'txt', 
        'pdf', 
        'json', 
        'csv',
        'rb',
        'xlsx'
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
        '#gilbert.downloads'                => '/users/Gilbert/Downloads',
        '#gilbert.progs.dvlps.common'       => '/users/Gilbert/Public/Progs/Dvlps/Common',
        '#icloud.documents'                 => '/users/Gilbert/Library/Mobile Documents/com~apple~CloudDocs/Documents',
        '#icloud.downloads'                 => '/users/Gilbert/Library/Mobile Documents/com~apple~CloudDocs/Downloads',
        '#pcloud.backups'                   => '/users/Gilbert/pCloud Drive/Backups/kDrive',
        '#pcloud.documents.informatic'      => '/users/Gilbert/pCloud Drive/Documents/Informatic',
        '#pcloud.eaglefiler_temptemp'       => '/users/Gilbert/pCloud Drive/EagleFiler_Temp',
        '#pcloud.ighe/ghe-dos_etc.rapports' => '/users/Gilbert/pCloud Drive/iGhe/Ghe-Dos_etc/Rapports'
    }
    dir_exclude = [
        'Library', 'Downloads', 'Desktop', 'Pictures', 'Photos',
        'archives', 'old', 'Video', 'Musique', 'MacBook', 'Mails', 'Backs',
        'Sync', 'Softwares', 'opt'
    ]
#
# Internal functions
#*******************
    def procFiles()
    # Process all files in a directory
        #INP:
        #OUT:
        directory_path  = Dir.pwd                            #get current directory path
        selected_files  = Dir.glob("#{directory_path}/*.{txt,pdf,json,csv,rb,xlsx}")

        @_com.step("3-Selected files: #{selected_files.length}")
        @_com.logData("3-Selected files: #{selected_files.length}")
        selected_files.each do |file_path|  #<L1>
            file_length = selected_files.length         #get number of files selected
            file_name   = File.basename(file_path)      #get file name
            file_size   = File.size(file_path)          #get file size
            file_type   = File.extname(file_name).delete('.') #get file type without dot
            file_tags   = "upload,#{file_type}"         #set tags for the file
            file_data   = File.read(file_path)          #read file data

            # Upload or not 
            puts "*"
            @count_sel   +=1
            @_com.step("3A-Processing file: #{file_name} as #{@count_sel}/#{selected_files.length}")
        ###    @_com.logData("3A-Processing file: #{file_name} as #{@count_sel}/#{selected_files.length}")
            if @reply_ok != 'ALL'
                print "Ok for this file to upload: #{file_name} (#{file_size} bytes, type: #{file_type}) [Y/N/Q]: "
                @reply_ok    = $stdin.gets.chomp.strip.upcase
                next if @reply_ok.nil? or @reply_ok.empty? or @reply_ok.size < 1
                exit 7 if @reply_ok == 'Q' || @reply_ok == 'QUIT' || @reply_ok == 'EXIT' || @reply_ok.size == 0
                next if @reply_ok == 'N' || @reply_ok == 'NO' || @reply_ok == 'NONE'
                next if @reply_ok != 'Y' && @reply_ok != 'ALL'
            else    #<IF2>
                @_com.step("3A-Ok for this file to upload: #{file_name} (#{file_size} bytes, type: #{file_type}")
            end

            # Read start of data if .txt
            if file_type == 'txt' || file_type == 'csv' #<IF2>
                File.open(file_path, 'rb') do |file|  #<L3>
                    chunk_data    = file.read(300)   #
                    puts "Display first 300 chars: #{chunk_data.inspect}"
                end #<L3>
            end

            # Get tags
            if @reply_ok != 'ALL' #<IF2>
                print "Define tags for the file (default: #{file_tags}): "
                file_tags   = $stdin.gets.chomp.strip
            end #<IF2>
            file_tags   = "upload,#{file_type}" if file_tags.empty? or file_tags.nil? or file_tags.size < 2 #default tags
            file_tags   = file_tags.split(',').map(&:strip) #split tags by comma and remove spaces

            # Create a new page in Notion
            @_com.step("4-Process page for: #{file_name}")
        ###    @_com.logData("4-")
        ###    @_com.logData("4-Process page for: #{file_name}")
        ###    @_com.logData("4-")
            @_com.step("4A-Creating page for: #{file_name}")
        ###    @_com.logData("4A-Creating page for: #{file_name}")
            body_add    = {
                'Reference' => {'title' => [{'text' => {'content' => file_name}}]},
                'FileName'  => {'rich_text' => [{'text' => {'content' => file_path}}]},
                'Tags'      => {'multi_select' => file_tags.map { |tag| {'name' => tag} }},
                'Type'      => {'select' => {'name' => file_type}},
                'FileSize'  => {'number' => file_size.to_i}
            }
            if @_mode == 'E' #<IF2>
                result      = @_not.addPage('', body_add)    #get result
                not_code    = result['code']                #extract code
                page_id     = result['id']                  #extract ID
            else    #<IF2>
                not_code = '900'
            end #<IF2>
            @_com.step("4B-Notion add page result: #{not_code} [900 = Log only]")
        ###    @_com.logData("4B-Notion add page result: #{not_code} [900 = Log only]")

            # Upload to Notion
            @_com.step("5-Uploading: #{file_name} (#{file_size} bytes)")
        ###    @_com.logData("5-Uploading: #{file_name} (#{file_size} bytes)")
            if @_mode == 'E' #<IF2>
                rc = @_not.upLoadFile(page_id, file_path, file_data, file_size)
                if rc   #<IF3>
                    @_com.step("5A-Upload successful for #{file_name}")
                    @_com.logData("5A-Upload successful for #{file_name}")
                    @count += 1
                else    #<IF3>
                    @_com.step("###ERR>5B-Upload failed for #{file_name}")
                end #<IF3>
            else    #<IF2>
                @_com.step("5C-Upload skipped for #{file_name} (Log only mode)")
            end #<IF2>
        end #<L1>
    end #<def>
#
# Main code
#**********
    # Initialize
    #+++++++++++
    # Notion class
    @_not    = ClNotion_2F.new('Private')                 # Private DBs familly

###    @_com.logData("**********")
    @_com.start(program," Start at #{Time.now} ")
    @_com.logData(" Start at #{Time.now} ")
    @_com.step("1-Initialize>")
###    @_com.logData("1-Initialize>")
    rc  = @_not.loadParams(_debug,@_not)                  #load params to Notion class
    @_com.step("1A-loadParams => #{rc}")
###    @_com.logData("1A-loadParams => #{rc}")
    rc  = @_not.initNotion(not_key)                      #init new cycle for 1 DB
    @_com.step("1B-initNotion for #{not_key}=> #{rc}")
###    @_com.logData("1B-initNotion for #{not_key}=> #{rc}")

    #
    # Processing
    #+++++++++++
    @_com.step("2-Processing")
###    @_com.logData("2-Processing")

    Dir.chdir("/users/Gilbert")                         #start @ home directory
    puts    "Replies allowed : " + 
        "\n- # for predefined" + 
        "\n- @i for iDrive" +
        "\n- @p for pDrive forward mode" + 
        "\n- @r for pDrive backward mode"
    print "Current directory: #{Dir.pwd} - set to ? "
    directory   = $stdin.gets.chomp
    
    case directory
    when '#'
        # Predefined directories
        dir_flag = true
        ## Display
        dir_pre.each_with_index do |dir,index| #<L2>
            puts "#{index+1} -> #{dir}"
        end #<L2>
        ## Select
        print "Select directory by N°: "
        dir_index = $stdin.gets.chomp.to_i - 1
        exit 5 if dir_index < 0 || dir_index >= dir_pre.length
        directory = dir_pre.values[dir_index]
        @_com.step("2A-Predefined directory selected: #{directory}")
    ###    @_com.logData("2A-Predefined directory selected: #{directory}")
        
        if dir_flag
            if File.directory?(directory) == false    #<IF1>
                puts "###ERR>Directory does not exist: #{directory}"
                exit 1
            end #<IF1>
            Dir.chdir(directory)                            #change to directory
        else
            if File.directory?("/users/Gilbert/"+directory) == false    #<IF1>
                puts "###ERR>Directory does not exist: #{directory}"
                exit 1
            end #<IF1>
            Dir.chdir("/users/Gilbert/#{directory}")            #change to directory
        end
        @_com.step("2B-Set directory to: #{Dir.pwd}")
        @_com.logData("2B-Set directory to: #{Dir.pwd}")

        procFiles()  # Process files in the selected directory

    when '@i'
        # Directories & sub-directories
        dir_flag = true
        dir_start = "/users/Gilbert/Library/Mobile Documents/com~apple~CloudDocs"
        dir_index = 99999
        while dir_index > 0 #<L2>

            if Dir.exist?(dir_start)
                Dir.foreach(dir_start) do |filex|
                    next if filex == '.' or filex == '..'
                    #next if filex.include?('.')
                    #next if !File.directory?(filex)
                    puts filex
                end
            end

            dir_list = Dir.glob("#{dir_start}/*").select{|entry| File.directory?(entry)}
            # Display lists
            @_com.step("2C-Check Files: #{dir_start}/*")
            dir_list.each_with_index do |dir,index| #<L2>
                puts "#{index+1} -> #{dir}"
            end
            # Select directory
            print "Select directory by N°: "
            dir_index = $stdin.gets.chomp.to_i-1
            exit 5 if dir_index < 0 || dir_index >= dir_list.length
            dir_select = dir_list[dir_index]
            puts "You selected: #{dir_select}"
            print "Next sub-directory? [Y/N]: "
            reply = $stdin.gets.chomp.strip.upcase
            if reply == 'Y' #<IF3>
                dir_start = dir_select
            else    #<IF3>
                directory = dir_select
                dir_index = 0
            end #<IF3>
        end #<L2>

        if dir_flag
            if File.directory?(directory) == false    #<IF1>
                puts "###ERR>Directory does not exist: #{directory}"
                exit 1
            end #<IF1>
            Dir.chdir(directory)                            #change to directory
        else
            if File.directory?("/users/Gilbert/"+directory) == false    #<IF1>
                puts "###ERR>Directory does not exist: #{directory}"
                exit 1
            end #<IF1>
            Dir.chdir("/users/Gilbert/#{directory}")            #change to directory
        end
        @_com.step("2B-Set directory to: #{Dir.pwd}")
        @_com.logData("2B-Set directory to: #{Dir.pwd}")

        procFiles()  # Process files in the selected directory

    when '@l'

        
    when '@p'
        # Directories & sub-directories
        dir_flag = true
        dir_start = "/users/Gilbert/pCloud Drive"
        print "Current directory: #{dir_start} - add: "
        sub_directory   = $stdin.gets.chomp
        dir_start = "#{dir_start}/#{sub_directory}" if sub_directory && !sub_directory.empty?
        @_com.step("Start directory: #{dir_start}")
        @_com.logData("Start directory: #{dir_start}")
        dir_index = 99999
        while dir_index > 0 #<L2>
            @_com.step("2C-Please take a while ...")
            @_com.step("2C-Check Files: #{dir_start}/**/*")
            dir_list = Dir.glob("#{dir_start}/**/*").select{|entry| File.directory?(entry) && dir_exclude.none?{ |ex| entry.include?(ex) }}
            puts "L0-"+dir_list.length.to_s
            pp dir_list
        ###    exit 3 if !@_com.continue()
            # Display lists
            dir_list.each_with_index do |dir,index| #<L2>
                puts "#{index+1} -> #{dir}"
            end
            # Select directory
            print "Select directory by N°: "
            dir_index = $stdin.gets.chomp.to_i-1
            exit 5 if dir_index < 0 || dir_index >= dir_list.length
            dir_select = dir_list[dir_index]
            puts "You selected: #{dir_select}"
            print "Next sub-directory? [Y/N]: "
            reply = $stdin.gets.chomp.strip.upcase
            if reply == 'Y' #<IF3>
                dir_start = dir_select
            else    #<IF3>
                directory = dir_select
                dir_index = 0
            end #<IF3>
        end #<L2>
        
        if dir_flag
            if File.directory?(directory) == false    #<IF1>
                puts "###ERR>Directory does not exist: #{directory}"
                exit 1
            end #<IF1>
            Dir.chdir(directory)                            #change to directory
        else
            if File.directory?("/users/Gilbert/"+directory) == false    #<IF1>
                puts "###ERR>Directory does not exist: #{directory}"
                exit 1
            end #<IF1>
            Dir.chdir("/users/Gilbert/#{directory}")            #change to directory
        end
        @_com.step("2B-Set directory to: #{Dir.pwd}")
        @_com.logData("2B-Set directory to: #{Dir.pwd}")

        procFiles()  # Process files in the selected directory

    when '@r'
        # all Directories & sub-directories
        dir_flag = true
        dir_start = "/users/Gilbert/pCloud Drive"
        print "Current directory: #{dir_start} - add: "
        sub_directory   = $stdin.gets.chomp
        dir_start = "#{dir_start}/#{sub_directory}" if sub_directory && !sub_directory.empty?
        @_com.step("Start directory: #{dir_start}")
        @_com.logData("Start directory: #{dir_start}")
        dir_index = 99999
        while dir_index > 0 #<L2>
            @_com.step("2C-Check Files: #{dir_start}/**/*")
            dir_list = Dir.glob("#{dir_start}/**/*").select{|entry| File.directory?(entry) && dir_exclude.none?{ |ex| entry.include?(ex) }}
            # Display lists
            dir_list.each_with_index do |dir,index| #<L2>
                puts "#{index+1} -> #{dir}"
            end
            # Select directory
            print "Select start directory by N°: "
            dir_index = $stdin.gets.chomp.to_i-1
            exit 5 if dir_index < 0 || dir_index >= dir_list.length
            dir_select = dir_list[dir_index]
            puts "You selected: #{dir_select} with all sub-directories"
            directory = dir_select
            dir_index = 0
        end #<L2>

        # Check on 5 levels of sub-directories
        dirs_l1 = []
        dirs_l1 = Dir.glob("#{directory}/*").select{|entry| File.directory?(entry)}

        puts "L1-"+dirs_l1.length.to_s
        pp dirs_l1
    ###    exit 3 if !@_com.continue()

        if dirs_l1.length > 0 #<L2>
            dirs_l2 = []
            dirs_l1.each do |dir_l1| #<L3>
                puts "Processing directory: #{dir_l1}"
                dirs_l2 = Dir.glob("#{dir_l1}/*").select{|entry| File.directory?(entry)}

        puts "L2-"+dirs_l2.length.to_s
        pp dirs_l2
    ###    exit 3 if !@_com.continue()
        
                if dirs_l2.length > 0 #<L4>
                    dirs_l3 = []
                    dirs_l2.each do |dir_l2| #<L5>
                        puts "Processing sub-directory: #{dir_l2}"
                        dirs_l3 = Dir.glob("#{dir_l2}/*").select{|entry| File.directory?(entry)}

        puts "L3-"+dirs_l3.length.to_s
        pp dirs_l3
    ###    exit 3 if !@_com.continue()
        
                        if dirs_l3.length > 0 #<L6>
                            dirs_l4 = []
                            dirs_l3.each do |dir_l3| #<L7>
                                puts "Processing sub-directory: #{dir_l3}"
                                dirs_l4 = Dir.glob("#{dir_l3}/*").select{|entry| File.directory?(entry)}

        puts "L4-"+dirs_l4.length.to_s
        pp dirs_l4
    ###    exit 3 if !@_com.continue()
        
                                if dirs_l4.length > 0 #<L8>
                                    dirs_l4.each do |dir_l4| #<L9>
                                        puts "Processing files on: #{dir_l4}"
                                        selected_files  = Dir.glob("#{dir_l4}/*.{txt,pdf,json,csv}")
                                        if selected_files.length > 0    #<IF-2 -> files in the sub-directory>
                                            Dir.chdir(dir_l4)  # Change to the sub-directory
                                            @_com.logData("2B-Set directory to: #{Dir.pwd}")
                                            procFiles()  # Process files in the selected directory
                                        end #<IF-2>
                                    end #<L9>
                                end #<L8>
                                puts "Processing files on: #{dir_l3}"
                                selected_files  = Dir.glob("#{dir_l3}/*.{txt,pdf,json,csv}")
                                if selected_files.length > 0    #<IF-2 -> files in the sub-directory>
                                    Dir.chdir(dir_l3)  # Change to the sub-directory
                                    @_com.logData("2B-Set directory to: #{Dir.pwd}")
                                    procFiles()  # Process files in the selected directory
                                end #<IF-2>
                            end #<L7>
                        end #<L6>
                        puts "Processing files on: #{dir_l2}"
                        selected_files  = Dir.glob("#{dir_l2}/*.{txt,pdf,json,csv}")
                        if selected_files.length > 0    #<IF-2 -> files in the sub-directory>
                            Dir.chdir(dir_l2)  # Change to the sub-directory
                            @_com.logData("2B-Set directory to: #{Dir.pwd}")
                            procFiles()  # Process files in the selected directory
                        end #<IF-2>
                    end #<L5>
                end #<L4>
                puts "Processing files on: #{dir_l1}"
                selected_files  = Dir.glob("#{dir_l1}/*.{txt,pdf,json,csv}")
                if selected_files.length > 0    #<IF-2 -> files in the sub-directory>
                    Dir.chdir(dir_l1)  # Change to the sub-directory
                    @_com.logData("2B-Set directory to: #{Dir.pwd}")
                    procFiles()  # Process files in the selected directory
                end #<IF-2>
            end #<L3>
        end #<L2>
        puts "Processing files on: #{directory}"
        selected_files  = Dir.glob("#{directory}/*.{txt,pdf,json,csv,xlsx}")
        if selected_files.length > 0    #<IF-2 -> files in the sub-directory>
            Dir.chdir(directory)  # Change to the sub-directory
            @_com.logData("2B-Set directory to: #{Dir.pwd}")
            procFiles()  # Process files in the selected directory
        end #<IF-2>
    end

    #Display counters
    #================
    @_com.step("6-Counters::Files selected:#{@count_sel} uploaded:#{@count}")
    @_com.logData("6-Counters::Files selected:#{@count_sel} uploaded:#{@count}")
    @_com.stop(program,"Done at #{Time.now} ")
#<EOS>