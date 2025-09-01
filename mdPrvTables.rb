#
=begin
    #   Define infos for all private DBs
    #   VRP: 1-1-1 <> <
=end

module PrvTables
#===============
#
#   Variables
#   +++++++++
    @tables  = {
        'TRA'   => {
            'prefix'        => 'TRA',
            'name'          => 'Sprocket.Transactions',
            'id'            => '9954848211e14d17b6c33617efd933d0',   #https://www.notion.so/cssghe/9954848211e14d17b6c33617efd933d0?v=94ac54e6d97c4ee19fd90a223f05ee82&pvs=4
            'integr'        => 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3',
            'properties'    => [
                'Name', 'Date trans', 'Date value', 'Date statement', 'amount trans', 'amount sub', 'amount exp',
                'Checked', 'Subscription', 'Category', 'Week', 'relWeek', 'Month', 'relMonth', 'processed',
                'Attachments', 'Account', 'This Month', 'Next Month', 'This Year', 'Next Year'
            ],
            'filter'        => {},
            'sort'          => {}
        },
        'WEEK'  => {
            'prefix'        => 'WEEK',
            'name'          => 'Sprocket.Weeks',
            'id'            => '05b82c18a3744633be75e67e6fc6bc08',  #https://www.notion.so/cssghe/05b82c18a3744633be75e67e6fc6bc08?v=d5e80c4dcc2146a6b0c6d13c57471e97&pvs=4
            'integr'        => 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3',
            'properties'    => [
                'Name','Week','Amount exp','Amount sub','Amount week','Total weeks','Weekly mean','Transactions',
                'Week-99','Weeks','Reference','Dates'
            ],
            'filter'        => {},
            'sort'          => {}
        },
        'MONTH'  => {
            'prefix'        => 'MONTH',
            'name'          => 'Sprocket.Months',
            'id'            => '1677d3cabb2b416fb0482c3ebf641d00',  #https://www.notion.so/cssghe/1677d3cabb2b416fb0482c3ebf641d00?v=746eeaf10369413d9fc9502c68c63c4c&pvs=4
            'integr'        => 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3',
            'properties'    => [
                'Name','Month','Amount trans','Amount exp','Amount sub','Amount month','Total months',
                'Monthly mean','Transactions','Month-99','Months','Dates','Reste','Reference'
            ],
            'filter'        => {},
            'sort'          => {}
        },
        'ACCOUNT'   => {
            'prefix'        => 'ACCOUNT',
            'name'          => 'Sprocket.Accounts',
            'id'            => '',
            'integr'        => 'secret_FIhPnoyaCFBlTWzD1Y4BBRbzEx7chTck1HkAm14uBd3',
            'properties'    => [],
            'filter'        => {},
            'sort'          => {}
        }
    }
#
#   Functions
#   +++++++++
    #Return infos to caller
    def PrvTables.loadTable(p_table)
    #++++++++++++++++++++++
        #INP::  p_table: prefix
        #OUT::  {pref=>,name=>,id=>,properties=>,filter=>,sort=>,}
        #
        return  @tables[p_table]
    end #<def>
    #
    #
end #<Mod>
