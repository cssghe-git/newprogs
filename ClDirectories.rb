#
=begin
    # => Class - ClDirectories.rb
    # => +++++++++++++++++++++
    #   Build: 4-1-1    <25051436->
    # => Functions :
            #initialize

=end
#Requires
#--------
require 'rubygems'
require 'timeout'
require 'date'
require 'pp'
#
class Directories
#****************
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
    @@classname    = self.name
#
#instance variables
#==================
    @_prog      = 'ClDirectories'
    @dbflag     = false
#
#Constructor
#===========
    def initialize(p_dbg=false)
    #+++++++++++++
       #instance variables
       @dbgflag     = p_dbg
       puts (@@classname+" Init ClDirectories") if @dbgflag
    end
#
#Accessor
#========
#
#Class methods
#=============
#
#Instance methods
#================
    # Missing
    #========
    def method_missing(name, *args)
    #+++++++++++++++++
        puts    "DBG>>>ClCommon_2>>Method>#{name} is missing with args>#{args.inspect}"
    end #<def>
    #
    def currentDir()
    #+++++++++++++
        return @@currentdir
    end
        #
    def otherDirs(p_exec='None',p_debug='N')
    #++++++++++++++
        #INP:
        #OUT: {'exec'=>,,,}
        #   assume directory : ..../Common
        current_dir = Dir.pwd                           #current directory
        puts    "dirCURRENT:"+current_dir       if @dbgflag
    
        Dir.chdir("#{current_dir}/..")
        beta_dir    = Dir.pwd                           #Beta directory
        puts    "dirBETA:"+beta_dir             if @dbgflag
        Dir.chdir("#{beta_dir}/Common")
        b_common_dir    = Dir.pwd                       #Common directory
        puts    "dirCOMMON/"+b_common_dir       if @dbgflag
        Dir.chdir("#{beta_dir}/Private")
        b_private_dir = Dir.pwd                         #Private directory
        puts    "dirPRIVATE:"+b_private_dir     if @dbgflag
        Dir.chdir("#{beta_dir}/MembersV2-3")            #Members directory
        b_members_dir = Dir.pwd
        puts    "dirMEMBERS:"+b_members_dir     if @dbgflag
    
        Dir.chdir("#{current_dir}/../../Prod")                                  #Progs directory
        prod_dir    = Dir.pwd                           #Prod directory
        puts    "dirPROD:"+prod_dir             if @dbgflag
        Dir.chdir("#{prod_dir}/Common")
        p_common_dir    = Dir.pwd                       #Common directory
        puts    "dirCOMMON/"+p_common_dir       if @dbgflag
        Dir.chdir("#{prod_dir}/Private")
        p_private_dir    = Dir.pwd                      #Private directory
        puts    "dirPrivate/"+p_private_dir     if @dbgflag
        Dir.chdir("#{prod_dir}/MembersV2-3")
        p_members_dir    = Dir.pwd                      #Members directory
        puts    "dirMEMBERS/"+p_members_dir     if @dbgflag
    
        Dir.chdir("#{current_dir}/../../../MemberLists")                                  #Progs directory
        mbrlist = Dir.pwd                               #MemberLists
        puts    "dirMBRLIST:"+mbrlist           if @dbgflag
        Dir.chdir("#{mbrlist}/ToSend")                                  #Progs directory
        tosend_dir  = Dir.pwd                           #ToSend
        puts    "dirTOSEND"+tosend_dir          if @dbgflag
        Dir.chdir("#{mbrlist}/ToProcess")                                  #Progs directory
        toprocess_dir  = Dir.pwd                        #ToProcess
        puts    "dirTOPROCESS"+toprocess_dir    if @dbgflag
        Dir.chdir("#{mbrlist}/Works")                                  #Progs directory
        works_dir   = Dir.pwd                           #Works
        puts    "dirWORKS:"+works_dir           if @dbgflag

        Dir.chdir("#{current_dir}/../../../Private")                                  #Progs directory
        prvlist = Dir.pwd                               #Private
        puts    "dirPRVLIST:"+mbrlist           if @dbgflag
        Dir.chdir("#{prvlist}/ToSend")                                  #Progs directory
        ptosend_dir  = Dir.pwd                           #ToSend
        puts    "dirPTOSEND"+ptosend_dir          if @dbgflag
        Dir.chdir("#{prvlist}/ToProcess")                                  #Progs directory
        ptoprocess_dir  = Dir.pwd                        #ToProcess
        puts    "dirPTOPROCESS"+ptoprocess_dir    if @dbgflag
        Dir.chdir("#{prvlist}/Works")                                  #Progs directory
        pworks_dir   = Dir.pwd                           #Works
        puts    "dirPWORKS:"+pworks_dir           if @dbgflag

        downloads_dir   = "/users/Gilbert/Library/Mobile Documents/com~apple~CloudDocs/Downloads"

        Dir.chdir(current_dir)                          #return to call directory
 
        dirs    = {
            'current'       => current_dir,
            'beta'          => beta_dir,
            'b.common'      => b_common_dir,
            'b.private'     => b_private_dir,
            'b.membres'     => b_members_dir,
            'prod'          => prod_dir,
            'p.common'      => p_common_dir,
            'p.private'     => p_private_dir,
            'p.membres'     => p_members_dir,
            'i.download'    => downloads_dir,
            'lists'         => mbrlist,
            'private'       => prvlist
        }
        pp  dirs    if @dbgflag
        
        case    p_exec.upcase
        when    'B'
            result  = {
                'exec'      => current_dir,
                'private'   => b_private_dir,
                'membres'   => b_members_dir,
                'common'    => b_common_dir,
                'send'      => tosend_dir,
                'process'   => toprocess_dir,
                'work'      => works_dir,
                'psend'     => ptosend_dir,
                'ppeocess'  => ptoprocess_dir,
                'pwork'     => pworks_dir,
                'idown'     => downloads_dir
            }
        when    'P'
            result  = {
                'exec'      => current_dir,
                'private'   => p_private_dir,
                'membres'   => p_members_dir,
                'common'    => p_common_dir,
                'send'      => tosend_dir,
                'process'   => toprocess_dir,
                'work'      => works_dir,
                'psend'     => ptosend_dir,
                'pprocess'  => ptoprocess_dir,
                'pwork'     => pworks_dir,
                'idown'     => downloads_dir
            }
        end
        pp  result   if @dbgflag
        return  result
    end #<def>
    #
end #<Class>
#<>
