//##########################################
//
//  CONTRO - #CONTROLLER
//
//    ver.2.02 [2015/4/25]
//##########################################
//[ スクリの動作 ]
//１、ノートカードに書かれたコマンドをShoutする
//２、座標を相対化・絶対化する
//
//[ コマンド ]
//  
//
//====================================================
//[input]
// (link_message) 0,"POSMEMORY",""  [from PosMemory]  //POSMEMORYスクリから相対化の指示
// (link_message) 0,"POSSET",""  [from PosMemory]  //POSMEMORYスクリから絶対化の指示
//
//[output]
//
//channelname&
//{
// ___,REZ,<X,Y,Z>,<ROT_X,ROT_Y,ROT_Z>,second
// ___,DEL,second
// ___,COLOR,<R,G,B>
// ___,COLOR_ANIM,<R,G,B>,<R,G,B>,second
// ___,ALPHA,alpha
// ___,ALPHA_ANIM,alpha,alpha,second
// ___,MOVE,<X,Y,Z>,<ROT_X,ROT_Y,ROT_Z>
// ___,MOVE_ANIM,<X,Y,Z>,<ROT_X,ROT_Y,ROT_Z>,<X,Y,Z>,<ROT_X,ROT_Y,ROT_Z>,second
// ___,WAIT,second
//
// ___,好きなコマンド,好きな文字列
//}
//##########################################
//integer COMMON_CHANNEL=1357246809; //共通リッスンチャンネル
integer COMMON_CHANNEL=0; //共通リッスンチャンネル
string NOTENAME="commands";

list commandlist=[]; //ノートカードから読み込んだコマンドのリスト
string command_before;
string command_after;
list command_pos_list;
list command_ang_list;

integer command_index;
key lastnotecardkey;
key req_note;
integer noteline; //現在の読み込み行
integer jointflg;
string jointstrings;
integer loadingflg;

