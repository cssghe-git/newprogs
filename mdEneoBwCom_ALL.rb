#
=begin
    Build: 1.1.1    <23121400>
=end
module EneoBwCom_ALL
#
#
#Variables
#+++++++++
    ####################
#   OFF
    @off_cdc     = 'ALL'
    @off_act     = [
    ]
    @off_mbrid  = ''    #
    @off_modid  = ''    #
#   .xlsx file =>
#       Statut  Référence   CDC Civilité    Nom Prénom  Adresse Canton  Ville   GSM Téléphone   Mail    Naissance   Cotisation  Cnci    Eneo    Remarque    ActPrc  ActSecs Entrée  Sortie  Seagma
#       A1      B2          C3  D4          E   F       G7      H8      I9      J10 K11         L12     M13         N14         O15     P16     Q17         R18     S19     T20     U21     V22     W23
    @off_f_fields        = {
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
####################
#
#Functions
#+++++++++
    def EneoBwCom_ALL.load()
    #   OUT: [cdc,activities,f_fields]
        values  = [@off_cdc,@off_act,@off_f_fields]
        return values
    end #<def>
end #<module>