**free
      //%METADATA                                                      *
      // %TEXT Remplissage du sous fichier                             *
      //%EMETADATA                                                     *
dcl-f expinfo workstn sfile(fmtenr:rrn); // DECLARATION DE DSPF AVEC SOUS FICHIER POUR L'OPTION 2
dcl-s rrn packed(4);
dcl-f infocentre; // Déclaration de infocentre PF

setll 1 infocentre; // On se place à l'enregistrement 1 de infocentre

exsr rempli_sfl; // Appel de la sous routine
if rrn <> 0;
  exsr dsp_page1; // Si on a chargé au moins un enregistrement, on affiche l'écran principal
endif;


*inlr = *on;

// SOUS ROUTINE DE REMPLISSAGE DU SOUS FICHIER
begsr rempli_sfl;
  read infocentre; // On lit l'enregistrement
  dow not %eof;
    rrn = rrn +1;
    write fmtenr; // On écrit les infos dans le format sfl ou d'enregistrement
    // On a pas besoin de les spécifié car ils portent le même nom que les zone du PF et y font réfé
    read infocentre; // On lit l'enregistrement suivant
  enddo;
  *in34 = *on; // Indicateur pour afficher fin quand il est allumé
endsr;

// SOUS ROUTINE D'AFFICHAGE DU
begsr dsp_page1;
  write touches; // N'ATTEND PAS D'ACTION DE L'UTILISATEUR DONC NON BLOCANTE
  // Affiche la touche de commande F12

  exfmt fmtctl;  // ATTEND UNE ACTION DE L'UTILISATEUR
   // Affiche l'écran de contrôle (format écran FMTCTL) et attend la saisie utilisateur
endsr;



