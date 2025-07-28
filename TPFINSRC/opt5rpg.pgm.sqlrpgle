**free
      //%METADATA                                                      *
      // %TEXT PGM pour le prtf                                        *
      //%EMETADATA                                                     *

dcl-f infocentre;
dcl-f opt5prtf printer oflind(*in56);
dcl-s uservar like(user) inz(*user);

user = uservar;
write entete;

read infocentre;
dow not %eof;
  vin_tot += nbrvins;
  write donnee;
  if *in56;
    write entete;
    *in56 = *off;
  endif;
  read infocentre;
enddo;
 exec sql
    select count(pr_code)
    into :pr_tot
    from infocentre;
 write total;
*inlr = *on;

