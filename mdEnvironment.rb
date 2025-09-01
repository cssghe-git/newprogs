#
=begin
    Module: mdEnvironment
    Goals:  define environment variables
    Format: {'appli'=>{'p1'=>"?",'p2'=>"?",...}}
    Build:  01.01.00    @ 250717-1449
    Functions:
        getParameters() => extract all parameters for 1 application
        updParameters() => update some parameters for 1 application
=end
#
# Variables
#==========
    appli_flag      = false                             #true when json read
    appli_params    = {
        'None'  => {
            'p1'=>  "P1",
            'p2'=>  "P2"
        }
    }
# Functions
#==========
    def getParameters(p_appli='None')
    #****************
        #INP:   appli:  application key
        #OUT:   parameters
        #
        if appli_flag == false                          #read json file
        end
        #
        return  appli_params['p_appli']
    end #<def>getParameters
    #
    def updParameters(p_appli='None',p_prms={})
    #****************
        #INP:   appli:  application key
        #       prms:   new parameters
        #OUT:   file json updated
        #
        appli_params['p_appli'] = p_prms
    end #<def>updParameters)