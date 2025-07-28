      --%METADATA                                                      *
      -- %TEXT script création infocentre full sql                     *
      --%EMETADATA                                                     *
-- rappel de l'exercice demandé
-- fichier infocentre:
-- PR_CODE (code producteur, table PRODUCTEURS)
-- PR_NOM  (Nom producteurs, table PRODUCTEURS)
-- PR_TEL (tel producteurs)
-- APPELLATIONS (0 ou 1 appellation par producteur, table appellations)
-- NBRVINS (nombre de VINS produits par le producteur)
-- ENCAVE  (O si AU MOINS 1 vin de ce producteur existe dans MA_CAVE, 'N' sinon)
-- CEPAGE  (Nom du cépage le plus utilisé dans les vins de ce producteur)
-- NBCEPAGES (nombre total de cépages cultivés par ce producteur)

set schema bdvine;
drop table qtemp.infocentre;

create table qtemp.infocentre as
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
    -- phase 2 : classement de nombre d'utilisation
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
    -- exgraction des vins dans MA_CAVE
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
        ) as NBCEPAGEs

        from producteurs left
            join appellations
                on producteurs.appel_code = appellations.appel_code
) with data
;



-- vérifications

select * from qtemp.infocentre
;
where encave = 'O'
;


select 'in', vin_code
from ma_cave
where vin_code in(
    select vin_code from vins where pr_code = 558
)
union
select 'join', v.vin_code
from ma_cave c join
    vins v on c.vin_code = v.vin_code
where v.pr_code = 558
;
