MODULE 'exec/tasks',
       'exec/ports',
       'exec/nodes',
       'exec/lists',
       'exec/types',
       'amigalib/ports',
       'tools/arexx',
       'intuition/intuition',
       'intuition/intuitionbase',
       'intuition/screens'

OBJECT doormsg
  door_msg:mn,
  command:INT,
  data:INT,
  string[80]:ARRAY OF CHAR,
  carrier:INT
ENDOBJECT

-> PROC main() is simply the startup code... write your door in
-> PROC theDoor()

-> These are all neaded by the startup code
DEF msgportname[12]:STRING, msgportname2[10]:STRING, mport=NIL:PTR TO mp,
    ourtask,cport=NIL:PTR TO mp, lost_carrier=0, wherefrom:PTR TO CHAR,
    p1:doormsg,rexxport,mes,command,doorarg[150]:STRING,space,
    script[150]:STRING,doorport[5]:STRING,portname[20]:STRING

PROC main()

    StrCopy(doorarg,arg,ALL)
    IF space:=InStr(doorarg,' ',0) THEN MidStr(script,doorarg,0,space)
    space:=MidStr(doorport,doorarg,space,space+1)
    space:=Val(doorport)

                StringF(portname,'MAXSERVE\d',space)

        rexxport:=rx_OpenPort(portname)
   StringF(script,'run RX >>T:MaxRexx.errors\d \s \d',space,script,space)
->StringF(script,'run RX >CON: \s \d',script,space)
    Execute(script,NIL,NIL)

    StringF(msgportname,'DoorControl\d',space)
    StringF(msgportname2,'DoorReply\d',space)

  -> Make msg port & msg:
  IF(mport:=createPort(msgportname2,0))

    ourtask:=FindTask(NIL)

    p1.door_msg.ln.type:=NT_MESSAGE
    p1.door_msg.replyport:=mport
    p1.door_msg.length:=SIZEOF doormsg

    -> Find  M A X's BBS door control port prt:

    Forbid()
    cport:=FindPort(msgportname)
    Permit()
    IF(cport>0)
      
      -> Startup code complete!
      theDoor()

      -> Closedown code
      p1.command:=20
      p1.data:=0
      putWaitMsg(p1)
    ELSE
      PrintF('$VER: MaxRexx V1.2 (c) 1998 Ian Chapman\n')
      PrintF('Must be run as a door from Maxs BBS!\n\n')
      PrintF('Arguments:-\n')
      PrintF('MaxRexx <arexx script>\n')
    ENDIF

    -> Clean up and return
    deletePort(mport)           -> Free port
  ENDIF
ENDPROC

/**************************
** WRITE YOUR DOOR HERE! **
**************************/

PROC theDoor()

DEF str[250]:STRING,
    num,
    outstring[200]:STRING,
    rc,
    menufunction[5]:STRING,
    extra[5]:STRING,
    menustr[40]:STRING,
    where,
    winx[5]:STRING,
    winy[5]:STRING,
    wintitle[30]:STRING,
    wintext[50]:STRING,
        centext[80]:STRING,
        ceny[5]:STRING,
        gotx[5]:STRING,
        goty[5]:STRING,
        backspace[200]:STRING,
        usinta[5]:STRING,
    usintb[5]:STRING,
        win:PTR TO window,
    maxscr:PTR TO screen,
    boxx,
    boxy,
    ibase:PTR TO intuitionbase,
    windowopen=FALSE

ibase:=intuitionbase

waitmessage:
REPEAT
    mes,command:=rx_GetMsg(rexxport)
    WaitTOF()
UNTIL mes<>0

StrCopy(str,command,ALL)

/*This is where the MaxRexx commands start*/

IF InStr(str,'$PRINTLN ',0)>-1
    MidStr(str,str,9,ALL)
    StringF(str,'\s\n',str)
    mxPrint(str)
    rx_ReplyMsg(mes,0,NIL)
    JUMP waitmessage
ENDIF

IF InStr(str,'$PRINT ',0)>-1
    MidStr(str,str,7,ALL)
    mxPrint(str)
    rx_ReplyMsg(mes,0,NIL)
    JUMP waitmessage
ENDIF


IF InStr(str,'$CENTRE ',0)>-1
        MidStr(str,str,8,ALL)
        where:=InStr(str,',',0)
        MidStr(ceny,str,0,where)
        MidStr(centext,str,where+1,ALL)
        mxCentre(Val(ceny),centext)
        rx_ReplyMsg(mes,0,NIL)
        JUMP waitmessage
ENDIF

