//  #SENSOR_RUN
//■センサーで数秒置きに発動する。
//※注意※
//センサーは非常に負荷がかかる為、必要最小限のご使用をお願いします。
//・常時設置するものは最低でも10秒以上の間隔をあけてください。
//・臨時のものは最低でも0.5秒以上の間隔をあけてください。

default{
	state_entry(){
		llSensorRepeat("","",AGENT,96,PI,20);//ここを調整して下さい。
	}
	timer(){
		llMessageLinked(LINK_THIS,llGetLinkNumber(),"RUN","");
	}
}