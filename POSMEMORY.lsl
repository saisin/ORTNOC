//##########################################
//
//  CONTRO - #POSMEMORY
//
//  ver.2.0[2015/4/1]
//##########################################
//[ スクリの動作 ]
//１、長押しでダイアログを出す
//２、ベースとの相対化(PosMemory)する
//３、現地で絶対化(PosSet)する
//
// [ PosMemoryのやり方 ]
//１、Flagを基準点に移動させる
//３、インベントリーからCONTROLLER_BASEオブジェクトをREZする
//４、CONTROLLERオブジェクトを並べる
//５、CONTROLLER_BASEオブジェクトをルートプリムにしてリンクする
//６、#POSMEMORYスクリプトを入れる
//７、ダイアログにしたがってPosMemoryを完了させる
// [ PosSetのやり方 ]
//１、Flagを基準点に移動させる
//３、インベントリーからCOMBINE_BASEオブジェクトをREZする
//４、CONTROLLERオブジェクトを並べる
//５、CONTROLLER_BASEオブジェクトをルートプリムにしてリンクする
//６、#POSMEMORYスクリプトを入れる
//７、ダイアログにしたがってPosMemoryを完了させる
//
//====================================================
//[ input ]
//
//[output]
// (COMMON_CHANNEL) channelname,GET_FLAGPOS   [To PosFlag]
// (link_message) 0,"POSMEMORY",rezzer_pos&rezzer_rot [to CHILDPRIMS] 子プリムへベースの位置を送り、相対化させる。
// (link_message) 0,"POSSET",rezzer_pos&rezzer_rot [to CHILDPRIMS] 子プリムへベースの位置を送り、絶対化させる。
//
//##########################################
integer COMMON_CHANNEL=1357246809; //共通リッスンチャンネル
string chnlname;  //チャンネル名(混線防止)

integer dlgchnl; //ダイアログ用リッスンチャンネル
integer lsnnum;
string DLG_POSMEMORY="PosMemoryを行います。
POSFLAGをREZし基準点に移動したら
'POSMEMORY'ボタンを押してください";
string DLG_POSSET="PosSetを行います。
POSFLAGをREZし基準点に移動したら
'POSSET'ボタンを押してください";
integer PosMemoryFlg=FALSE;
integer PosSetFlg=FALSE;

vector rezzer_pos=<0,0,0>;
rotation rezzer_rot=ZERO_ROTATION;

string timer_failed_msg;
integer touchcnt=0;
//==============================================
default{
    state_entry(){
        if(llGetFreeMemory()<17000){
            llDialog(llGetOwner(),"コンバインを行う前にスクリプトをMONOで保存しなおして下さい。\n#POSMEMORYスクリプトを開き、MONOにチェックを入れて保存して下さい。",["OK"],-1651352);
            return;
        }
        if((llGetObjectDesc()=="")||(llGetObjectDesc()=="(No Description)")){
            if(llGetLinkPrimitiveParams(2,[PRIM_DESC])!=[""]){
                llSetObjectDesc(llList2String(llGetLinkPrimitiveParams(2,[PRIM_DESC]),0));//子プリム１のDESCをコピー
            }else{
                llSetObjectDesc("A");
            }
        }
        chnlname=llGetObjectDesc();
        dlgchnl=(integer)llFrand(1000000);
        lsnnum=llListen(dlgchnl,"",llGetOwner(),"");
        llDialog(llGetOwner(),DLG_POSMEMORY,["POSMEMORY","キャンセル"],dlgchnl);
        timer_failed_msg="ダイアログの時間切れです。";
        llSetTimerEvent(60);
    }
	touch_start(integer num){
		touchcnt=0;
	}
	touch(integer num){
		if(llDetectedKey(0)!=llGetOwner()){return;}
		++touchcnt;
		if(touchcnt==100){
			llListenRemove(lsnnum);
			dlgchnl=(integer)llFrand(1000000);
			lsnnum=llListen(dlgchnl,"",llGetOwner(),"");
			if(PosMemoryFlg){
				llDialog(llGetOwner(),DLG_POSSET,["POSSET","キャンセル"],dlgchnl);
			}else{
				llDialog(llGetOwner(),DLG_POSMEMORY,["POSMEMORY","キャンセル"],dlgchnl);
			}
			timer_failed_msg="ダイアログの時間切れです。";
			llSetTimerEvent(60);
		}
	}

    listen(integer chnl,string name,key id,string msg){
        if(chnl==dlgchnl){
            if((msg=="POSMEMORY")||(msg=="POSSET")){
                llSetTimerEvent(0);
                lsnnum_getrezzerinfo=llListen(COMMON_CHANNEL,"","","");
                llShout(COMMON_CHANNEL,llGetObjectDesc()+",GET_FLAGINFO");
                llOwnerSay("☆PosFlagの位置を確認中...");
                timer_failed_msg="〔×エラー〕PosFlagが見つかりませんでした。\nチャンネル設定、もしくはPosFlagとの距離が100ｍを超えていないかご確認下さい。";
                llSetTimerEvent(30);
                llListenRemove(lsnnum_acceptburning);
            }
            if(msg=="キャンセル"){
				llOwnerSay("キャンセルしました。");
			}
        }
		
        if(chnl==COMMON_CHANNEL){//chnlname+",FLAG_INFO,"+(string)llGetPos()+","+(string)llGetRot()
            list tmplist=llCSV2List(msg);
            chnlname=llList2String(tmplist,0);          //チャンネル名取得
            if(chnlname!=llGetObjectDesc()){return;}
            if(llList2String(tmplist,1)!="FLAG_INFO"){return;}
            llListenRemove(lsnnum_getrezzerinfo);
            rezzer_pos=(vector)llList2String(tmplist,2);
            rezzer_rot=(rotation)llList2String(tmplist,3);
            llOwnerSay("OK");
			if(!PosMemoryFlg){
				PosMemoryFlg=TRUE;
				llOwnerSay("☆POSMEMORYを開始します・・・");
				llMessageLinked(LINK_SET,0,"POSMEMORY",(string)rezzer_pos+"&"+(string)rezzer_rot);				
			}else{
				PosSetFlg=TRUE;
				llOwnerSay("☆POSSETを開始します・・・");
				llMessageLinked(LINK_SET,0,"POSSET",(string)rezzer_pos+"&"+(string)rezzer_rot);
			}
			llSleep(5);
			llOwnerSay("完了しました");
        }
    }
    timer(){
        llSetTimerEvent(0);
        llOwnerSay(timer_failed_msg);
    }
}