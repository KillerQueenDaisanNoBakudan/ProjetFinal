**free
      //%METADATA                                                      *
      // %TEXT Remplissage du sous fichier                             *
      //%EMETADATA                                                     *

// PROGRAMME POUR L'OPTION 3
ctl-opt option(*nodebugio:*srcstmt);

dcl-f expinfopt3 workstn sfile(fmtenr:rrn); // DECLARATION DE SOUS FICHIER
dcl-s rrn like(rang);
dcl-s rrnSave like(rang);
dcl-f infocentre usage(*update:*delete); // Déclaration en update et delete


dcl-s codSave like(pr_code);

// Variables utilisé pour les requête sql
dcl-s copy_code like(pr_code);
dcl-s copy_name like(pr_nom);
dcl-s copy_tel like(pr_tel);
dcl-s copy_appel like(appel1);
dcl-s copy_nbrvins like(nbrvins);
dcl-s copy_en_cave like(en_cave);
dcl-s copy_cepage like(cepage);
dcl-s copy_nbcepage like(nbcepage);

dcl-s command char(50);

write touches;

dow not *in12;
  setll 1 infocentre; // On se place au premier enregistrement
  exsr rempli_sfl; // Appel de la sous routine
  rang = 1;
  if rrn <> 0; // Si un enregistrement est trouvé
    exsr dsp_page1; // Appel de la sous routine pour afficher le dspf
    if *in12;
      exsr sortie;
    endif;
    dow not *in12;
      select;
      when *in12;
        exsr sortie;
      when *in38; // Quand on pagine via ROLLUP dans le dspf
        exsr rempli_sfl; // On mets à jour avec les enregistrement suivant
        rang = rrn; // Met à jour le rang courant avec la position actuelle
      other;
        exsr lectureOption; // Appelle la sous-routine pour traiter les options de l'utilisateur
        rang = hautpage; // Met à jour le rang avec la valeur en haut de page
      endsl;
      exsr dsp_page1; // Réaffiche la page avec les éventuelles modifications
    enddo;
    exsr clear_sfl; // Nettoie la sous-fenêtre (supprime les enregistrements affichés)
  endif;


  write touches;
enddo;
*inlr = *on;



begsr rempli_sfl;
  rrn = rrnSave;
  read(n) infocentre; // Lecture de l'enregistrement courant 'infocentre' sans verrouillage
  dow not %eof;
    rrn = rrn +1; // On incrémente le numéro relatif de ligne
    write fmtenr; // On écrit une ligne dans le (SFL) avec le format denregistrement 'fmtenr'
    read infocentre; // On lit l'enregistrement suivant du fichier 'infocentre'
  enddo;
  *in34 = *on; // On active l'indicateur 34, pour afficher suivant ou fin
  codSave = pr_code; // codSave pour permettre de récupérer le bon pr_code pour la paginat
  rrnSave = rrn; // rrnSave  pour permettre de récupérer le bon
endsr;

begsr clear_sfl;
  reset rrn; // Réinitialise le champ 'rrn' à zéro ou à sa valeur initiale
  reset rrnSave; // Réinitialise la variable 'rrnSave'
  reset codSave; // Réinitialise la variable 'codSave'
  reset *in34; // Réinitialise l'indicateur 34
  *in30 = *on; // Active l'indicateur 30
  write fmtctl; // Écrit le format de contrôle 'fmtctl'
  *in30 = *off; // Désactive l'indicateur 30
endsr;

begsr dsp_page1;
  *in32 =*on;
  exfmt fmtctl;  // Affiche le format de controle
  *in32 = *off;
endsr;

begsr sortie;
  *inlr = *on;
  return;
endsr;

