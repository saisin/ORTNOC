//##########################################
//
//  CONTRO - #ADD_DANCE
//
// ver.2.0[2015/4/1]
//##########################################
//[ �X�N���̓��� ]
// �_���X�p�̃X�N���v�g
// �P�I���Ǝ��̃A�j���������Đ�����B�d���͂ł��Ȃ��B
//
//
// [ �R���g���[���[�R�}���h ]
// ___,DANCE_REGISTRY,�A�o�^�[��,�o�^�i���o�[                                    //�ŏ��ɃA�o�^�[��o�^����
// ___,DANCE_START,�A�j���[�V������,����,�o�^�i���o�[(1),�o�^�i���o�[(2)   //���ԕ��A�j���[�V��������B0���ƃ��[�v
// ___,DANCE_STOP,�o�^�i���o�[(1),�o�^�i���o�[(2)                                    //�_���X���~�߂�
//
//
//====================================================
//[input]
// (link_message) DANCE_REGISTRY&avatar_name&registry_number
// (link_message) DANCE_START&anim_name&anim_time&registry_number&registry_number
// (link_message) DANCE_STOP&registry_number&registry_number
//
//##########################################8
list NUMLIST=["0","1","2","3","4","5","6","7","8","9"]; //�����`�F�b�N�p
integer LNKMSGCHNL=466938182; //�����N���b�Z�[�W�ŒʐM����`�����l��
string MSG_COULDNT_FIND_AVATAR="����96m�ȓ��Ɍ�����܂���ł����B";
string MSG_PERMISSION_ERROR="�A�j���[�V�����̌���������܂���BDANCE_REGISTRY�R�}���h�Ō������擾���Ă��������B";

integer my_script_number;                //���̃X�N���v�g�̔ԍ�
string my_avatar_name;                    //���̃X�N���v�g���ێ����Ă���A�o�^�[��
key my_avatar_key;                    //���̃X�N���v�g���ێ����Ă���A�o�^�[�L�[
string nowanim;                      //���s���̃A�j���[�V����
list next_anim_stlist;                 //�Đ�����A�j���[�V�����̃X�g���C�h���X�g(�A�j���[�V������,(float)����)

string tgt_name;
integer tgt_number;              //�v������Ă��鑀���i���o�[
integer perm;                    //�A�j���[�V�����̃p�[�~�b�V�����t���O

integer i;
//==========================================================
AddAnimation(string anim,float second){
    if(nowanim==""){
        nowanim=anim;
        llStartAnimation(anim);
        //�^�C�}�[�Z�b�g
        llSetTimerEvent(second);
    }else{
        next_anim_stlist+=[anim,second];
    }
}

NextAnimation(){
    llStopAnimation(nowanim);
    if(next_anim_stlist!=[]){
        if(nowanim==llList2String(next_anim_stlist,0)){llSleep(0.1);}
        nowanim=llList2String(next_anim_stlist,0);
        llStartAnimation(nowanim);
        llSetTimerEvent(llList2Float(next_anim_stlist,1));
        next_anim_stlist=llDeleteSubList(next_anim_stlist,0,1);
    }
}
//==========================================================
default{
    on_rez(integer num){
        llResetScript();
    }
    state_entry(){
        //my_script_number�擾�J�n
        string tmp=llGetScriptName();
        integer index=llStringLength(tmp)-1;
        for(i=0;i<4;i++){
            string check=llGetSubString(tmp,index,index);
            if(llListFindList(NUMLIST,(list)check)!=-1){index--;}else{i=10;}
        }
        if(index==llStringLength(tmp)){
            my_script_number=0;}else{
            my_script_number=(integer)llGetSubString(tmp,index,llStringLength(tmp));
        }
    }
    link_message(integer sender,integer num,string msg,key id)
    {
        //-----------------------------------------------------------------------------
        //msg�ɃR�}���h���ƕ����̃p�����[�^�[��&��؂�ő����Ă���̂�
        //�������ă��X�gdata_list�ɕۑ�����B
        //�R�}���h�����`�F�b�N���čD���ȏ��������s����B
        //-----------------------------------------------------------------------------
        if(num!=0){
            return;
        }
        list data_list=llParseString2List(msg,["&"],[]);
        string command=llList2String(data_list,0);//��r�p�ɃR�}���h�͕ϐ��ɓ����
        
        if(command=="DANCE_REGISTRY"){//DANCE_REGISTRY,AVANAME,NUMBER
            if((integer)llList2String(data_list,2)!=my_script_number){return;}
            llSetTimerEvent(0);//�Ƃ肠�����A�S�ăX�g�b�v���ă��Z�b�g
            if(perm&PERMISSION_TRIGGER_ANIMATION){
                if(nowanim!=""){
                    llStopAnimation(nowanim);
                }
            }
            nowanim="";
            next_anim_stlist=[];
            tgt_name=llList2String(data_list,1);
            if(my_avatar_name!=tgt_name){//�㏑���̏ꍇ���s
                if(tgt_name==llKey2Name(llGetOwner())){//�I�[�i�[�Ȃ炻�̂܂܃A�j�������擾�ցA�����łȂ��Ȃ�Z���T�[�ŒT��
                    llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION);
                }else{
                    if(tgt_name==""){
                        my_avatar_key="";
                        my_avatar_name="";
                        llRequestPermissions("1612e679-795f-4e53-ac8f-f01c8351e854",PERMISSION_TRIGGER_ANIMATION);
                    }else{
                        llSensor(tgt_name,"",AGENT,96,PI);
                    }
                }
            }
        }else if(command=="DANCE_START"){//DANCE_START,DANCENAME,TIME,NUMBER,NUMBER
            if(llListFindList(llList2List(data_list,3,-1),(list)((string)my_script_number))==-1){
                return;
            }
            if(perm&PERMISSION_TRIGGER_ANIMATION){
                AddAnimation(llList2String(data_list,1),(float)llList2String(data_list,2));
            }
        }else if(command=="DANCE_STOP"){//DANCE_STOP,NUMBER,NUMBER
            if(llListFindList(data_list,(list)((string)my_script_number))==-1){return;}
            if(perm&PERMISSION_TRIGGER_ANIMATION){
                llSetTimerEvent(0);
                if(nowanim!=""){llStopAnimation(nowanim);}
                nowanim="";
                next_anim_stlist=[];
            }
        }
    }
    run_time_permissions(integer tmp){
        perm=tmp;
        if(perm&PERMISSION_TRIGGER_ANIMATION){
            my_avatar_key=llGetPermissionsKey();
            my_avatar_name=llKey2Name(my_avatar_key);
        }
    }
    timer(){
        llSetTimerEvent(0);
        NextAnimation();
    }
    sensor(integer num){
        llRequestPermissions(llDetectedKey(0),PERMISSION_TRIGGER_ANIMATION);
    }
    no_sensor(){
        llOwnerSay(tgt_name+MSG_COULDNT_FIND_AVATAR);
    }
}