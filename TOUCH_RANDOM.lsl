//  #TOUCH_RUN
//■他人がタッチすると発動する。（重複防止の為、オーナーは除く）

default{
	state_entry(){}
	touch_start(integer num){
		if(llDetectedKey(0)!=llGetOwner()){
			integer rnd=llFloor(llFrand(3));
			llMessageLinked(rnd,rnd,"RUN","");
		}
	}
}