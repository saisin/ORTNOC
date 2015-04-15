//##########################################
//
//  CONTRO - #ADD_DANCE
//
// ver.2.0[2015/4/1]
//##########################################
//[ スクリの動作 ]
// ダンス用のスクリプト
// １つ終わると次のアニメを順次再生する。重複はできない。
//
//
// [ コントローラーコマンド ]
// ___,DANCE_REGISTRY,アバター名,登録ナンバー                                    //最初にアバターを登録する
// ___,DANCE_START,アニメーション名,時間,登録ナンバー(1),登録ナンバー(2)   //時間分アニメーションする。0だとループ
// ___,DANCE_STOP,登録ナンバー(1),登録ナンバー(2)                                    //ダンスを止める
//
//
//====================================================
//[input]
// (link_message) DANCE_REGISTRY&avatar_name&registry_number
// (link_message) DANCE_START&anim_name&anim_time&registry_number&registry_number
// (link_message) DANCE_STOP&registry_number&registry_number
//
//##########################################8
list NUMLIST=["0","1","2","3","4","5","6","7","8","9"]; //数字チェック用
integer LNKMSGCHNL=466938182; //リンクメッセージで通信するチャンネル
string MSG_COULDNT_FIND_AVATAR="さんが96m以内に見つかりませんでした。";
string MSG_PERMISSION_ERROR="アニメーションの権限がありません。DANCE_REGISTRYコマンドで権限を取得してください。";

integer my_script_number;                //このスクリプトの番号
string my_avatar_name;                    //このスクリプトが保持しているアバター名
key my_avatar_key;                    //このスクリプトが保持しているアバターキー
string nowanim;                      //実行中のアニメーション
list next_anim_stlist;                 //再生するアニメーションのストライドリスト(アニメーション名,(float)時間)

string tgt_name;
integer tgt_number;              //要求されている操作先ナンバー
integer perm;                    //アニメーションのパーミッションフラグ

integer i;
//==========================================================
AddAnimation(string anim,float second){
    if(nowanim==""){
        nowanim=anim;
        llStartAnimation(anim);
        //タイマーセット
        llSetTimerEvent(second);
    }else{
        next_anim_stlist+=[anim,second];
    }
}

NextAnimation(){
    llStopAnimation(nowanim);
    if(next_anim_stlist!=[]){
        if(nowanim==llList2String(next_anim_stlist,0)){llSleep(0.1);}
        nowanim=llList2String(next_anim_stlist,0);
        llStartAnimation(nowanim);
        llSetTimerEvent(llList2Float(next_anim_stlist,1));
        next_anim_stlist=llDeleteSubList(next_anim_stlist,0,1);
    }
}
//==========================================================
default{
    on_rez(integer num){
        llResetScript();
    }
    state_entry(){
        //my_script_number取得開始
        string tmp=llGetScriptName();
        integer index=llStringLength(tmp)-1;
        for(i=0;i<4;i++){
            string check=llGetSubString(tmp,index,index);
            if(llListFindList(NUMLIST,(list)check)!=-1){index--;}else{i=10;}
        }
        if(index==llStringLength(tmp)){
            my_script_number=0;}else{
            my_script_number=(integer)llGetSubString(tmp,index,llStringLength(tmp));
        }
    }
    link_message(integer sender,integer num,string msg,key id)
    {
        //-----------------------------------------------------------------------------
        //msgにコマンド名と複数のパラメーターが&区切りで送られてくるので
        //分割してリストdata_listに保存する。
        //コマンド名をチェックして好きな処理を実行する。
        //-----------------------------------------------------------------------------
        if(num!=0){
            return;
        }
        list data_list=llParseString2List(msg,["&"],[]);
        string command=llList2String(data_list,0);//比較用にコマンドは変数に入れる
        
        if(command=="DANCE_REGISTRY"){//DANCE_REGISTRY,AVANAME,NUMBER
            if((integer)llList2String(data_list,2)!=my_script_number){return;}
            llSetTimerEvent(0);//とりあえず、全てストップしてリセット
            if(perm&PERMISSION_TRIGGER_ANIMATION){
                if(nowanim!=""){
                    llStopAnimation(nowanim);
                }
            }
            nowanim="";
            next_anim_stlist=[];
            tgt_name=llList2String(data_list,1);
            if(my_avatar_name!=tgt_name){//上書きの場合実行
                if(tgt_name==llKey2Name(llGetOwner())){//オーナーならそのままアニメ権限取得へ、そうでないならセンサーで探す
                    llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION);
                }else{
                    if(tgt_name==""){
                        my_avatar_key="";
                        my_avatar_name="";
                        llRequestPermissions("1612e679-795f-4e53-ac8f-f01c8351e854",PERMISSION_TRIGGER_ANIMATION);
                    }else{
                        llSensor(tgt_name,"",AGENT,96,PI);
                    }
                }
            }
        }else if(command=="DANCE_START"){//DANCE_START,DANCENAME,TIME,NUMBER,NUMBER
            if(llListFindList(llList2List(data_list,3,-1),(list)((string)my_script_number))==-1){
                return;
            }
            if(perm&PERMISSION_TRIGGER_ANIMATION){
                AddAnimation(llList2String(data_list,1),(float)llList2String(data_list,2));
            }
        }else if(command=="DANCE_STOP"){//DANCE_STOP,NUMBER,NUMBER
            if(llListFindList(data_list,(list)((string)my_script_number))==-1){return;}
            if(perm&PERMISSION_TRIGGER_ANIMATION){
                llSetTimerEvent(0);
                if(nowanim!=""){llStopAnimation(nowanim);}
                nowanim="";
                next_anim_stlist=[];
            }
        }
    }
    run_time_permissions(integer tmp){
        perm=tmp;
        if(perm&PERMISSION_TRIGGER_ANIMATION){
            my_avatar_key=llGetPermissionsKey();
            my_avatar_name=llKey2Name(my_avatar_key);
        }
    }
    timer(){
        llSetTimerEvent(0);
        NextAnimation();
    }
    sensor(integer num){
        llRequestPermissions(llDetectedKey(0),PERMISSION_TRIGGER_ANIMATION);
    }
    no_sensor(){
        llOwnerSay(tgt_name+MSG_COULDNT_FIND_AVATAR);
    }
}