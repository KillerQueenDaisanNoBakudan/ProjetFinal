**free
      //%METADATA                                                      *
      // %TEXT Read producteur file to write in infocentre             *
      //%EMETADATA                                                     *
ctl-opt option(*nodebugio:*srcstmt:*nounref) alwnull(*usrctl) actgrp(*new);

dcl-f producteur;
dcl-f appellatio keyed;
dcl-f infocentre usage(*output:*update);
dcl-f bdvinxlf keyed; // On a crée un LF des vins mais ayant une clé sur les producteurs
dcl-f cavelf keyed; // On a créé un LF des cave mais avec une clé sur les producteurs

dcl-s CEPAGE_PRINC varchar(50);
dcl-s cepages varchar(50) dim(4); // Declaration d'un tableau pour stocker les cépages étant réparti
dcl-s i int(5);
dcl-s j int(5);

dcl-s maxCompteur int(5);
dcl-s indexMax int(5);
dcl-s compteurCepage int(5);
dcl-s nbVinCpt int(5);

dcl-c MAX_CEPAGE 100; // Choix de cette valeur pour être sur d'avoir assez de place pour traiter les


// Structure de données CepageStats : tableau contenant les statistiques de cépages
// Chaque entrée contient un nom de cépage et le nombre de fois quil a été rencontré
dcl-ds CepageStats qualified dim(MAX_CEPAGE);
  Nom varchar(50); // Nom du cépage (ex : 'MERLOT', 'SYRAH'...), max 50 caractères
  Compteur int(5); // Compteur doccurrences pour ce cépage (ex : 3 si le cépage est apparu 3 fois)
end-ds;

// A - B - Lecture du fichier productueur pour écrire dans le fichier infocentre
setll *start producteur;
read producteur;
dow not %eof;
  // On initialise les variable à une valeur de base
  en_cave = 'N'; // Tout les en_cave sont à NON
  nbVinCpt = 0;
  for i = 1 to MAX_CEPAGE;
    CepageStats(i).Nom = '';
    CepageStats(i).Compteur = 0;
  endfor;
  maxCompteur = 0;
  indexMax = 0;
  compteurCepage =0;

  AppellationProc(); // procédure d'appellation

  setll pr_code bdvinxlf; // on se place sur le LF à la clé pr_code
  reade pr_code bdvinxlf; // Lit le prochain enregistrement dont la clé est égale à pr_code
  dow not %eof;
    // La clé sur pr_code du LF permet d'alimenter les procédure
    NbrvinProc(); // Appel de la procédure qui gère l'incrément du nombre de vin par producteur et l
    CepageProc(); // Appel de la procédure qui permet de récupérer les 4 colonne de cépage par produ
    reade pr_code bdvinxlf; // Lit lenregistrement suivant avec la même clé pr_code
  enddo;

  // COMPTAGE DU CEPAGE LE PLUS UTILISÉ PAR PRODUCTEUR
  for i = 1 to MAX_CEPAGE;
    if CepageStats(i).Compteur > maxCompteur; // Si le compteur du cépage actuel est strictement sup
      maxCompteur = CepageStats(i).Compteur; // On met à jour le maximum
      indexMax = i; // On conserve lindex du cépage qui a ce maximum
    endif;
  endfor;
  if indexMax > 0; // Après la boucle, si un cépage principal a été trouvé (indexMax > 0)
    CEPAGE_PRINC = %trim(CepageStats(indexMax).Nom); // On attribue à CEPAGE_PRINC le nom du cépage
  else;
    CEPAGE_PRINC = 'Inconnu';  // Sinon, on met 'Inconnu' par défaut (aucun cépage trouvé)
  endif;

  // COMPTAGE DU NOMBRE DE CEPAGE DIFFERENT PAR PRODUCTEUR
  for i = 1 to MAX_CEPAGE;
    if CepageStats(i).Nom <> ''; // Si une case du tableau contient un nom de cepage
      compteurCepage += 1; // On incrémente le compteur de cépage différent
    endif;
  endfor;

  // ECRITURE DANS INFOCENTRE DE CES TROIS DONNEE
  NBRVINS = nbVinCpt;
  cepage = %trim(CEPAGE_PRINC);
  nbcepage = compteurCepage;

  write INFOCF1; // On écrit les données dans infocentre
  read producteur; // On lit l'enregistrement suivant
enddo;
*inlr = *on;

// C - APPELLATION
dcl-proc AppellationProc;
  // On fait un select de l'appellation qu'on injecte dans la une variable appellation de la table/P
  exec sql
  select a.appel00001
    into :appel00001
    from appellation a
    where a.appel_code = :appel_code;


  if sqlcode <> 0;
    appel00001 = 'Pas d''appellation'; // gestion si pas trouvé
  endif;
end-proc;

// D - NOMBRE DE VIN PAR PRODUCTEUR
// E - NOMBRE DE VINS PAR PRODUCTEUR EN CAVE
dcl-proc NbrvinProc;
  nbVinCpt += 1; // Ici on compte le nombre de vin par producteur via le read fait dans la fonction

  // Vérifier si au moins un vin est en cave via le LF bdvinx avec une clé sur le producteur
  exec sql
    select count(*)
    into :en_cave
    from bdvinxlf v
    where pr_code = :pr_code
    and exists (
      select 1 from cavelf c
      where c.vin_code = v.vin_code
    );

  // Si on trouve au moins un vin en cave on passe en cave dans Infocentre à OUI
  if en_cave > 0;
    en_cave = 'O';
  endif;
end-proc;

// F - CEPAGE + NBCEPAGE
dcl-proc CepageProc;
  dcl-s trouve ind; // Booléen pour savoir si un vin est trouvé

  // remplit cepages à partir de 4 colonne (vin_c00001 à vin_c00004) dans le PF producteurs
  cepages(1) = %upper(%trim(vin_c00001));
  cepages(2) = %upper(%trim(vin_c00002));
  cepages(3) = %upper(%trim(vin_c00003));
  cepages(4) = %upper(%trim(vin_c00004));

  // Compter les cépages
  for i = 1 to 4;
    if cepages(i) <> ''; // Si la case contient un cépage (non vide)
      trouve = *off; // On part du principe que ce cépage na pas encore été comptabilisé
      for j = 1 to MAX_CEPAGE; // Parcours du CepageStat pour vérifier si ce cépage existe déjà
        if CepageStats(j).Nom = cepages(i); // Si le cépage courant existe déjà dans les statistique
          CepageStats(j).Compteur += 1; // Incrémentation du compteur pour ce cépage
          trouve = *on; // Marque qu'on a trouvé ce cépage (pour ne pas le rajouter une 2e fois) dan
          leave;
        endif;
      endfor;

      if not trouve; // Si le cépage na pas encore été rencontré jusquici
        for j = 1 to MAX_CEPAGE;  // Recherche dun emplacement vide dans le tableau des statistique
          if CepageStats(j).Nom = ''; // Si la case est vide (première disponible)
            CepageStats(j).Nom = cepages(i); // On enregistre le nouveau nom de cépage ici
            CepageStats(j).Compteur = 1;  // Initialisation du compteur à 1 (première apparition)
            leave;
          endif;
        endfor;
      endif;
    endif;
  endfor;
end-proc;

