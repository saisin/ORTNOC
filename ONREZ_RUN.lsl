//  #ONREZ_RUN
//■REZすると発動する。

default{
	state_entry(){}
	on_rez(integer num){
		llMessageLinked(LINK_THIS,llGetLinkNumber(),"RUN","");
	}
}