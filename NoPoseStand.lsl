key sit_ava;
integer lsnnum;
integer lsnchnl;
float sit_offset=-0.35;
float nowheight=1.6;
default {
state_entry(){
llSitTarget(<0,0,sit_offset+nowheight>,ZERO_ROTATION);
}
touch_start(integer num){
if(llDetectedKey(0)==sit_ava){
llListenRemove(lsnnum);
lsnchnl=(integer)llFrand(-500000);
lsnnum = llListen(lsnchnl,"",sit_ava,"");
llDialog(sit_ava,"高さを調節できます。",[" ","キャンセル"," ","-0.05","-0.1 ","-0.2","+0.05","+0.1 ","+0.2"],lsnchnl);
}
}
changed(integer change){
if (change & CHANGED_LINK){
sit_ava = llAvatarOnSitTarget();
if (sit_ava != NULL_KEY) {
llRequestPermissions(sit_ava,PERMISSION_TRIGGER_ANIMATION);
llStopAnimation("sit");
llStartAnimation("stand");
string anim;
anim=llGetInventoryName(INVENTORY_ANIMATION,0);
if(anim!=""){
llStartAnimation(anim);
}
//llSetAlpha(0.01,ALL_SIDES);
llSetTexture(TEXTURE_TRANSPARENT,ALL_SIDES);
}else{
//llSetAlpha(1,ALL_SIDES);
llSetTexture(TEXTURE_BLANK,ALL_SIDES);
llSetTexture("7fc25b1b-59b5-234e-0e63-a7fbb7d57e96",0);
}
}
}
listen(integer chnl,string name,key id,string msg){
if(msg=="キャンセル"){
llListenRemove(lsnnum);
return;
}
integer ava_linknum=llGetNumberOfPrims();
if(llGetLinkName(ava_linknum)==name){
nowheight+=(float)msg;
llSetLinkPrimitiveParams(llGetNumberOfPrims(),[PRIM_POSITION,<0,0,nowheight>]);
llSitTarget(<0,0,sit_offset+nowheight>,ZERO_ROTATION);
}
}
}