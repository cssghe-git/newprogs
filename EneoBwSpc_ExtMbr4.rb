#
=begin
    #Function:  extract members for 1 activity
    #Call:      ruby EneoBwSpc_ExtMbr.rb N
    #Parameters::
        #P1:    argv: R=>request D=>default Y=>debug
    #Actions:
        #
        #
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
#
    require_dir = Dir.pwd
require "#{require_dir}/ClDirectories.rb"
#
    program = 'EneoBwSpc_ExtMbr4'
    exec_mode   = 'P'                                   #change B or P
    _dir    = Directories.new('N')
    arrdirs = _dir.otherDirs(exec_mode)                 #=>{exec,private,membres,common,send,work}
require "#{arrdirs['common']}/ClCommon_2.rb"
    _com    = Common_2.new(program,'N',"DEBUG")
require "#{arrdirs['common']}/ClNotion_2.rb"
    #
    downloads_dir   = arrdirs['work']
    send_dir        = arrdirs['send']
#
# Input parameters
#*****************
    _debug  = 'N'

# Variables
#**********
    #membres_v24 => mbr_
    mbr_key     = 'membres_v24'                         #DB key
    mbr_fields  = []                                    #DB fields
    #requests
    req_fields  = [                                     #array of fields requested, or ALL
        'Référence','CDC','ActivitéP','ActivitéS',
        'EnCours','Statut','Etat'
    ] 
    #   req_fields  = ['ALL']
    req_activity    = 'NIV-Pilates'     #*********dont forget to update this value**********
    #
    infos   = {}
    count   = 0

#
# Internal functions
#*******************

# Main code
#**********
    # Initialize
    #+++++++++++
    # Notion class
    _mbr    = ClNotion_2.new('Mbr24')                   #mbr24 DBs familly

    puts    "DBG>>Init>"
    rc  = _mbr.loadParams(false,_mbr)                     #load params to Notion class
    puts    "DBG>>loadParams => #{rc}"
    rc  = _mbr.initNotion(mbr_key)                      #init new cycle for 1 DB
    puts    "DBG>>initNotion for #{mbr_key}=> #{rc}"

    #
    # Processing
    #+++++++++++

    puts    "DBG>>Processings"
    puts    "DBG>>Get MBR Fields"
    result  = _mbr.getDbFields()
    mbr_fields  = result['data']
    puts    "DBG>>Fields: #{mbr_fields}"

    #   puts    "DBG>Search Title"
    #   result  = _mbr.schTitle('database','')
    #   code    = result['code']
    #   id      = result['ID']
    #   data    = result['result']
    #   pp result

    #   exit 9

    puts    "DBG>>Yield block"
    mbr_filter  = {
        'and'=> [
            {'property'=> 'EnCours', 'checkbox'=>{'equals'=>true}},
            {'property'=> 'AllActs', 'formula'=> {'string'=> {'contains'=> req_activity}}}
        ]
    }
    mbr_sort    = [
        {'property'=> 'Référence', 'direction'=> 'ascending'}
    ]
    fields  = ['Référence','CDC','ActivitéP','ActivitéS','EnCours','Statut','Etat'] #array of fields requested, or ALL
    #   fields  = ['ALL']

    _mbr.runProperties(mbr_filter,mbr_sort,fields) do |data|            #execute bloc on Notion class with filter, sort & properties
                                                        #data => result function => contains all properties
        count   += 1
        ### pp  data

        print "   =>"
        data.each do |prop|                             #loop all properties
            #pp  prop
            name    = prop[0]                           #extract name
            value   = prop[1]                           #extract value
            case    name
            when    'CDC','Référence','ActivitéP','ActivitéS',
                    'EnCours','Statut','Etat'
                print   "#{name.upcase}:#{value} "
            end
        end
        puts " "
    end

    puts    "DBG>>End"
    puts    "DBG>>Count: #{count} recs"
