//  #SENSOR_RUN
//■センサーで人やモノを感知したら発動する。
//※注意※
//センサーは非常に負荷がかかる為、必要最小限のご使用をお願いします。

default{
	state_entry(){
		llSensorRepeat("人の名前","",AGENT,96,PI,10);//ここを調整して下さい。
	}
	sensor(){
		llMessageLinked(LINK_THIS,llGetLinkNumber(),"RUN","");
	}
}