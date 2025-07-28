**free
      //%METADATA                                                      *
      // %TEXT maintenance infocentre;statique;natif                   *
      //%EMETADATA                                                     *
//---------------------------------------------
// Programme.......:MNTINFOC
// Description.....:Maintenance de l'infocentre
// Creation Date.: 2024-06-29
// Create by.....:
//---------------------------------------------

//liste des indicateurs
// 03 : F3
// 09 : confirmation (F9)
// 12 : F12
// 31 : true=affiche le sous fichier; Attention si sous fichie vide, doit être false
// 30 : true= affiche le fmt de contrôle; false=vide le sous fichier
// 50 : bascule affichage / edition dans la fenêtre
// 90 : affiche le libellé appellation en rouge (cas delete)
//-------------------------------------------------------------------------
// Modifications
//-------------------------------------------------------------------------
// Task     Date     Programmeur    Description
//-------------------------------------------------------------------------

ctl-opt option(*nodebugio : *srcstmt) ACTGRP(*NEW) ALWNULL(*USRCTL)
    CCSID(*CHAR:*JOBRUN);

//juste pour le fun, ce n'est pas dans l'énoncé du TP
// voir le source modmsgs.rpgle pour la création de
// tools_bnd
ctl-opt bnddir('UTIL_BND');

//-------------------------------------------------------------------------
// déclaration des fichiers
//-------------------------------------------------------------------------
// Fichier écran
dcl-f mntinfocd workstn sfile(sflprd : prdRrn) infds(ecrDs);

// fichier infocentre
dcl-f infocentre disk usage(*input);

// on va utiliser l'index (par code producteur
dcl-f infocentl1 disk usage(*update:*delete) rename(infoc1:infocupd) prefix(u_);

//-------------------------------------------------------------------------
// déclaration des constantes
//-------------------------------------------------------------------------
dcl-c true *ON;
dcl-c false *OFF;

//-------------------------------------------------------------------------
// déclaration des structures
//-------------------------------------------------------------------------

//*    PSDS (ex SDS)  : informations sur le programme lui même *
dcl-ds PGM PSDS qualified;
    Name  *PROC; //char(10) pos(1)
    stsCode *STATUS;  //zoned(5:0) pos(11)
    //stsPrv  ZONED(5:0) POS(16);
    //numLigne ZONED(8:0) POS(21);
    routine *ROUTINE; //CHAR(8) POS(29);
    nbparms  *PARMS; //ZONED(3:0) POS(37);   //nombre de paramêtre reçus
    //mch_ou_cpf CHAR(3) POS(40);
    //errorcode CHAR(4) POS(43);
    //ligneMI   CHAR(4) POS(47);
    //message CHAR(30)  POS(51);
    //lib    CHAR(10) POS(81);
    //lastFile CHAR(10)  POS(201);
    //fileInfo CHAR(35) POS(209);
    //JOB CHAR(10)  POS(244);
    //user  CHAR(10) POS(254);
    //jobnbr     CHAR(6)    POS(264);
    //jobdaterun CHAR(6) POS(270);
    //pgmdaterun   CHAR(6) POS(276);
    //pgmheurerun  CHAR(6) POS(282);
    //date_crt   CHAR(6) POS(288);
    //heure_crt  CHAR(6) POS(294);
    //compilateur CHAR(4) POS(300);
    //fichier_src CHAR(10) POS(304);
    //bib_src  CHAR(10)    POS(314);
    //mbr_src  CHAR(10)    POS(324);
    //current_user CHAR(10)POS(358);
    //nb_element_xml_into INT(10) POS(372); // 7.3
    //Internal_job_ID CHAR(16) POS(380); // 7.4 ou PTF
    //system_name CHAR(8) POS(396); // 7.4 ou PTF
end-ds;

dcl-ds  ecrDs;
    // à l'instar de PSDS, les fichiers incorporés au programme par
    // dcl-f peuvent avoir une DS associée ...
    // ATTENTION, chaque type de fichier (DSPF, PRTF, PF, LF, ...)
    //     des données qui lui sont propres dans cette DS
    //     ex : un DSPF peut avoir des infors relatives aux sousfichiers
    //          un prtf peut avoir des infos relatives au dépassement
    //             de page
    //          etc.
    //
    //TODO: chercher dans la documentation les autres champs
    //      en étudiant les particularités de chaque type de fichier
    //      ...
    //      il y a peut être d'autres informations très intéressantes

    recno int(5) pos(378); // placé dans SFLRCNBR on réaffiche même page !
