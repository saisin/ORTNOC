//##########################################
//
//  CONTRO - #ADD_DANCE
//
// ver.1.1[2015/1/28]
//##########################################
//[ スクリの動作 ]
// ダンス用のスクリプト
// １つ終わると次のアニメを順次再生する。重複はできない。
//
//
// [ コントローラーコマンド ]
// DANCE_REGISTRY,___,登録ナンバー,アバター名            //最初にアバターを登録する
// DANCE_START,___,登録ナンバー,アニメーション名,時間        //時間分アニメーションする。0だとループ
// DANCE_STOP,___,登録ナンバー                                //ダンスを止める
//
//
//====================================================
//[input]
// (link_message) DANCE_REGISTRY&number&avatar_name
// (link_message) DANCE_START&avatar_name&anim_name
// (link_message) DANCE_STOP&avatar_name&anim_name
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

integer tgt_number;              //要求されている操作先ナンバー
string tgt_name;                //要求されているアバター名もしくはアニメーション名
float tgt_sec;                  //アニメーションの秒数
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

        tgt_number=(integer)llList2String(data_list,1);  //操作先の番号
        if(tgt_number!=my_script_number){return;}

        //パラメータを格納して各コマンドを実行する
        tgt_name=llList2String(data_list,2);        //アバター名もしくはアニメーション名
        tgt_sec=(float)llList2String(data_list,3);  //アニメーションの秒数

        if(command=="DANCE_REGISTRY"){
            llSetTimerEvent(0);//とりあえず、全てストップしてリセット
            if(perm&PERMISSION_TRIGGER_ANIMATION){
                llStopAnimation(nowanim);
            }
            nowanim="";
            next_anim_stlist=[];
            if(my_avatar_name!=tgt_name){//上書きの場合実行
                if(tgt_name==llKey2Name(llGetOwner())){//オーナーならそのままアニメ権限取得へ、そうでないならセンサーで探す
                    llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION);
                }else{
					if(tgt_name==""){
						llRequestPermissions("1612e679-795f-4e53-ac8f-f01c8351e854",PERMISSION_TRIGGER_ANIMATION);
					}else{
						llSensor(tgt_name,"",AGENT,96,PI);
					}
                }
            }
        }else if(command=="DANCE_START"){
            if(perm&PERMISSION_TRIGGER_ANIMATION){
                AddAnimation(tgt_name,tgt_sec);
            }
        }else if(command=="DANCE_STOP"){
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
        my_avatar_name=tgt_name;
        my_avatar_key=llDetectedKey(0);
        llRequestPermissions(my_avatar_key,PERMISSION_TRIGGER_ANIMATION);
    }
    no_sensor(){
        llOwnerSay(tgt_name+MSG_COULDNT_FIND_AVATAR);
    }
}