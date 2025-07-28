**free
      //%METADATA                                                      *
      // %TEXT création infocentre avec du SQL dedans                  *
      //%EMETADATA                                                     *
//---------------------------------------------
// Programme.......:FILLINFO2
// Description.....:traitement infocentre
//                  AVEC du SQL DEDANS
//---------------------------------------------

//-------------------------------------------------------------------------
// Modification logs
//-------------------------------------------------------------------------
// Task     Date     Programmeur    Description
//-------------------------------------------------------------------------
// 1C                               Ajout de APPEL00001
//                                  et recherche dans le fichier
//                                  'appellations' (appellatio en RPG)
// 1D                               Ajout de NBRVINS
//                                  recherche et comptage des vins du
//                                  producteur
// 1E / 1Ev                         Ajout de ENCAVE
//                                  et recherche si on a ce vin en cave
//                                  variante par appel de procédure
// 1F                               Ajout de CEPAGE/NBCEPAGE
//                                  récupération de cépage le plus utilisé
//                                  par le producteur dans tous ses vins
//                                  résultat dans CEPAGE,
//                                  et compage du nombre de cépages différents
//                                  résultat dans NBCEPAGE
//                                  traitement dans une procédure
// 1H                               modification du traitement en SQL:
//                                  - si au moins 1 vin est en cave
//                                  - recherche appellation
//-------------------------------------------------------------------------

ctl-opt option(*nodebugio : *srcstmt) ACTGRP(*NEW) ALWNULL(*USRCTL)
    CCSID(*CHAR:*JOBRUN);

dcl-f producteur disk;

dcl-f infocentre disk usage(*output);

//1C - ajout du fichier appellations
//1H - plus besoin de dcl-f (passage SQL)
//dcl-f appellatio disk usage(*input);

//1D - ajout du fichier des vins
dcl-f vini1 disk keyed usage(*input);

//1E - ajout du fichier CAVE
//1H - plus besoin de cave (passage SQL)
dcl-f cavei1 disk keyed usage(*input);


//1F structure tableau pour compter les cépages
dcl-ds cepages dim(50) qualified;
    cep like(CEPAGE);
    nbcep like(NBCEPAGE);
end-ds;

// 1F compteur !!! A ne jamais faire!!!!
//    jamais de zones i, e, a, b ....
//    c'est une vraie galère après pour rechercher
//    la zone dans un programme de plusieurs pages...
//    ayez toujours en mémoire le psychopathe
dcl-s i like(nbcepage);

//1H varaible servant de comptage des vins en cave
dcl-s vinsencave packed(10);

//-------------------------------------------------------------------------
//démarrage de la lecture
read producteur;
// tant qu'on n'est pas arrivé en fin du fichier
dow not %eof;

    //1F initialisations pour une nouveau producteur
    clear cepages;
    //1E
    encave = 'N';
    //fin 1E
    nbrvins = 0;


    //1H - code en commentaire (lecture par SQL)
    //1C - recherche de l'appellation
    //chain appel_code appelf;
    //if not %found;
    //    appel00001 = 'non trouvé';
    //endif;
    //fin 1C


    EXEC SQL
        select
            coalesce(appellation, 'non trouvé') into :APPEL00001
        from
            appellations
        where
            appel_code = :APPEL_CODE
        ;
    //fin 1H

    //1D recherche et comptage des vins du producteur
    setll pr_code vini1;

    reade pr_code vini1;
    dow not %eof;
        nbrvins += 1;

        //1H - mise en commentaire (requête SQL)
        //1E recherche si un vin est dans ma cave
        //1Ev   variante : appel de la procédure
        //if isEnCave(vin_code);
        //    encave = 'O';
        //endif;
        //fin 1E
        //fin 1H

        //1F appel de la procédure de comptage
        compte_cepage(VIN_C00001);
        compte_cepage(VIN_C00002);
        compte_cepage(VIN_C00003);
        compte_cepage(VIN_C00004    );

        reade pr_code vini1;
    enddo;
    //fin 1D

    //1H requête SQL pour savoir s on a AU MOINS
    //   1 vin de ce producteur dans notre cave
    EXEC SQL
        select count(*) into :vinsencave
        from
            vins
            join ma_cave using(vin_code)
        where
            vins.pr_code = :pr_code
    ;
    if vinsencave > 0;
        encave = 'O';
    endif;
    //fin 1H

    //1F récupération du cépage le plus utilisé
    sorta(d) cepages(*).nbcep;
    cepage = cepages(1).cep;

    //nombre de cépages différents
    for i = 1 to %elem(cepages);
        if cepages(i).cep = *blanks;
            leave;
        endif;
    endfor;
    nbcepage = i - 1;

    //identique au bloc for précédent:
    // recherche de la première occurence à blanc -1
    // !!!!!!!!!!!!!!!!!!      on peut commenter l'un des 2 blocs
    nbcepage = %lookup(*blanks:cepages(*).cep) - 1;

    // fin 1F

    //écriture dans infocentre
    write infoC1;

    //enregistrement suivant
    read producteur;
enddo;

//quand tout est terminé, on sort du programme
*inlr = '1';


//1H la procédure n'a plus lieu d'être : mise en commentaires
//**************************************************************************
// 1Ev Variante : procédure
//**************************************************************************
//dcl-proc isEnCave;
    //interface de la procédure
    //paramêtre(s) en entrée:
    //   rvin : code du vin
    //en sortie :
    //    indicateur *ON/*OFF selon que le code existe en cave ou non
//    dcl-pi *n ind;
//        rvin like(vin_code) const;
//    end-pi;

//    chain rvin cavei1;
//    return %found;

//end-proc;
//fin 1H


//**************************************************************************
// 1F procédure de traitement des cépages
//**************************************************************************
dcl-proc compte_cepage;
    //interface
    //paramêtre(s) en entrée:
    //   rcepage : nom du cépage
    dcl-pi *n;
        rcepage like(cepage) const;
    end-pi;
    dcl-s indx like(nbcepage);


    //si cépage reçu = '', on ne fait rien
    if rcepage = *blanks;
        return ;
    endif ;

    //recherche du cépage dans le tableau
    indx = %lookup(rcepage : cepages(*).cep) ;

    if indx > 0;

        // Cépage existe dans le tableau: incrément du nombre
        cepages(indx).nbcep += 1;

    else;

        // Cépage n'existe pas : ajout dans le tableau
        indx = %lookup(*blanks : cepages(*).cep) ;
        cepages(indx).cep = rcepage;
        cepages(indx).nbcep = 1;

    endif;
end-proc;
