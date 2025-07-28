(*write**free
//---------------------------------------------
// Programme.......:PRTINFOC
// Description.....:Impression de l'infocentre
// Creation Date.: 2024-06-29
// Create by.....:
//---------------------------------------------

//liste des indicateurs
// 90 : débordement de page : on imprime une nouvelle page

ctl-opt option(*nodebugio:*srcstmt)
        alwnull(*usrctl);

//Fichiers en lecture
dcl-f infocentre keyed;

//Fichier en écriture
dcl-f prtinfocp   printer OFLIND(*IN90) ;

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
    //Name  *PROC; //char(10) pos(1)
    //stsCode *STATUS;  //zoned(5:0) pos(11)
    //stsPrv  ZONED(5:0) POS(16);
    //numLigne ZONED(8:0) POS(21);
    //routine *ROUTINE; //CHAR(8) POS(29);
    //nbparms  *PARMS; //ZONED(3:0) POS(37);
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
    current_user CHAR(10)POS(358);
    //nb_element_xml_into INT(10) POS(372); // 7.3
    //Internal_job_ID CHAR(16) POS(380); // 7.4 ou PTF
    //system_name CHAR(8) POS(396); // 7.4 ou PTF
end-ds;

//Traitement principal


// Init des compteurs
clear TOTALF ;

// Impression de l'entête de la première page
PUSER = pgm.current_user ;
write PAGEF ;

//Lecture du fichier infocentre
read  infocentre ;
dow not %eof;

  //Incrémentation du compteur du nombre de producteur et nombre de vins
  NBTOTPROD += 1 ;
  NBTOTVINS += NBRVINS ;

  // Saut de page ? *in90 est mis automatiquement à *ON
  if *in90 ;
    write PAGEF ;
    *in90 = false ;
  endif ;

  // Impression du producteur
  write LIGNEF ;

  //lecture du producteur suivant
  read  infocentre;

enddo;

// Impression du total après un saut de page
write PAGEF ;
write TOTALF ;
// sortie du programme
*inlr = true ;
