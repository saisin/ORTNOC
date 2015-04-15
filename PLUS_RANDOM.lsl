//  #PLUS_RANDOM
//■ぶつかるとリンクされたコントローラーのどれか１つをRUNします。
//■３つのコントローラーをリンクしてこれを入れてください。

default{
	state_entry(){}
	collision_start(integer num){
		if(llDetectedKey(0)!=llGetOwner()){
			integer rnd=llFloor(llFrand(3));
			llMessageLinked(rnd,rnd,"RUN","");
		}
	}
}