IF InStr(str,'$GOTO ',0)>-1
        MidStr(str,str,6,ALL)
        where:=InStr(str,',',0)
        MidStr(gotx,str,0,where)
        MidStr(goty,str,where+1,ALL)
        mxGoto(Val(gotx),Val(goty))
        rx_ReplyMsg(mes,0,NIL)
        JUMP waitmessage
ENDIF

IF InStr(str,'$FCOLOUR',0)>-1
    MidStr(str,str,9,ALL)
    mxColourF(Val(str))
    rx_ReplyMsg(mes,0,NIL)
    JUMP waitmessage
ENDIF

IF InStr(str,'$BCOLOUR',0)>-1
    MidStr(str,str,9,ALL)
    mxColourB(Val(str))
    rx_ReplyMsg(mes,0,NIL)
    JUMP waitmessage
ENDIF

IF InStr(str,'$PAGEFLAG',0)>-1
    MidStr(str,str,10,ALL)
    mxSetPageFlag(Val(str))
    rx_ReplyMsg(mes,0,NIL)
    JUMP waitmessage
ENDIF

IF InStr(str,'$NEWLINE',0)>-1
    mxPrint('\n')
    rx_ReplyMsg(mes,0,NIL)
    JUMP waitmessage
ENDIF

IF InStr(str,'$CLS',0)>-1
    mxPrint('[2J[0;0H')
    rx_ReplyMsg(mes,0,NIL)
    JUMP waitmessage
ENDIF

IF InStr(str,'$INPUT ',0)>-1
    MidStr(str,str,7,ALL)
    mxInput(Val(str),outstring)
    IF StrLen(outstring)=0 THEN rc:=-1 ELSE rc:=0
    rx_ReplyMsg(mes,rc,outstring)
    JUMP waitmessage
ENDIF

IF InStr(str,'$HOTKEY',0)>-1
    num:=mxHotKey()
    StringF(outstring,'\d',num)
    rx_ReplyMsg(mes,0,outstring)
    JUMP waitmessage
ENDIF

IF InStr(str,'$NOWAITHOTKEY',0)>-1
    num:=mxNoWaitHotKey()
    StringF(outstring,'\d',num)
    rx_ReplyMsg(mes,0,outstring)
    JUMP waitmessage
ENDIF

IF InStr(str,'$SHOWANSI',0)>-1
    MidStr(str,str,10,ALL)
    mxPrintFile(str)
    rx_ReplyMsg(mes,0,NIL)
    JUMP waitmessage
ENDIF

IF InStr(str,'$CHECKFILE',0)>-1
    MidStr(str,str,11,ALL)
    rc:=mxCheckFile(str)
    rx_ReplyMsg(mes,rc,NIL)
    JUMP waitmessage
ENDIF

IF InStr(str,'$USERVAL',0)>-1
    MidStr(str,str,9,ALL)
    num:=Val(str)
    num:=mxGetIntInfo(num)
    StringF(outstring,'\d',num)
    rx_ReplyMsg(mes,0,outstring)
    JUMP waitmessage
ENDIF

IF InStr(str,'$USERSTR',0)>-1
    MidStr(str,str,9,ALL)
    num:=Val(str)
    mxGetStrInfo(num,outstring)
    rx_ReplyMsg(mes,0,outstring)
    JUMP waitmessage
ENDIF

IF InStr(str,'$MENUFUNC',0)>-1
    MidStr(str,str,10,ALL)
    where:=InStr(str,',',0)
    MidStr(menufunction,str,0,where)
    MidStr(str,str,where+1,ALL)
    where:=InStr(str,',',0)
    MidStr(extra,str,0,where)
    MidStr(menustr,str,where+1,ALL)
    IF InStr(menustr,'NIL',0)=1 THEN menustr[0]:=NIL
    mxMenuFunct(Val(menufunction),Val(extra),menustr)
    mxPrint(menustr)
        rx_ReplyMsg(mes,0,NIL)
    JUMP waitmessage
ENDIF

IF InStr(str,'$NEWUSERINT',0)>-1
    MidStr(str,str,12,ALL)
    where:=InStr(str,',',0)
    MidStr(usinta,str,0,where)
    MidStr(usintb,str,where+1,ALL)
    mxChangeUserInt(Val(usinta),Val(usintb))
    rx_ReplyMsg(mes,0,NIL)
    JUMP waitmessage
ENDIF

