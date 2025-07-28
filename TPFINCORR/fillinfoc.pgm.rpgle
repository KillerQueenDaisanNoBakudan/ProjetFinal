**free
      //%METADATA                                                      *
      // %TEXT création infocentre FULL natif                          *
      //%EMETADATA                                                     *
//---------------------------------------------
// Programme.......:FILLINFOC
// Description.....:traitement infocentre
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
//-------------------------------------------------------------------------

ctl-opt option(*nodebugio : *srcstmt) ACTGRP(*NEW) ALWNULL(*USRCTL)
    CCSID(*CHAR:*JOBRUN);

dcl-f producteur disk;

dcl-f infocentre disk usage(*output);

//1C - ajout du fichier appellations
dcl-f appellatio disk usage(*input) keyed;

//1D - ajout du fichier des vins
dcl-f vini1 disk keyed usage(*input);

//1E - ajout du fichier CAVE
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

    //1C - recherche de l'appellation
    chain appel_code appelf;
    if not %found;
        appel00001 = 'non trouvé';
    endif;
    //fin 1C

    //1D recherche et comptage des vins du producteur
    setll pr_code vini1;

    reade pr_code vini1;
    dow not %eof;
        nbrvins += 1;

        //1E recherche si un vin est dans ma cave
        //1Ev   variante : appel de la procédure
        if isEnCave(vin_code);
            encave = 'O';
        endif;
        //fin 1E

        //1F appel de la procédure de comptage
        compte_cepage(VIN_C00001);
        compte_cepage(VIN_C00002);
        compte_cepage(VIN_C00003);
        compte_cepage(VIN_C00004    );

        reade pr_code vini1;
    enddo;
    //fin 1D

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
    nbcepage = %lookup(*blanks:cepages(*).cep) - 1;

    // fin 1F

    //écriture dans infocentre
    write infoC1;

    //enregistrement suivant
    read producteur;
enddo;

//quand tout est terminé, on sort du programme
*inlr = '1';


//**************************************************************************
// 1Ev Variante : procédure
//**************************************************************************
dcl-proc isEnCave;
    //interface de la procédure
    //paramêtre(s) en entrée:
    //   rvin : code du vin
    //en sortie :
    //    indicateur *ON/*OFF selon que le code existe en cave ou non
    dcl-pi *n ind;
        rvin like(vin_code) const;
    end-pi;

    chain rvin cavei1;
    return %found;

end-proc;


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