begsr lectureOption;
  if *in06;
    exsr createProd; // Appel du sous-programme createProd pour créer un nouveau producteur
  endif;
  readc fmtenr; // Lecture conditionnelle du premier enregistrement sélectionné dans le SFL
  dow not %eof;
    select;
    // OPTION 5 = AFFICHAGE DETAILS
    when opt = '5'; // TO-DO : METTRE DANS UNE PROC OU SR
      chain(n) pr_code infocentre; // Recherche du producteur dans infocentre via pr_code
      if %found;
        appel1 = appel00001; // Affectation à appel1 car celui en BDD trop long
        exfmt details; // Affichage de la fenêtre détails
      endif;
    // OPTION 2 = MODIFIER
    when opt = '2'; // TO-DO : METTRE DANS UNE PROC OU SR
      *in70 = *off;
      monitor; // On surveille une erreur potentielle
        chain pr_code infocentre; // Recherche du producteur dans infocentre
      on-error 1218; // vérifie que le fichier soit déjà ouvert
        *in80 = *on;
        exfmt details;// On affiche lécran détail pour informer lutilisateur
        *in80 = *off;
      endmon;
      if %found;
        *in70 = *on; // On active un indicateur pour autoriser la modification
        exfmt details;
        dow not *in12 and not *in09; // Tant quon na pas appuyé sur F12 ou F9
          exfmt details; // On reste sur lécran détail
        enddo;
        if *in09; // si F9 est pressé
          update infocf1; // Mise à jour des données dans infocentre
          unlock infocentre; // Déverrouillage de l'enregistrement
        elseif *in12;
          chain pr_code infocentre; // Recharge lenregistrement sans le modifier
          unlock infocentre;
        endif;
        unlock infocentre;
      endif;

    // OPTION 4 = SUPPRIMER
    when opt = '4'; // TO-DO : METTRE DANS UNE PROC OU SR
      exfmt delete; // Affiche l'écran de confirmation de suppression
      if not *in12; // Si l'utilisateur n'a pas appuyé sur F12 => confirme la suppression)
        // Supprime l'enregistrement dans  `infocentre` correspondant au `pr_code` courant
        exec sql
          delete
          from infocentre
          where pr_code = :pr_code;
        // Valide la suppression dans la base de données
        exec sql
        commit;

        // Change localement les valeur et la couleur pour indiquer qu'il a été supprimé
        pr_nom = '***Producteur supprimé***';
        pr_code = 0;
        nbcepage = 0;
        *in55 = *on; // Active un indicateur qui passe le nom en rouge et protège la zone opt
      endif;
      unlock infocentre;

    when opt = '3';
      // Selection du max pr_code incrémenté de 1 et stocké dans une variable
      exec sql
      select max(pr_code) + 1 into :copy_code from infocentre;

      // Selection des donnée et ajout dans des variables en fonction du pr_code actuel
      exec sql
        select pr_nom, pr_tel, appellation, nbrvins, en_cave, cepage, nbcepage
        into :copy_name, :copy_tel, :copy_appel, :copy_nbrvins, :copy_en_cave, :copy_cepage,
         :copy_nbcepage
        from infocentre where pr_code = :pr_code;

      // Insertion dans la base de données en utilisant les variables
      exec sql
       insert into infocentre
       values (:copy_code,:copy_name, :copy_tel, :copy_appel, :copy_nbrvins, :copy_en_cave,
               :copy_cepage, :copy_nbcepage);

      // Commit pour valider les changement
      exec sql
          commit;
      snd-msg *status 'Enregistrement copié' %target(*EXT);
    endsl;

    reset opt; // Effacer opt pour le remettre à blanc
    update fmtenr; // Mise à jour du format SFL
    // On éteint les 3 indicateurs
    *in70 = *off;
    *in55 = *off;
    *in06 = *off;

    readc fmtenr;

    unlock infocentre;
  enddo;

  setgt codSave infocentre;
endsr;

begsr createProd;
  exfmt create; // Affichage du format de création
  if not *in12;
    // Selection du max pr_code incrémenté de 1 et stocké dans une variable
    exec sql
          select max(pr_code) + 1 into :copy_code from infocentre;
    // Insertion dans la table avec champs obtenu de la fenêtre
    exec sql
      insert into infocentre
      values (
        :copy_code,
        :pr_nom,
        :pr_tel,
        :appel2,
        :nbrvins,
        upper(:en_cave),
        :cepage,
        :nbcepage
      );
    // Commit pour valider les changement
    exec sql
        commit;
     snd-msg *status 'Enregistrement créé' %target(*EXT);
      command = 'DLYJOB DLY(' + %trim(%char(3)) + ')';
      exec sql call qsys2.qcmdexc(:command);

  endif;

endsr;






