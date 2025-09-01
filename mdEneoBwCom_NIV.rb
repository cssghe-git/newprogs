#
=begin
  
=end
module EneoBwCom_NIV
#
#
#Variables
#+++++++++
    ####################
#   NIV
    @sel_cdc     = 'NIV'
    @sel_act     = [
        'None',
        'Amicale_des_Archers',
        'Aquagym_1',
        'Aquagym_2',
        'Aquagym_3',
        'Art_Floral',
        'Danse',
        'Dessin',
        'Gymnastique_1',
        'Gymnastique_2',
        'Informatique',
        'Marcheurs_du_Jeudi',
        'Marche_Nordique',
        'Pilates',
        'Randonneurs_du_Brabant',
        'Scrapbooking',
        'TaiChi',
        'Tennis_de_Table',
        'Vie_Active',
        'System',
        'ALL'
    ]
    @sel_mbrid  = '96313b72db5542cbac572be3004087d1'    #Membres_NIV => https://www.notion.so/eneobw/96313b72db5542cbac572be3004087d1?v=5ac067539c334b8a83a6b19e03d122a2&pvs=4
    @sel_modid  = '84861af4723d481c81e83d63b6af6f92'    #Modifications_NIV => https://www.notion.so/eneobw/84861af4723d481c81e83d63b6af6f92?v=5764334843864f8f9b578efab75a9599&pvs=4
    @sel_cotid  = '179e0e553d93808da562e2e349e06156'    #Cotisations_NIV => https://www.notion.so/eneobw/179e0e553d93808da562e2e349e06156?v=94705033540046f9b69b3156a285aa98&pvs=4
#   .xlsx file =>
#       Statut  Référence   CDC Civilité    Nom Prénom  Adresse Canton  Ville   GSM Téléphone   Mail    Naissance   Cotisation  Cnci    CnciOK  Eneo    Remarque    ActPrc  ActSecs Entrée  Sortie  V-A
#       A1      B2          C3  D4          E   F       G7      H8      I9      J10 K11         L12     M13         N14         O15     P16     Q17     R18         S19     T20     U21     V22     W23
    @sel_f_fields        = {
        "f_statut"=> 0,
        "f_reference"=> 1,
        "f_cdc"=> 2,
        "f_civilite"=> 3,
        "f_nom"=> 4,
        "f_prenom"=> 5,
        "f_adresse"=> 6,
        "f_canton"=> 7,
        "f_ville"=> 8,
        "f_gsm"=> 9,
        "f_telephone"=> 10,
        "f_mail"=> 11,
        "f_naissance"=> 12,
        "f_cotisation"=> 13,
        "f_certificat"=> 14,
        "f_eneo"=> 15,
        "f_actprc"=> 16,
        "f_actsecs"=> 17,
        "f_entree"=> 18,
        "f_paiement"=> 19,
        "f_sortie"=> 20,
        "f_deces"=> 21,
        "f_va"=> 22
    }
#   Eneo/EneoSport
    @sel_eneo   = {
        'None'=>'Non',
        'NIV-Amicale_des_Archers'=>'Eneo',
        'NIV-Aquagym_1'=>'EneoSport',
        'NIV-Aquagym_2'=>'EneoSport',
        'NIV-Aquagym_3'=>'EneoSport',
        'NIV-Art_Floral'=>'Eneo',
        'NIV-Danse'=>'EneoSport',
        'NIV-Dessin'=>'Eneo',
        'NIV-Gymnastique_1'=>'EneoSport',
        'NIV-Gymnastique_2'=>'EneoSport',
        'NIV-Informatique'=>'Eneo',
        'NIV-Marcheurs_du_Jeudi'=>'eneoSport',
        'NIV-Marche_Nordique'=>'EneoSport',
        'NIV-Pilates'=>'EneoSport',
        'NIV-Randonneurs_du_Brabant'=>'EneoSport',
        'NIV-Scrapbooking'=>'Eneo',
        'NIV-TaiChi'=>'EneoSport',
        'NIV-Tennis_de_Table'=>'EneoSport',
        'NIV-Vie_Active'=>'EneoSport',
        'System'=>'None',
        'ALL'=>'None'
     }
#   emails
     @sel_emails    = {
        'None'=>'None',
        'NIV-Amicale_des_Archers'=>['henriettedubois4@gmail.com','chantalhottaux@hotmail.com'],
        'NIV-Aquagym_1'=>['klecker.anne@gmail.com'],
        'NIV-Aquagym_2'=>['anne.espalard@gmail.com'],
        'NIV-Aquagym_3'=>['paule.jadin@gmail.com'],
        'NIV-Art_Floral'=>['pascale.defrenne1951@gmail.com','semal.annik@live.fr'],
        'NIV-Danse'=>['patricia.secretariatdanse@gmail.com'],
        'NIV-Dessin'=>['ronaldhellin99@gmail.com','georges.lorge@outlook.com'],
        'NIV-Gymnastique_1'=>['ann.delcroix@gmail.com'],
        'NIV-Gymnastique_2'=>['vivianevleugels@gmail.com'],
        'NIV-Informatique'=>['eneo@heintje.net'],
        'NIV-Marcheurs_du_Jeudi'=>['agnes.paternostre@belgacom.net'],
        'NIV-Marche_Nordique'=>['bernadetteplasman@hotmail.com'],
        'NIV-Pilates'=>['francigille@skynet.be'],
        'NIV-Randonneurs_du_Brabant'=>['rdb.tresorier@gmail.com'],
        'NIV-Scrapbooking'=>['m.courtejoie@skynet.be'],
        'NIV-TaiChi'=>['m.steen@hotmail.be','csteveny@voo.be'],
        'NIV-Tennis_de_Table'=>['anne.espalard@gmail.com','pierre.marianne.merckx@gmail.com'],
        'NIV-Vie_Active'=>['claudedelvoye52@gmail.com'],
        'System'=>'None',
        'ALL'=>'None'
     }
####################
#
#Functions
#+++++++++
    def EneoBwCom_NIV.load()
    #   OUT: [cdc,activities,f_fields,mbr,mod,eneo,mail,cot]
        values  = [@sel_cdc,@sel_act,@sel_f_fields,@sel_mbrid,@sel_modid,@sel_eneo,@sel_emails,@sel_cotid]
        return values
    end #<def>
end #<module>