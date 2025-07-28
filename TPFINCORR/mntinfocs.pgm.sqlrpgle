**free
      //%METADATA                                                      *
      // %TEXT maintenance infocentre;dynamique;SQL                    *
      //%EMETADATA                                                     *
//---------------------------------------------
// Programme.......:MNTINFOCS
// Description.....:Maintenance de l'infocentre
//                  identique à MNTINFOC mais avec
//                  du SQL
// Creation Date.: 2024-06-29
// Create by.....:
//---------------------------------------------

//liste des indicateurs
// 03 : F3
// 12 : F12
// 31 : true=affiche le sous fichier; Attention si sous fichie vide, doit être false
// 30 : true= affiche le fmt de contrôle; false=vide le sous fichier
// 50 : bascule affichage / edition dans la fenêtre
// 61 : rollup (page suivante)
// 62 : rolldown (page précédente)
// 90 : affiche le libellé appellation en rouge (cas delete)
//-------------------------------------------------------------------------
// Modifications
//-------------------------------------------------------------------------
// Task     Date     Programmeur    Description
//-------------------------------------------------------------------------

ctl-opt option(*nodebugio : *srcstmt) ACTGRP(*NEW) ALWNULL(*USRCTL)
    CCSID(*CHAR:*JOBRUN)
    bnddir('UTIL_BND');

//-------------------------------------------------------------------------
// déclaration des fichiers
//-------------------------------------------------------------------------
// Fichier écran
//MNTINFOCS : on proend le dspf MNTINFOCSD
dcl-f mntinfocsd workstn sfile(sflprd : prdRrn) infds(ecrDs);

// fichier infocentre
// MNTINFOCS plus besoin, on passe par SQL
//dcl-f infocentre disk usage(*input);

// on va utiliser l'index (par code producteur
// MNTINFOCS ... SQL
//dcl-f infocentl1 disk usage(*update:*delete) rename(infoc1:infocupd) prefix(u_);

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
    nbparms  *PARMS; //ZONED(3:0) POS(37);
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
    //TODO: chercher dans la documentation les autres champs
    //      il y a peut être d'autres informations très intéressantes

    //MNTINFOCS : plus besoin, car sous fichier dynamique
    //recno int(5) pos(378); // placé dans SFLRCNBR on réaffiche même page !
end-ds;
//-------------------------------------------------------------------------
// déclaration des variables (tableaux ou non)
//-------------------------------------------------------------------------
dcl-s possibleOpts char(1) dim(5);

dcl-s nenreg packed(5 : 0);

// MNTINFOCS
// Numéro de page du sous fichier
dcl-s sflpage int(10) inz(1);
dcl-c limit 14;

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
//s_recno = 1;

//remplissage du sous fichier
FillSfl(sflpage);

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


    exec sql
        Set Option
            DATFMT = *ISO,
            CLOSQLCSR = *ENDMOD,
            COMMIT = *NONE
    ;

    exec sql
        set schema EF
    ;

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
        when sfopt = '3';
            winttl = 'Copie d''un producteur';
        endsl;

end-proc;

//------------------------------------------------------------------------------
// Remplissage du sous fichier par SQL
//------------------------------------------------------------------------------
dcl-proc FillSfl;
    dcl-pi *n like(sflpage);
        rpage like(sflpage)  const;
    end-pi;

dcl-s offset                     int(10);
    dcl-s wpage like(rpage);

    wpage = rpage;
    if wpage <= 0;
        wpage = 1;
    endif;

    // offset commence à 0.
    // rpage = 1 -> offset = 0, (page 1 : éléments 0 à 13)
    // rpage = 2 -> offset = 14 (page 2 : éléments 14 à 27)
    // etc.
    offset = ((wpage -1) * limit) ;

    // vidage du sous fichier
    clearsfl();


    exec sql
        declare curs cursor for
            select
                PR_code,
                pr_nom,
                nbcepage
            from infocentre
            limit :limit
            offset :offset
    ;

    exec sql
        open curs
    ;

    dow sqlcode = *zeros;
        exec sql
            fetch next from curs into
                :cdprod,
                :nmprod,
                :NBCEPA
        ;
        if sqlcode = *zeros;
            writeSfl();
        endif;
    enddo;

    exec sql
        close curs;

    return wpage;
end-proc;




//------------------------------------------------------------------------------
// vidage du sous fichier
//------------------------------------------------------------------------------
dcl-proc clearSfl;

    *in30 = false;
    write ctlprd;
    *in30 = true;
    PrdRRN = 0;

end-proc;