IF InStr(str,'$ASCIIBOX ',0)>-1
        MidStr(str,str,10,ALL)
        where:=InStr(str,',',0)
        MidStr(gotx,str,0,where)
        MidStr(goty,str,where+1,ALL)

        mxPrint('.')
        FOR boxx:=1 TO Val(gotx)-2
            mxPrint('-')
        ENDFOR
        mxPrint('.[1B')
        StringF(backspace,'[\dD',Val(gotx))
        mxPrint(backspace)

        FOR boxy:=1 TO Val(goty)-2
            mxPrint('| ')
                FOR boxx:=1 TO Val(gotx)-3
                    mxPrint(' ')
                ENDFOR
            mxPrint('|[1B')
            mxPrint(backspace)
        ENDFOR


        StrCopy(backspace,'\a')
        mxPrint('`')
        FOR boxx:=1 TO Val(gotx)-2
            mxPrint('-')
        ENDFOR
        mxPrint(backspace)

        rx_ReplyMsg(mes,0,NIL)
        JUMP waitmessage
ENDIF

IF InStr(str,'$ANSIBOX ',0)>-1
        MidStr(str,str,9,ALL)
        where:=InStr(str,',',0)
        MidStr(gotx,str,0,where)
        MidStr(goty,str,where+1,ALL)

        mxPrint('Ú')
        FOR boxx:=1 TO Val(gotx)-2
            mxPrint('Ä')
        ENDFOR
        mxPrint('¿[1B')
        StringF(backspace,'[\dD',Val(gotx))
        mxPrint(backspace)

        FOR boxy:=1 TO Val(goty)-2
            mxPrint('³')
                FOR boxx:=1 TO Val(gotx)-2
                    mxPrint(' ')
                ENDFOR
            mxPrint('³[1B')
            mxPrint(backspace)
        ENDFOR

        mxPrint('À')
        FOR boxx:=1 TO Val(gotx)-2
            mxPrint('Ä')
        ENDFOR
        mxPrint('Ù')

        rx_ReplyMsg(mes,0,NIL)
        JUMP waitmessage
ENDIF


IF InStr(str,'$OPENWINDOW',0)>-1
    IF windowopen=FALSE
        maxscr:=ibase.firstscreen


        WHILE InStr(maxscr.title,'1: M A X',0)=-1
            maxscr:=maxscr.nextscreen
            WaitTOF()
        ENDWHILE

        MidStr(str,str,12,ALL)
        where:=InStr(str,',',0)
        MidStr(winx,str,0,where)
        MidStr(str,str,where+1,ALL)
        where:=InStr(str,',',0)
        MidStr(winy,str,0,where)
        MidStr(wintitle,str,where+1,ALL)

        IF (win:=OpenW(0,0,Val(winx),Val(winy),IDCMP_CLOSEWINDOW,
                                               WFLG_DRAGBAR OR
                                               WFLG_GIMMEZEROZERO,
                                               wintitle,
                                               maxscr,
                                               $F,
                                               NIL,
                                               NIL))=NIL
            rx_ReplyMsg(mes,-1,NIL)
            windowopen:=FALSE
        ELSE
            windowopen:=TRUE
            rx_ReplyMsg(mes,0,NIL)
        ENDIF
    ELSE
        rx_ReplyMsg(mes,0,NIL)
    ENDIF

    JUMP waitmessage

ENDIF

IF InStr(str,'$WINTEXT',0)>-1
    IF windowopen=TRUE
        MidStr(str,str,9,ALL)
        where:=InStr(str,',',0)
        MidStr(winx,str,0,where)
        MidStr(str,str,where+1,ALL)
        where:=InStr(str,',',0)
        MidStr(winy,str,0,where)
        MidStr(wintext,str,where+1,ALL)

        TextF(Val(winx),Val(winy),wintext)
        rx_ReplyMsg(mes,0,NIL)
    ELSE
        rx_ReplyMsg(mes,-1,NIL)
    ENDIF

    JUMP waitmessage
ENDIF

IF InStr(str,'$WINCOL',0)>-1
    MidStr(str,str,8,ALL)
    Colour(Val(str))
    rx_ReplyMsg(mes,0,NIL)
    JUMP waitmessage
ENDIF

IF InStr(str,'$CLOSEWINDOW',0)>-1
    IF windowopen=TRUE
        CloseW(win)
        windowopen:=FALSE
        rx_ReplyMsg(mes,0,NIL)
    ELSE
        rx_ReplyMsg(mes,-1,NIL)
    ENDIF

    JUMP waitmessage
ENDIF

IF InStr(str,'$MAXBEEP',0)>-1
    IF maxscr>0 THEN DisplayBeep(maxscr) ELSE DisplayBeep(NIL)
    rx_ReplyMsg(mes,0,NIL)
    JUMP waitmessage
ENDIF


/*This is where the MaxRexx commands end*/

IF InStr(str,'$TWIT',0)>-1
    StrCopy(str,'$END')
    mxTwit()
    rx_ReplyMsg(mes,0,NIL)
ENDIF

