//  #TIMER_RUN
//■タイマーで数秒置きに発動する。
//※注意※
//タイマーは非常に負荷がかかる為、必要最低限のご使用をお願いします。
//・常時設置するものは最低でも１０秒以上の間隔をあけてください。
//・臨時のものは最低でも0.3秒以上の間隔をあけてください。

default{
	state_entry(){
		llSetTimerEvent(10);//ここを調整して下さい。
	}
	timer(){
		llMessageLinked(LINK_THIS,llGetLinkNumber(),"RUN","");
	}
}