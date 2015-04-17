//##########################################
//
//  CONTRO - #REZZER_main
//
//  ver.2.0 [2015/4/1]
//##########################################
//[ スクリの動作 ]
//１、指定された座標にオブジェクトをREZする
//２、コントローラーからレザーの位置確認要求があれば自分の座標・角度をシャウトする
//３、REZするオブジェクトへの命令を一時的にストックしておきREZされた後に発言する
//
// [ コマンド ]
// REZ,___,pos(),ang(),second
//
//====================================================
//[input]
// (COMMON_CHANNEL) channelname,REZ,XXX,<X,Y,Z>,<ROT_X,ROT_Y,ROT_Z>,second  [from CONTROLLER]
// (COMMON_CHANNEL) channelname,GET_REZZER_INFO [from CONTROLLER]
//
//[output]
// (COMMON_CHANNEL) chnlname+",REZZER_INFO,"+(string)llGetPos()+","+(string)llGetRot() [to CONTROLLER]
//
//##########################################
//integer COMMON_CHANNEL=1357246809; //共通リッスンチャンネル
integer COMMON_CHANNEL=0; //共通リッスンチャンネル
vector rezzer_pos;    //REZZERの初期位置を記憶しておく変数
list save_command_list=[]; //再送信するコマンドを保存しておく
list rezzing_objname_list=[];

//==============================================
AddRezObjName(string objname){
    if(llListFindList(rezzing_objname_list,(list)objname)==-1){
        rezzing_objname_list+=[objname];
        save_command_list+=["@"];//初期値、あとで上書きされるため必要
        //llOwnerSay("AddRezObjname;"+objname+" nowlist="+llDumpList2String(rezzing_objname_list,"&"));
    }
}
DelRezObjName(string objname){
    integer ind=llListFindList(rezzing_objname_list,(list)objname);if(ind==-1){return;}
    save_command_list=llDeleteSubList(save_command_list,ind,ind);
    rezzing_objname_list=llDeleteSubList(rezzing_objname_list,ind,ind);
    //llOwnerSay("DelRezObjname;"+llDumpList2String(rezzing_objname_list,"\n"));
}
AddCommands(integer ind,string add_command){//MOVE,XXX,<XYZ>,<XYZ>
    list tmplist=llParseString2List(llList2String(save_command_list,ind),["\n"],[]);
    save_command_list=llListReplaceList(save_command_list,(list)llDumpList2String(tmplist+(list)add_command,"\n"),ind,ind);    
}
ShoutCommands(string objname){
    integer ind=llListFindList(rezzing_objname_list,(list)objname);if(ind==-1){return;}
    list commandlist=llParseString2List(llList2String(save_command_list,ind),["\n"],[]);

    string chnlname=llGetObjectDesc();//チャンネル名取得
    //1024以内に分割して送信
    string send=chnlname;
    integer i;
    string tmp;
    for(i=1;i<llGetListLength(commandlist);i++){
        tmp=llList2String(commandlist,i);
        if((llStringLength(send)+llStringLength(tmp)+2)<1000){
            send+="\n"+tmp;
        }else{
            llShout(COMMON_CHANNEL,send);
            send=chnlname+"\n"+tmp;
        }
    }
    if(send!=chnlname){llShout(COMMON_CHANNEL,send);}    
}
//==============================================
default{
    state_entry(){
        if(llGetObjectDesc()==""){
            llSetObjectDesc("A");
        }
        rezzer_pos=llGetPos();
        llListen(COMMON_CHANNEL,"","","");
        llListen(COMMON_CHANNEL+1,"","","REZZED");
    }

    timer(){//キューのリセット
            llSetTimerEvent(0);
            llSetRegionPos(rezzer_pos);
            llSetLinkPrimitiveParamsFast(llGetLinkNumber(),[
                PRIM_TEXTURE,ALL_SIDES,"43b69a6a-c20b-0f42-1097-cf1fa5810f9c",<1,1,0>,<0,0,0>,0,
                PRIM_TEXTURE,0,"30953c55-91c5-f0e9-d34b-6147af8fca65",<1,1,0>,<0,0,0>,0,
                PRIM_TEXTURE,5,TEXTURE_BLANK,<1,1,0>,<0,0,0>,0]);
            rezzing_objname_list=[];
            save_command_list=[];
    }

    listen(integer chnl,string name,key id,string msg){//channelname,REZ,XXX,<X,Y,Z>,<ROT_X,ROT_Y,ROT_Z>,second

        if(chnl==COMMON_CHANNEL+1){
            ShoutCommands(name);
            DelRezObjName(name);
            //rezzed_objname_list+=name;
            llSetTimerEvent(2);
            return;
        }

        string objname=llGetObjectName();
        list tmplist=llParseStringKeepNulls(msg,["\n"],[]);//A/objname,MOVE,<xyz>,<xyz>/objname,MOVE,<xyz>,<xyz>
        list rezcmd_list;
        integer i;
        for(i=1;i<llGetListLength(tmplist);i++){//objname,MOVE,<xyz>,<xyz>
            list tmplist2=llCSV2List(llList2String(tmplist,i));//objname,MOVE,<xyz>,<xyz>
            if(llList2String(tmplist2,0)==objname){
                    string command=llList2String(tmplist2,1);    //命令の種類
                    if(command=="GET_REZZER_INFO"){
                        llShout(COMMON_CHANNEL,llGetObjectDesc()+"\nREZZER_INFO,"+(string)llGetPos()+","+(string)llGetRot());//CONTROLERに位置・回転情報を返す
                        rezzer_pos=llGetPos();
                        return;
                    }else if(command=="REZ"){//objname,REZ,rezobj,<XYZ>,<XYZw>,0
                        if(rezzing_objname_list==[]){
                            llSetLinkPrimitiveParamsFast(llGetLinkNumber(),[PRIM_TEXTURE,ALL_SIDES,TEXTURE_TRANSPARENT,<1,1,0>,<0,0,0>,0]);
                        }
                        //llOwnerSay("REZ準備");
                        string rezobjname=llList2String(tmplist2,2);
                        if(llGetInventoryType(rezobjname)==INVENTORY_NONE){return;}//インベントリーに無い場合中断
                        rezcmd_list+=llList2List(tmplist2,2,5);
                        AddRezObjName(rezobjname);
                        llMessageLinked(LINK_THIS,123456,llList2String(tmplist2,2)+","+llList2String(tmplist2,3)+","+llList2String(tmplist2,4)+","+llList2String(tmplist2,5)+","+llList2String(tmplist2,6),"REZ");
                    }
            }else{//REZ中のオブジェクト宛てコマンドは保存
                integer found=llListFindList(rezzing_objname_list,llList2List(tmplist2,0,0));
                if(found!=-1){
                    AddCommands(found,llList2String(tmplist,i));
                }
            }
        }
    }
}