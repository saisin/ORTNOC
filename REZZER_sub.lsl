//##########################################
//
//  CONTRO - #REZZER_sub
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
list rezzed_obj_que=[];
//==============================================