//------------------------------------------------------------------------------
//écriture dans le sous fichier
//------------------------------------------------------------------------------
dcl-proc writeSfl;

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
    *in31 = PRDRRN > 0;


    //ecran 'bidon' qui sert à nettoyer l'écran
    //  (fait parce que tous lesautres formats sont en OVERLAY)
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
    //MNTINFOCS plus la peine : sous fichier dynamique
    //s_recno = recno;

    // vider le sous fichier de messages
    ClrMsgPgmQ(pgm.name);

    //MNTINFOCS : on étudie les touches de fonction
    if *in61;     //rollup - page suivante
        sflpage = FillSfl(sflpage + 1);
        return;
    endif;

    if *in62;     //rolldown - page précédente
        sflpage = FillSfl(sflpage - 1);
        return;
    endif;

    //si pas de touches de fonction, aors entrée : on lit les
    // enregistrements du sous fichier qui ont été modifiés
    // ici : option saisie.

    //lecture du sous fichiers (options sélectionnées)
    readc sflprd;
    dow not %eof;

        //l'otion que l'utilisateur a tapé est-elle autorisée ?
        //TODO: gérer un message d'erreur
        if sfopt in possibleOpts;
            Titrefenetre();
            select;
                when sfopt = '5';
                    dspINfo(cdprod);
                when sfopt = '2';
                    wrkInfo(cdprod);
                when sfopt = '4';
                    dltInfo(cdprod);
                when sfopt = '3';
                    cpyInfo();
            endsl;
        endif;

        //mise à jour du sous fichier
        reset sfopt;
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
        rprod like(cdprod) const;
    end-pi;

    exec sql
        select
            pr_nom,
            pr_tel,
            appellation,
            nbrvins,
            case encave
                when 'O' then 'OUI'
                when 'N' then 'NON'
            end,
            cepage,
            nbcepage
        into
            :pr_nom,
            :pr_tel,
            :appelat,
            :nbrvins,
            :incav,
            :cepage,
            :nbcepage
        from infocentre
        where
            pr_code = :rprod
    ;

end-proc;


//------------------------------------------------------------------------------
//affichage simple des informations
//------------------------------------------------------------------------------
dcl-proc dspInfo;
     dcl-pi *n;
        rprod like(cdprod) const;
    end-pi;

    readInfo(rprod);
    *in50 = true;
    exfmt detProd;

end-proc;


//------------------------------------------------------------------------------
//maintenance des informations
//------------------------------------------------------------------------------
dcl-proc wrkInfo;
    dcl-pi *n;
        rprod like(cdprod) const;
    end-pi;

    readInfo(rprod);
    *in50 = false;

    dou (1 = 2);

        exfmt detProd;

        if *in12;
            return;
        endif;
        if  *in09;
            exec sql
                update infocentre
                set (
                    pr_nom,
                    pr_tel,
                    appellation,
                    nbrvins,
                    encave,
                    cepage,
                    nbcepage
                )
                =
                (
                    :pr_nom,
                    :pr_tel,
                    :appelat,
                    :nbrvins,
                    case :incav
                        when 'OUI' then 'O'
                        When 'NON' then 'N'
                    end,
                    :cepage,
                    nbcepage
                )
                where pr_code = :rprod
            ;


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
    dcl-pi *n;
        rprod like(cdprod) const;
    end-pi;
    //TODO: A faire : afficher la fenere pour confirmer

    exec sql
        delete from infocentre
        where pr_code = :rprod
    ;
    NMPROD = '** supprimé ! **';

    *in90 = true;
    SndMsgPgmQ(
        pgm.name :
        'CPF9898' :
        'QCPFMSG' :
        'Producteur ' + %char(CDPROD) + ' Supprimé'
    );

end-proc;


//------------------------------------------------------------------------------
//maintenance des informations
//------------------------------------------------------------------------------
dcl-proc cpyInfo;
    dcl-pi *n;
        rprod like(pr_code) const;
    end-pi;

    dcl-s newCode like pr_code;

    readInfo(rprod);
    *in50 = false;

    dou (1 = 2);

        exfmt detProd;

        if *in12;
            return;
        endif;

        if  *in09;
            exec sql
                select
                    max(pr_code) + 1
                    into :newCode
                from
                    infocentre
            ;

            exec sql
                insert into infocentre
                (
                    pr_code,
                    pr_nom,
                    pr_tel,
                    appellation,
                    nbrvins,
                    encave,
                    cepage,
                    nbcepage
                )
                values
                (
                    :newCode,
                    :pr_nom,
                    :pr_tel,
                    :appelat,
                    :nbrvins,
                    case :incav
                        when 'OUI' then 'O'
                        When 'NON' then 'N'
                    end,
                    :cepage,
                    nbcepage
                )
            ;

            //message de confirmation
            SndMsgPgmQ(
                pgm.name :
                'CPF9898' :
                'QCPFMSG' :
                'Producteur ' + %char(rprod) + ' copié en ' + char(newCode)
            );
            return;
        endif;

    enddo;

end-proc;
