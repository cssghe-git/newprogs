#
=begin
    #   Define infos for all private DBs
    #   VRP: 1-1-1 <> <
=end
# Require some DB values

module Common_Dbs
#****************
#
#   Variables
#   +++++++++
    @all_infos  = {}
    #private
    @all_infos['evenements']    = {
            'dbname'    => 'enct.Events',
            'dblink'    => 'https://www.notion.so/cssghe/21e72117082a80948241f6dd297c450a?v=21e72117082a804e90fd000c420a460f&source=copy_link',
            'dbid'      => '21e72117082a80948241f6dd297c450a',
            'dbsecret'  => 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3',
            'properties'=> {}
    }
    @all_infos['cbc_records']   = {
            'dbname'    => 'enct.Fin-Trans_CBC',
            'dblink'    => '',
            'dbid'      => '',
            'dbsecret'  => '',
            'properties'=> {}
    }
    @all_infos['auteurs']       = {
            'dbname'    => 'enct.Auteurs',
            'dblink'    => 'https://www.notion.so/1e072117082a80478149f7ab1b020ea3?v=1e072117082a80549645000c4cc2ad0e&pvs=4',
            'dbid'      => '1e072117082a80478149f7ab1b020ea3',
            'dbsecret'  => 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3',
            'properties'=> {}
    }
    @all_infos['livres']        = {
            'dbname'    => 'enct.Livres',
            'dblink'    => 'https://www.notion.so/cssghe/13572117082a80e0acc8f5d50c791ed7?v=13572117082a81fcade5000c8d86d85c&pvs=4',
            'dbid'      => '13572117082a80e0acc8f5d50c791ed7',
            'dbsecret'  => 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3',
            'properties'=> {}
    }
    @all_infos['emails25']      = {
            'dbname'    => 'enct.Emails.25',
            'dblink'    => 'https://www.notion.so/cssghe/64ef68da08884deaa0df186a96ec5cc3?v=4f3089903c5245ae98d71c3f24ddb427&pvs=4',
            'dbid'      => '64ef68da08884deaa0df186a96ec5cc3',
            'dbsecret'  => 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3',
            'properties'=> {}

    }
    @all_infos['archives24']    = {
            'dbname'    => 'enct.Archives.24',
            'dblink'    => 'https://www.notion.so/cssghe/1f072117082a80f0bfdcff0921ff4f6b?v=1f072117082a816e8600000c2aa5c9c3&pvs=4',
            'dbid'      => '1f072117082a80f0bfdcff0921ff4f6b',
            'dbsecret'  => 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3',
            'properties'=> {}
    }
    @all_infos['filesupload']   = {
            'dbname'    => 'enct.FilesUpload',
            'dblink'    => 'https://www.notion.so/cssghe/20172117082a809784efeb6f051f8e0c?v=20172117082a80c98939000cc986227f&pvs=4',
            'dbid'      => '20172117082a809784efeb6f051f8e0c',
            'dbsecret'  => 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3',
            'properties'=> {}

    }
    @all_infos['report']        = {
            'dbname'    => 'enct.Fin-Rapports',
            'dblink'    => 'https://www.notion.so/cssghe/19472117082a8080876dc65ee8791d15?v=1aa72117082a8030842d000c18549708&source=copy_link',
            'dbid'      => '19472117082a8080876dc65ee8791d15',
            'dbsecret'  => 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3',
            'properties'=> {}
    }

    #eneo
    @all_infos['membres_v24']   = {
            'dbname'    => 'mbr24.Membres_NIV',
            'dblink'    => 'https://www.notion.so/eneobw/19ae0e553d938007b793fc4e7e74e666?v=19ae0e553d93819e95fb000ce1280044&pvs=4',
            'dbid'      => '19ae0e553d938007b793fc4e7e74e666',
            'dbsecret'  => 'secret_2XXOYzX5JThHqZviHGZpPna5ihVU2o3knCvrCu76RjS',
            'properties'=> {}
    }
    @all_infos['modifications_v24'] = {
            'dbname'    => 'mbr24.Modifications_NIV',
            'dblink'    => 'https://www.notion.so/eneobw/19de0e553d9380a9bbdaf5e2f4685118?v=19de0e553d9381c48dae000c88a3acc6&pvs=4',
            'dbid'      => '19de0e553d9380a9bbdaf5e2f4685118',
            'dbsecret'  => 'secret_2XXOYzX5JThHqZviHGZpPna5ihVU2o3knCvrCu76RjS',
            'properties'=> {}
    }
    @all_infos['logfile_v24']   = {
            'dbname'    => 'mbr24.Logfile',
            'dblink'    => 'https://www.notion.so/eneobw/19be0e553d9380fe8d98cc8fc7216ca0?v=19be0e553d938160b3db000c511e52b0&pvs=4',
            'dbid'      => '19be0e553d9380fe8d98cc8fc7216ca0',
            'dbsecret'  => 'secret_2XXOYzX5JThHqZviHGZpPna5ihVU2o3knCvrCu76RjS',
            'properties'=> {}
    }
    @all_infos['updates_v24']   = {
            'dbname'    => 'mbr24.Updates_NIV',
            'dblink'    => 'https://www.notion.so/eneobw/1bce0e553d9380e49274e17425df2236?v=1cbe0e553d9380caad1e000c8aa60068&pvs=4',
            'dbid'      => '1bce0e553d9380e49274e17425df2236',
            'dbsecret'  => 'secret_2XXOYzX5JThHqZviHGZpPna5ihVU2o3knCvrCu76RjS',
            'properties'=> {}
    }
    @all_infos['updates-csv_v24']   = {
            'dbname'    => 'mbr24.Updates_NIV (CSV)',
            'dblink'    => 'https://www.notion.so/eneobw/23fe0e553d93809ab446d647b6da9660?v=23fe0e553d938036aacc000c318cc87c&source=copy_link',
            'dbid'      => '23fe0e553d93809ab446d647b6da9660',
            'dbsecret'  => 'secret_2XXOYzX5JThHqZviHGZpPna5ihVU2o3knCvrCu76RjS',
            'properties'=> {}
    }
    @all_infos['cybmeetings']   = {
            'dbname'    => 'cyb2t.Reunions.Presences',
            'dblink'    => 'https://www.notion.so/cssghe/1e872117082a80f881d0caaf2f3d2bda?v=1e872117082a80818e99000c53cbe055&source=copy_link',
            'dbid'      => '1e872117082a80f881d0caaf2f3d2bda',
            'dbsecret'  => 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3',
            'properties'=> {'Reference' => 'title'}
    }
    @all_infos['tasks_list']      = {
            'dbname'    => 'mbr2t.Mgt.Tasks',
            'dblink'    => 'https://www.notion.so/cssghe/21972117082a804aae40c26ff35c1450?v=21972117082a8021a8ab000c35d5370b&source=copy_link',
            'dbid'      => '21972117082a804aae40c26ff35c1450',
            'dbsecret'  => 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3',
            'properties'=> {'Reference'=> 'title'}
    }

    #template
    @all_infos['template']      = {
            'dbname'    => '',
            'dblink'    => '',
            'dbid'      => '',
            'dbsecret'  => '',
            'properties'=> {}
    }

#
#   Functions
#   +++++++++
    #
    # Return all DB infos to caller
    #
    def Common_Dbs.loadInfos(p_db)
    #+++++++++++++++++++++++
        #INP::  DB key
        #OUT::  {...}
        #
        #make correct key
        db_key  = p_db.strip.downcase.gsub('é','e').gsub('è','e')
        #
        return  @all_infos[db_key]
    end #<def>
    #




end #<Mod>
