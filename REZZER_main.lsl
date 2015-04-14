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
    for(i=0;i<llGetListLength(commandlist);i++){
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
/*
    object_rez(key id){
        llOwnerSay("rezzed="+llKey2Name(id));
        ShoutCommands(llKey2Name(id));
        DelRezObjName(llKey2Name(id));
    }
*/


    listen(integer chnl,string name,key id,string msg){//channelname,REZ,XXX,<X,Y,Z>,<ROT_X,ROT_Y,ROT_Z>,second

        if(chnl==COMMON_CHANNEL+1){
            llOwnerSay("rezzed="+name);
            ShoutCommands(llKey2Name(id));
            llSetTimerEvent(0.4);
            return;
        }

        //自分宛てコマンドチェック
        string objname=llGetObjectName();
        //if(llSubStringIndex(msg,"\n"+objname+",")==-1){
        //    llOwnerSay("自分宛てコマンドがみつからないのでリターン");
        //    return;
        //}
        list tmplist=llParseString2List(msg,["\n"],[]);//A/objname,MOVE,<xyz>,<xyz>/objname,MOVE,<xyz>,<xyz>
        list rezcmd_list;
        integer i;
        for(i=1;i<llGetListLength(tmplist);i++){//objname,MOVE,<xyz>,<xyz>
            list tmplist2=llCSV2List(llList2String(tmplist,i));//objname,MOVE,<xyz>,<xyz>
            if(llList2String(tmplist2,0)==objname){
                    string command=llList2String(tmplist2,1);    //命令の種類
                    if(command=="GET_REZZER_INFO"){
                        llShout(COMMON_CHANNEL,llGetObjectDesc()+"\nREZZER_INFO,"+(string)llGetPos()+","+(string)llGetRot());//CONTROLERに位置・回転情報を返す
                        return;
                    }else if(command=="REZ"){//objname,REZ,rezobj,<XYZ>,<XYZw>,0
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
                    llOwnerSay("キューにいれます。："+llList2String(tmplist,i));
                    AddCommands(found,llList2String(tmplist,i));
                }else{
                    llOwnerSay("REZオブジェじゃない："+llList2String(tmplist,i));
                }
            }
        }
		/*
        if(rezcmd_list==[]){return;}
        rezzer_pos=llGetPos();
        string rezobjname;
        vector rezobjpos;
        rotation rezobjrot;
        integer second;
        llSetLinkPrimitiveParamsFast(llGetLinkNumber(),[PRIM_TEXTURE,ALL_SIDES,TEXTURE_TRANSPARENT,<1,1,0>,<0,0,0>,0]);
        for(i=0;i<llGetListLength(rezcmd_list);i+=4){//rezobj,<XYZ>,<XYZW>,0
            rezobjname=llList2String(rezcmd_list,i);
            rezobjpos=(vector)llList2String(rezcmd_list,i+1);
            rezobjrot=llEuler2Rot((vector)llList2String(rezcmd_list,i+2)*DEG_TO_RAD);
            second=(integer)((float)llList2String(rezcmd_list,i+3)*1000);
            float dist=llVecDist(rezzer_pos,rezobjpos);
            if(dist>=100){//REZ先が100m以上離れている場合は出さない。
                llOwnerSay((string)rezobjpos+"はREZZERから100m以上離れているのでREZしません。距離："+(string)dist);
            }else{
                //llSetAlpha(0.03,ALL_SIDES);
                //llSetTexture(TEXTURE_TRANSPARENT,ALL_SIDES);
                llSetRegionPos(rezobjpos+<0,0,9.5>);//REZZERは10m上に移動してからREZする
                //llWhisper(COMMON_CHANNEL,chnlname+",DEL,"+rezobjname+"0,0");     //先に同じオブジェがある場合重複防止のため削除
                //llOwnerSay("rezobjrot="+(string)rezobjrot);
                //llOwnerSay("RezAtRoot");
                llRezAtRoot(rezobjname,rezobjpos,ZERO_VECTOR,rezobjrot,second);
            }
        }
        //llOwnerSay("Return&SetTexture");
        llSetRegionPos(rezzer_pos);
        llSetLinkPrimitiveParamsFast(llGetLinkNumber(),[
            PRIM_TEXTURE,ALL_SIDES,"43b69a6a-c20b-0f42-1097-cf1fa5810f9c",<1,1,0>,<0,0,0>,0,
            PRIM_TEXTURE,0,"30953c55-91c5-f0e9-d34b-6147af8fca65",<1,1,0>,<0,0,0>,0,
            PRIM_TEXTURE,5,TEXTURE_BLANK,<1,1,0>,<0,0,0>,0]);
		*/
    }
}