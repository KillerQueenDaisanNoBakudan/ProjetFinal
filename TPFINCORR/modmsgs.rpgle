**free
      //%METADATA                                                      *
      // %TEXT MODULE!!! compiler avec CRTRPGMOD                       *
      //%EMETADATA                                                     *

//=======================================================================================
// SRV_MOMSGS module contenant des  procésures pour envoyer des messages
//   1) avec QMHSNDPM
//   2) avec Qp0zLprintf (vers la log du job)
//
//
// procédure compilation et installation
// CRTRPGMOD MODULE(MODMSGS)
//
// A ne faire qu'une fois:
// CRTBNDDIR  BNDDIR(UTIL_BND)
// ADDBNDDIRE BNDDIR(UTIL_BND) OBJ((MODMSGS *MODULE))
//
//
//======================================================================================
// Modifications :
// A noter : toute modification de source doit être notifié par le code
// ! code     ! date    ! developpeur   ! description

ctl-opt nomain option(*nodebugio: *srcstmt);

/copy 'TPFINCORR/modmsgs.h.rpgleinc'

//=== QMHSNDPM internal prototype =============================
dcl-pr QMHSNDPM extpgm('QMHSNDPM');
    *n char(7) const; // piMsgId
    *n char(20) const; // piMsgFile
    *n char(1024) const options(*varsize); // piMsgData
    *n int(10) const; // piMsgDataLgth
    *n char(10) const; // piMsgType
    *n char(10) const; // piCallStk
    *n int(10) const; // piRelCallStk
    *n char(4); // piRtnMsgKey
    *n char(17); // apiErrorDS
end-pr;

//=== QMHRMVPM internal prototype =============================
dcl-pr QMHRMVPM extpgm('QMHRMVPM');
    *n char(10); // pPgmMsgQ
    *n int(10); // PgmStk
    *n char(4); // MsgKey
    *n char(10); // Remove
    *n char(17); // apiErrorDS
end-pr;

//=== Qp0zLprintf =============================================
dcl-pr printLog extproc('Qp0zLprintf');
    *n pointer value options(*string); // piMsg
end-pr;


//=== SNDMSGPGMQ ===============================================
// Envoie une message dans la MSGQ du programme
// message pré défini. La msgq est le nom du programme que l'on envoie
// en paramètre
// cf CLRMSGPGMQ pour vider la MSGQ après affichage de l'écran
//==============================================================
// comment utiliser :
//=================
// H BndDir('UTIL_BND')
//...
//  /include QINCSRC,MODMSGS.H
//...
// D ProgStatus     sds
// D PgmName           *PROC
//...
//  SNDMSGPGMQ(PgmName:
//             Msgid:
//             MsgFile:
//             MsgDta);
//==============================================================
dcl-proc SndMsgPgmQ export;
    dcl-pi SndMsgPgmQ;
        pMsgQ char(10);
        pMsgid char(7) value;
        pMsgFile char(10) value;
        pMsgDta varchar(512) value options(*nopass);
    end-pi;
//=== Calling Parameters =======================================
// Parm        I/O/B  Description
// ----        -----  -----------
// pMsgQ       I      message queue à utiliser. nom du programme,
//                    ou le nom de lap rocédure MAIN. %proc().
// pMsgId      I      Message pré défini. exemple CPF9898.
// pMsgFile    I      Fichier de messages contenant pMsgid.
//                    (bibliothèque : *LIBL.)
// pMsgDta     I      Facultatif : données à remplacer dans le
//                    message

    dcl-ds APIError len(272);
        APIEProv int(10) inz(0) pos(1);
        APIEAvail int(10) inz(0) pos(5);
        APIErrId char(7) inz(*blanks) pos(9);
    end-ds;

    //=== QMHSNDPM Parameters =======================================
    dcl-s QMsgFile char(20);
    dcl-s MsgType char(10) inz('*INFO');
    dcl-s StackCntr int(10) inz(0);
    dcl-s MsgKey char(4) inz(' ');
    dcl-s MsgDta char(256) inz(' ');
    dcl-s MsgDtaLgth int(10);

    //=== SNDMSGPGMQ execution starts here ==========================
    QMsgFile = pMsgFile + '*LIBL';

    if %parms > 3;
        MsgDta = pMsgDta;
        MsgDtaLgth = %len(%trimr(MsgDta));
    else;
        MsgDtaLgth = 0;
    endif;

    //=== Send message with API =====================================
    QMHSNDPM (pMsgid
        :QMsgFile
        :MsgDta
        :MsgDtaLgth
        :MsgType
        :pMsgQ
        :StackCntr
        :MsgKey
        :APIError
    );

    return;