end-ds;
//-------------------------------------------------------------------------
// déclaration des variables (tableaux ou non)
//-------------------------------------------------------------------------
dcl-s possibleOpts char(1) dim(5);

dcl-s nenreg packed(5 : 0);


//-------------------------------------------------------------------------
// déclaration des modules
//-------------------------------------------------------------------------
/copy 'TPFINCORR/modmsgs.h.rpgleinc'

//---------------------------------------------
// Interface du programme principal
//---------------------------------------------
dcl-pi *n;
    Ropt char(1) const;
end-pi;

//******************************************************************
// programme
// A noter : on passe par des procs, au lieu d'exsr (c'est plus joli)
//******************************************************************
InitPgm();

//Vidage du sous fichier
clearSfl();
s_recno = 1;

//remplissage du sous fichier
// ici le sous fichier est en statique :
// on remplit tout  (max 9999 éléments), et on laisse
//     le système gérer la pagination AV/ARR

// >> lecture du fichier
read infocentre;
dow not %eof;
    writeSfl();
    read infocentre;
enddo;

SndMsgPgmQ(
    pgm.name :
    'CPF9898' :
    'QCPFMSG' :
    %char(prdRRN) + ' Enregs dans infocentre'
);

//affichage à l'écran
dow not *in03;
    affEcran();
enddo;


*inlr = true;

//******************************************************************************
// procédures
//******************************************************************************

//------------------------------------------------------------------------------
// déterminer le titre de l'écran principal enfonction de l'option reçue
//------------------------------------------------------------------------------
dcl-proc InitPgm;

    pgmnam = Pgm.Name;
    // on peut aussi passer par un "select case"
    if ropt = '2';
        Titre =  'Affichage des producteurs';
        ttOpt = '5=Afficher';
        //possibleOpts : liste des options possibles
        possibleOpts = %list('5');
    endif;
    if ropt = '3';
        titre =  'Maintenance des producteurs';
        ttOpt = '2=Modifier 3=Copier 4=Supprimer 5=Afficher';
        possibleOpts = %list('2':'3':'4':'5');
    endif;

end-proc;


//------------------------------------------------------------------------------
// détarminer le titre de l'écran principal enfonction de l'option reçue
//------------------------------------------------------------------------------
dcl-proc TitreFenetre;

    select;
        when sfopt = '2';
            winttl =  'Modification d''un producteur';
        when sfopt = '5';
            winttl = 'Affichage d''un producteur';
        when sfopt = '4';
            winttl = 'Suppression d''un producteur';
    endsl;

end-proc;


//------------------------------------------------------------------------------
// vidage du sous fichier
//------------------------------------------------------------------------------
dcl-proc clearSfl;

    // voir le source de l'écran:
    // N30 ...... SFLCLR
    // au write du format, si l'indicateur 30
    // est false, le sous fichier serra vidé
    *in30 = false;
    write ctlprd;
    //  30 ...... SFLDSPCTL + SFLEND
    *in30 = true;
    PrdRRN = 0;

end-proc;

//------------------------------------------------------------------------------
//écriture dans le sous fichier
//------------------------------------------------------------------------------
dcl-proc writeSfl;

    cdprod = pr_code;
    nmprod = pr_nom;
    nbcepa = nbcepage;
    //incrémentation du rrn du sous fichier
    PrdRRN += 1;
    //TODO: tester si le rrn n'arrive pas à la limite
    //      du sous fichier (voir dspf : 9999)
    write sflprd;

end-proc;


