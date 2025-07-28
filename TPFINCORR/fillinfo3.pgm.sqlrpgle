**free
      //%METADATA                                                      *
      // %TEXT création infocentre FULL SQL                            *
      //%EMETADATA                                                     *
//---------------------------------------------
// Programme.......:FILLINFO3
// Description.....:traitement infocentre
//                  AVEC QUE du SQL DEDANS
//---------------------------------------------

//-------------------------------------------------------------------------
// Modification logs
//-------------------------------------------------------------------------
// Task     Date     Programmeur    Description
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------

ctl-opt option(*nodebugio : *srcstmt) ACTGRP(*NEW) ALWNULL(*USRCTL)
    CCSID(*CHAR:*JOBRUN);

exec SQL
    set option commit=*none,
    naming=*sys ;


exec SQL
    set schema bdvin8;
exec sql
    drop table if exists ef.infocentre;
exec sql
    create table ef.infocentre as
    (
        -- phase 1 : latéralisation des colonnes
        --           cepage1, cepage2n cepage3, cepage4
        with cepage_producteurs as
        (
        select vins.pr_code, c.cepage
            from vins,
            lateral (
                values
                (vin_cepage1),
                (vin_cepage2),
                (vin_cepage3),
                (vin_cepage4)
            ) as c(cepage)
            where c.cepage is not null
            --group by vins.pr_code, c.cepage
            order by vins.pr_code
        ),

        -- phase 2 : classement de nombre d''utilisation
        --           des cépges sélectionnés
        cepages_classement as(
            select pr_code, cepage,
                count(*) as nb_utilisation,
                rank() over(
                    partition by pr_code
                    order by count(*) desc,
                    cepage) as classement
            from cepage_producteurs
            group by pr_code, cepage
            order by pr_code
        ),

        -- phase 3 : récupération du cépage
        --           le plus utilisé (1er au classement)
        cepage_plus_utilise as(
            select pr_code, cepage
            from cepages_classement
            where classement = 1
            group by pr_code, cepage
        ),

        -- extraction des vins dans MA_CAVE
        vins_en_cave as(
            select producteurs.pr_code, vins.vin_code
            from producteurs join
                vins join ma_cave
                    on vins.vin_code = ma_cave.vin_code
                on producteurs.pr_code = vins.pr_code
        )

        -- REQUETE : récupération des informations des
        --           sous requètes précédentes
        SELECT
            producteurs.Pr_CODE,
            producteurs.PR_NOM,
            producteurs.PR_TEL,
            coalesce(
                appellations.appellation,
                'Non trouvé'
            ) AS APPELLATION,
            (
                SELECT COUNT(*)
                FROM vins
                WHERE vins.pr_code = producteurs.pr_code
            ) AS NBRVINS,
            coalesce(
                (
                    select 'O'
                    from vins_en_cave
                    where producteurs.pr_code = vins_en_cave.pr_code
                    limit 1
                ),
                'N'
            ) as ENCAVE,
            (
                select cepage
                from cepage_plus_utilise
                where producteurs.pr_code = cepage_plus_utilise.pr_code
            ) as CEPAGE,
            (
                select count(distinct cepage)
                from cepage_producteurs
                where producteurs.pr_code = cepage_producteurs.pr_code
            ) as NBCEPAGE

            from producteurs left
                join appellations
                    on producteurs.appel_code = appellations.appel_code
    ) with data
    rcdfmt infoc1
;

exec sql
    create unique index ef.infocentl1
    ON ef.infocentre(PR_code)
;

*inlr = *on;