end-proc;


//=== CLRMSGPGMQ =-=============================================
// Vide la MSGQ du programme
// MQGD : nom du programme envoyé en paramètre
//===============================================================
// comment utiliser :
//=================
// H BndDir('UTIL_BND')
//...
//  /include QINCSRC,MODMSGS.H
//...
// D ProgStatus     sds
// D PgmName           *PROC
//...
//  CLRMSGPGMQ(PgmName)

dcl-proc ClrMsgPgmQ export;
    dcl-pi ClrMsgPgmQ ind;
        pPgmMsgQ char(10);
    end-pi;


    dcl-ds APIError len(272);
        APIEProv int(10) inz(0) pos(1);
        APIEAvail int(10) inz(0) pos(5);
        APIErrId char(7) inz(*blanks) pos(9);
    end-ds;

    //=== Parameters for QMHRMVPM API ===============================
    dcl-s PgmStk int(10) inz(0);
    dcl-s MSgKey char(4) inz(*blanks);
    dcl-s Remove char(10) inz('*ALL');

    //=== Calling Parameters =============================================
    // Parm      I/O/B    Description
    // ----      -----    -----------
    // pPGMMsgQ    I      Program message queue to clear.
    //=== ClrMsgPgmQ execution starts here ==========================
    QMHRMVPM(pPgmMsgQ
            :PgmStk
            :MSgKey
            :Remove
            :APIError
    );

    return *off;

end-proc;



//=== SndEscMsg ===============================================
// Envoie le message CPF9898 en mode *ESCAPE

dcl-proc SndEscMsg export;

    dcl-pi SndEscMsg;
        piMsg varchar(512) const;
        piStackEnt int(10) const options(*nopass);
    end-pi;

       //--- Parameters for QMHSNDPM -------------------------
    dcl-c MSGID const('CPF9898');
    dcl-c MSGF const('QCPFMSG   *LIBL     ');
    dcl-c MSGTYPE const('*ESCAPE   ');
    dcl-c PGMQUE const('*         ');
    dcl-s InvCount int(10) inz(2);
    dcl-s ApiError char(17) inz(x'00');
    dcl-s RetMsgKey char(4);
    dcl-s DataLen int(10);

    //--- Local Variables ---------------------------------
    dcl-s MsgData char(1024);

    DataLen = %len(piMsg);
    MsgData = piMsg;

    if %parms = 2;
        InvCount = piStackEnt;
    else;
        InvCount = 2;
    endif;

    QMHSNDPM(MSGID
        :MSGF
        :MsgData
        :DataLen
        :MSGTYPE
        :PGMQUE
        :InvCount
        :RetMsgKey
        :ApiError);
    return;


end-proc;


//=== SndInfMsg ===============================================
// envoie le message CPF9898 en mode *INFO
dcl-proc SndInfMsg export;

    dcl-pi SndInfMsg;
        piMsg varchar(512) const;
    end-pi;

    //--- Parameters for QMHSNDPM -------------------------
    dcl-c MSGID const('CPF9898');
    dcl-c MSGF const('QCPFMSG   *LIBL     ');
    dcl-c MSGTYPE const('*INFO     ');
    dcl-c PGMQUE const('*EXT      ');
    dcl-c INVCOUNT const(2);
    dcl-s ApiError char(17) inz(x'00');
    dcl-s RetMsgKey char(4);
    dcl-s DataLen int(10);

    //--- Local Variables ---------------------------------
    dcl-s MsgData char(1024);

    DataLen = %len(piMsg);
    MsgData = piMsg;

    QMHSNDPM(MSGID
                  :MSGF
                  :MsgData
                  :DataLen
                  :MSGTYPE
                  :PGMQUE
                  :INVCOUNT
                  :RetMsgKey
                  :ApiError);
    return;

end-proc;


//=== JobLogMsg ===============================================
// Envoie un texte dans la joblog

dcl-proc JobLogMsg export;

    dcl-pi JobLogMsg;
        piMsg varchar(512) value;
    end-pi;

    dcl-s wkMsg like(piMsg:+1);
    dcl-c EOL x'25';

    wkMsg = piMsg + EOL;

    //printLog est défini plus haut
    printLog(wkMsg);
    return;
end-proc;