//------------------------------------------------------------------------------
// affichage et maintenance écran
//------------------------------------------------------------------------------
dcl-proc affEcran;

    //Attention : écriture pas très appréciée
    // IN31 est le résultat du test en 1 instruction
    // joli, mais implicite
    // if prdrrn > 0;
    //    *in31 = true;
    // else;
    //    *in31 = false;
    // endif;
    // + voir le source écran...
    //   31   ......... SFLDSP
    // faire très attention, ON NE PEUT PAS AFFICHER
    //     UN SOUS FICHIER VIDE
    *in31 = PRDRRN > 0;


    //ecran 'bidon' qui sert à nettoyer l'écran
    //  (fait parce que tous les autres formats sont en OVERLAY)
    write clrscr;

    // touches de fonction en bas de l'écran
    write fct;

    // sous fichier de messages du pgm.
    // ici, ne sert à rien, tant qu'on n'envoie pas de messages
    // dans la file d'attente.
    write msgctl;

    //affichage de l'entéte + sous fichier (*IN31)
    exfmt ctlprd;

    //on met le recno (issu de l'infds) dans s_recno (SFLRCDNBR du format DSPF)
    //pour réafficher la page du sous fichier dernièrement affichée
    s_recno = recno;

    // vider le sous fichier de messages
    ClrMsgPgmQ(pgm.name);

    //lecture du sous fichiers (options sélectionnées)
    readc sflprd;
    dow not %eof;

        //l'otion que l'utilisateur a tapé est-elle autorisée ?
        //TODO: gérer un message d'erreur
        if sfopt in possibleOpts;
            Titrefenetre();
            select;
                when sfopt = '5';
                    dspINfo();
                when sfopt = '2';
                    wrkInfo();
                when sfopt = '4';
                    dltInfo();
    //            when sfopt = '3';
    //                cpyInfo();
            endsl;
        endif;

        //mise à jour du sous fichier
        sfopt = '';
        update sflprd;

        // *in90 à false au cas où il y aurait eu une suppression
        *in90 =false;

        //lecture du suivant
        readc sflprd;
    enddo;

end-proc;


//**********************************
// procédure infocentre
//**********************************


//------------------------------------------------------------------------------
//lecture infocentre
//------------------------------------------------------------------------------
dcl-proc readInfo;
    dcl-pi *n;
        rprod like(pr_code) const;
    end-pi;

    chain rprod infocentl1;

    //champs fichier -> champs écran
    pr_nom = U_PR_NOM;
    pr_tel = u_pr_tel;

    // avec quelques transformations
    appelat = u_appel00001;

    nbrvins = u_nbrvins;

    incav = 'NON';
    if u_ENCAVE = 'O';
        incav = 'OUI';
    endif;

    cepage = u_cepage;
    nbcepage = u_nbcepage;

end-proc;


//------------------------------------------------------------------------------
//affichage simple des informations
//------------------------------------------------------------------------------
dcl-proc dspInfo;

    readInfo(cdprod);
    *in50 = true;
    exfmt detProd;

end-proc;


//------------------------------------------------------------------------------
//maintenance des informations
//------------------------------------------------------------------------------
dcl-proc wrkInfo;

    readInfo(cdprod);
    *in50 = false;

    dou (1=2);   //boucle infinie !!!!!

        exfmt detProd;

        if *in12;
            return;
        endif;

        if  *in09;

            // confirmation
            confmsg = 'Confirmez par ''O'' ou par ''N'' la modification';
            exfmt conf;
            if rep <> 'O';
                return;
            endif;

            chain cdprod infocupd;

            // je remplace les champs du fichier par les champs de l'écran
            u_pr_nom = pr_nom;
            u_pr_tel = pr_tel;
            u_appel00001 = appelat;
            u_nbrvins = nbrvins;
            if incav = 'OUI';
                u_encave = 'O';
            else;
                u_encave = 'N';
            endif;
            u_cepage = cepage;
            u_nbcepage = nbcepage;

            // mise à jour du fichier
            update infocupd;

            // un petit + :
            //modification de NMPROD et NBCEPA
            // par les valeurs de l'écran....
            // si on modifie ces valeurs, elles eront modifiées
            // dans le sous fichier
            NMPROD = pr_nom;
            NBCEPA = nbcepage;

            //message de confirmation
            SndMsgPgmQ(
                pgm.name :
                'CPF9898' :
                'QCPFMSG' :
                'Producteur ' + %char(CDPROD) + ' Modifié'
            );

            return;
        endif;

    enddo;

end-proc;

//------------------------------------------------------------------------------
//suppression des informations
//------------------------------------------------------------------------------
dcl-proc dltInfo;

    // confirmation
    confmsg = 'Confirmez la suppression par ''O'' ou par ''N''';
    exfmt conf;
    if rep <> 'O';
        return;
    endif;

    readInfo(cdprod);
    delete infocupd;

    NMPROD = '** supprimé ! **';
    *in90 = true;

    SndMsgPgmQ(
        pgm.name :
        'CPF9898' :
        'QCPFMSG' :
        'Producteur ' + %char(CDPROD) + ' Supprimé'
    );

end-proc;