//==============================================
Run(){
    if(loadingflg){llOwnerSay("コマンドを読み込み中です、少々おまちください");return;}
    string chnlname=llGetObjectDesc();//チャンネル名取得
    //1024以内に分割して送信
    string send=chnlname;
    integer i;
    string tmp;
    string checkcmd;
    integer chatchnl;
    list tmplist;
    for(i=command_index;i<llGetListLength(commandlist);i++){
        command_index++;
        tmp=llList2String(commandlist,i);
        checkcmd=llGetSubString(tmp,0,5);
        if(checkcmd=="SHOUT,"){
            tmplist=llParseString2List(tmp,[","],[]);
            llShout((integer)llList2String(tmplist,1),llList2String(tmplist,2));
        }else if(llGetSubString(checkcmd,0,4)=="WAIT,"){
            llSetTimerEvent((float)llGetSubString(tmp,5,-1));
            i=10000;
        }else if(llGetSubString(checkcmd,0,3)=="SAY,"){
            tmplist=llParseString2List(tmp,[","],[]);
            llSay((integer)llList2String(tmplist,1),llList2String(tmplist,2));
        }else{
            if((llStringLength(send)+llStringLength(tmp)+2)<1000){
                send+="\n"+tmp;
            }else{
                llShout(COMMON_CHANNEL,send);
                send=chnlname+"\n"+tmp;
            }
        }
    }
    if(send!=chnlname){llShout(COMMON_CHANNEL,send);}
}
//===============================================
default{
    state_entry(){
        if((llGetObjectDesc()=="")||(llGetObjectDesc()=="(No Description)")){
            llSetObjectDesc("A");
        }
        loadingflg=TRUE;
        req_note=llGetNotecardLine(NOTENAME,0);
    }
    touch_start(integer num){
        if((llDetectedKey(0)!=llGetOwner())||(llGetListLength(commandlist)==0)){return;}
        command_index=0;
        Run();
    }
    timer(){
        llSetTimerEvent(0);
        Run();
    }
    changed(integer chg){
        if(chg & CHANGED_INVENTORY){
            if(lastnotecardkey!=llGetInventoryKey(NOTENAME)){//ノートが変更されたので読み込む
                lastnotecardkey=llGetInventoryKey(NOTENAME);
                commandlist=[];
                command_pos_list=[];
                command_ang_list=[];
                noteline=0;
                jointstrings="";
                jointflg=FALSE;
                llSetText("",<1,1,1>,0);
                loadingflg=TRUE;
                req_note=llGetNotecardLine(NOTENAME,0);
            }
        }
    }
    dataserver(key reqid,string data){
        if(reqid==req_note){
            if(data!=EOF){
                list tmplist=llParseString2List(data,["&"],[]);
                data=llDumpList2String(tmplist,"＆");;
                if(llStringLength(data)>=255){llOwnerSay("#ERROR#"+(string)(noteline+1)+"行目 :コマンドは1行あたり255文字未満にしてください。");}
                if(data!=""){
                    if(llGetSubString(data,0,0)!="\""){
                        //pos() ang()　保存しておく
                        list tmplist=llParseString2List(data,["pos("],[]);
                        integer i;
                        string tmp;
                        for(i=1;i<llGetListLength(tmplist);i++){
                            tmp=llGetSubString(llList2String(tmplist,i),0,llSubStringIndex(llList2String(tmplist,i),")")-1);
                            if(llListFindList(command_pos_list,(list)tmp)==-1){
                                command_pos_list+=[tmp,<0,0,0>,<0,0,0>];//128,128,20|<1.0000,0.0000,0.0000>|<128.0000,128.0000,20.0000> //絶対<>無し文字列|相対｜絶対
                            }
                        }
                        tmplist=llParseString2List(data,["ang("],[]);
                        for(i=1;i<llGetListLength(tmplist);i++){
                            tmp=llGetSubString(llList2String(tmplist,i),0,llSubStringIndex(llList2String(tmplist,i),")")-1);
                            if(llListFindList(command_ang_list,(list)tmp)==-1){
                                command_ang_list+=[tmp,ZERO_ROTATION,ZERO_ROTATION];//0,0,90|rotation|rotation //絶対<>無し文字列|相対｜絶対
                            }
                        }
                        //,終わりは複数行コマンドなのでつなげる
                        if(llGetSubString(data,-1,-1)==","){
                            jointflg=TRUE;
                            jointstrings+=data;
                        }else{
                            if(jointflg){
                                commandlist+=jointstrings+data;
                                jointflg=FALSE;
                                jointstrings="";
                            }else{
                                commandlist+=data;
                            }
                        }
                    }else{
                        llSetText(llGetSubString(data,1,llStringLength(data)-2),<1,1,1>,1);
                    }
                }
                noteline++;
                req_note=llGetNotecardLine(NOTENAME,noteline);
            }else{
                //pos() ang()を変換
                command_before=llDumpList2String(commandlist,"&");
                list tmplist=llParseStringKeepNulls(command_before,["pos("],[""]);
                integer i;
                integer ind;
                string tmptgt;
                for(i=1;i<llGetListLength(tmplist);i++){
                    tmptgt=llList2String(tmplist,i);
                    ind=llSubStringIndex(tmptgt,")");
                    tmplist=llListReplaceList(tmplist,(list)(llGetSubString(tmptgt,0,ind-1)+">"+llGetSubString(tmptgt,ind+1,-1)),i,i);
                }
                command_after=llDumpList2String(tmplist,"<");
                tmplist=llParseStringKeepNulls(command_after,["ang("],[""]);
                for(i=1;i<llGetListLength(tmplist);i++){
                    tmptgt=llList2String(tmplist,i);
                    ind=llSubStringIndex(llList2String(tmplist,i),")");
                    tmplist=llListReplaceList(tmplist,(list)(llGetSubString(tmptgt,0,ind-1)+">"+llGetSubString(tmptgt,ind+1,-1)),i,i);
                }
                command_after=llDumpList2String(tmplist,"<");
                //tmplist=llParseStringKeepNulls(command_after,[")"],[""]);
                //command_after=llDumpList2String(tmplist,">");
                commandlist=llParseString2List(command_after,["&"],[]);

                //llOwnerSay("poslist="+llDumpList2String(command_pos_list,"\n"));
                //llOwnerSay("anglist="+llDumpList2String(command_ang_list,"\n"));
                //llOwnerSay("cmdlist="+llDumpList2String(commandlist,"\n"));
                loadingflg=FALSE;
            }
        }
    }
    link_message(integer sender,integer num,string msg,key id){
        if((msg=="RUN")&&(num==llGetLinkNumber())){
            command_index=0;
            Run();
        }
        if(msg=="POSMEMORY"){
            list tmplist=llParseString2List(id,["&"],[]);//<128,128,20>&rotation
            vector rezzer_pos=(vector)llList2String(tmplist,0);
            rotation rezzer_rot=(rotation)llList2String(tmplist,1);
            vector relpos;
            integer i;
            //llOwnerSay("cmdposlist="+(string)llGetListLength(command_pos_list));
            for(i=0;i<llGetListLength(command_pos_list);i+=3){
                relpos=((vector)("<"+llList2String(command_pos_list,i)+">")-rezzer_pos)/rezzer_rot;
                command_pos_list=llListReplaceList(command_pos_list,(list)relpos,i+1,i+1);
                //llOwnerSay("pos_list_i="+llList2String(command_pos_list,i)+"\nrelpos="+(string)relpos);
            }
            for(i=0;i<llGetListLength(command_ang_list);i+=3){
                rotation relrot=llEuler2Rot((vector)(llList2String(command_ang_list,i))*DEG_TO_RAD)/rezzer_rot;
                command_ang_list=llListReplaceList(command_ang_list,(list)relrot,i+1,i+1);
            }
            //llOwnerSay("poslist="+llDumpList2String(command_pos_list,"\n"));
            //llOwnerSay("anglist="+llDumpList2String(command_ang_list,"\n"));
        }
        if(msg=="POSSET"){
            list tmplist=llParseString2List(id,["&"],[]);//<128,128,20>&<0,0,90>
            vector rezzer_pos=(vector)llList2String(tmplist,0);
            rotation rezzer_rot=(rotation)llList2String(tmplist,1);
            //絶対座標作成
            vector abspos;
            string absang;
            integer i;
            //llOwnerSay("cmdposlist="+(string)llGetListLength(command_pos_list));
            for(i=0;i<llGetListLength(command_pos_list);i+=3){
                abspos=rezzer_pos+(llList2Vector(command_pos_list,i+1)*rezzer_rot);
                command_pos_list=llListReplaceList(command_pos_list,(list)abspos,i+2,i+2);
                //llOwnerSay("abspos_i("+(string)i+")="+(string)abspos);
            }
            for(i=0;i<llGetListLength(command_ang_list);i+=3){
                absang=(string)(llRot2Euler(llList2Rot(command_ang_list,i+1)*rezzer_rot)*RAD_TO_DEG);
                command_ang_list=llListReplaceList(command_ang_list,(list)absang,i+2,i+2);
                //llOwnerSay("absrot_i("+(string)i+")="+absang);
            }
            //置換
            command_after=command_before;
            for(i=0;i<llGetListLength(command_pos_list);i+=3){
                tmplist=llParseStringKeepNulls(command_after,["pos("+llList2String(command_pos_list,i)+")"],[]);
                command_after=llDumpList2String(tmplist,llList2String(command_pos_list,i+2));
            }
            for(i=0;i<llGetListLength(command_ang_list);i+=3){
                tmplist=llParseStringKeepNulls(command_after,["ang("+llList2String(command_ang_list,i)+")"],[]);
                command_after=llDumpList2String(tmplist,llList2String(command_ang_list,i+2));
            }
            commandlist=llParseString2List(command_after,["&"],[]);
            llOwnerSay("poslist="+llDumpList2String(command_pos_list,"\n"));
            llOwnerSay("anglist="+llDumpList2String(command_ang_list,"\n"));
            llOwnerSay("cmdlist="+llDumpList2String(commandlist,"\n"));
        }
    }
}