IF InStr(str,'$END',0)=-1
    mxPrint('[31m\n------------------------------\n')
    mxPrint('\n   Warning - Unknown Command  \n')
    mxPrint(str)
    mxPrint('\nPress Any Key to return to BBS\n')
    mxPrint('------------------------------[37;40m')
    DisplayBeep(NIL)
    mxHotKey()
    rx_ReplyMsg(mes,-1,NIL)
ELSE
    rx_ReplyMsg(mes,0,NIL)
ENDIF


rx_ClosePort(rexxport)

ENDPROC

-> Print a string
PROC mxPrint(str:PTR TO CHAR)
  p1.command:=1
  p1.data:=0
  doCopy(p1.string,str)
  putWaitMsg(p1)
ENDPROC

-> Input a string. NOTE: buffer *MUST* point to an E-String!!!!
PROC mxInput(maxlen:PTR TO INT,buffer)
  DEF rt
  p1.command:=6
  p1.data:=maxlen
  p1.string[]:=0
  rt:=putWaitMsg(p1)
  StrCopy(buffer,p1.string)
ENDPROC

-> Reads a key
-> Returns ASCII value
-> IF(wherefrom=0) its from the local terminal
-> IF(wherefrom=1) its from the remote terminal
PROC mxHotKey()
  DEF rt
  p1.command:=8
  p1.data:=0
  p1.string[]:=0
  rt:=putWaitMsg(p1)
  wherefrom:=Char(p1.string-1)
ENDPROC Char(p1.string)

-> Twit the user
PROC mxTwit()
  p1.command:=9
  putWaitMsg(p1)
ENDPROC

-> Print a text file
PROC mxPrintFile(filename)
  p1.command:=10
  p1.data:=0
  doCopy(p1.string,filename)
  putWaitMsg(p1)
ENDPROC

-> Check file is online
-> 1 if yes, -1 if no
PROC mxCheckFile(filename)
  DEF rt
  p1.command:=11
  p1.data:=0
  doCopy(p1.string,filename)
  rt:=putWaitMsg(p1)
ENDPROC p1.data  

PROC mxNoWaitHotKey()
 DEF rt
   p1.command:=201
   p1.data:=0
   p1.string[]:=0
   rt:=putWaitMsg(p1)
   wherefrom:=Char(p1.string-1)
ENDPROC Char(p1.string)

PROC mxSetPageFlag(state)
   p1.command:=202
   p1.data:=state
   putWaitMsg(p1)
ENDPROC

PROC mxColourF(f)
DEF goat[10]:STRING
   StringF(goat,'\e[3\dm',f)
   mxPrint(goat)
ENDPROC

PROC mxColourB(b)
DEF goat[10]:STRING
   StringF(goat,'\e[4\dm',b)
   mxPrint(goat)
ENDPROC

-> Get user information values
PROC mxGetIntInfo(type:PTR TO INT)
  p1.command:=13
  p1.data:=type
  p1.string[]:=0
  putWaitMsg(p1)
ENDPROC p1.data

-> Get user/BBS strings
-> buffer *MUST* point to an E-String
PROC mxGetStrInfo(type,buffer)
  p1.command:=14
  p1.data:=type
  p1.string[]:=0
  putWaitMsg(p1)
  StrCopy(buffer,p1.string)
ENDPROC
  
-> Do a maxs bbs menu function
PROC mxMenuFunct(menufunc,extra,string)
  p1.command:=menufunc+100
  p1.data:=extra
  doCopy(p1.string,string)
  putWaitMsg(p1)
ENDPROC

-> Change a user int value
-> MAXs BBS only!
PROC mxChangeUserInt(uint,value)
  p1.command:=200
  p1.data:=uint
  p1.string[]:=value
  putWaitMsg(p1)
ENDPROC

PROC mxCentre(y,text)
DEF str[80]:STRING,len
        len:=StrLen(text)
        len:=(80-len)/2
        StringF(str,'\e[\d;\dH\s',y,len,text)
        mxPrint(str)
ENDPROC

PROC mxGoto(x,y)
DEF goat[10]:STRING
        StringF(goat,'\e[\d;\dH',y,x)
        mxPrint(goat)
ENDPROC

      
-> Wait for reply msg
-> returns ptr to string

PROC putWaitMsg(msg:PTR TO doormsg)
  DEF rmsg
  PutMsg(cport,msg)
waitloop:
  WaitPort(mport)
  IF(rmsg:=GetMsg(mport))=0 THEN JUMP waitloop
  lost_carrier:=p1.carrier
ENDPROC rmsg  

PROC doCopy(dest:PTR TO CHAR,src:PTR TO CHAR)
  DEF c
  FOR c:=0 TO StrLen(src)
    PutChar(dest+c,Char(src+c))
  ENDFOR
ENDPROC
