//  #PLUS_COLLISION
//■人やモノとぶつかると発動する。

default{
	state_entry(){}
	collision_start(integer num){
		llMessageLinked(LINK_THIS,llGetLinkNumber(),"RUN","");
	}
}