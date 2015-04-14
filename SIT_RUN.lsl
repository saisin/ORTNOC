//  #SIT_RUN
//■座るとRUNする。複数座る場合座るたびに発動。

integer avatar_number;//座っているアバター人数
integer i;
default{
	state_entry(){}
	changed(integer chg){
		if(chg&CHANGED_LINK){
			if(avatar_number<llGetNumberOfPrims()-llGetObjectPrimCount()){
				llMessageLinked(LINK_THIS,llGetLinkNumber(),"RUN","");
			}
			avatar_number=llGetNumberOfPrims()-llGetObjectPrimCount();
		}
	}
}