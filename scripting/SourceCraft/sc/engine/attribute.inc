/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: attribute.inc
 * Description: Attributes
 * Author(s): -=|JFH|=-Naris
 */

new Handle:attrArray = INVALID_HANDLE;
new Handle:attrTrie[MAXPLAYERS+1]  = INVALID_HANDLE;
new Handle:attrDataArray[MAXPLAYERS+1]  = INVALID_HANDLE;

bool:HasAttribute(client, const String:attrName[], &Handle:data)
{
    if (attrTrie[client] != INVALID_HANDLE)
        return GetTrieValue(attrTrie[client], attrName, data);
    else
        return false;
}

bool:AssignAttribute(client, const String:attrName[], Handle:data)
{
    if (attrTrie[client] == INVALID_HANDLE)
        attrTrie[client] = CreateTrie();

    if (attrDataArray[client] == INVALID_HANDLE)
        attrDataArray[client] = CreateArray();

    new Handle:value = INVALID_HANDLE;
    if (GetTrieValue(attrTrie[client], attrName, value) && value != INVALID_HANDLE)
    {
        CloseHandle(value);

        new Handle:attrData = attrDataArray[client];
        if (attrData != INVALID_HANDLE)
        {
            new index = FindValueInArray(attrData, value);
            if (index >= 0)
                RemoveFromArray(attrData, index);
        }
    }

    PushArrayCell(attrDataArray[client], data);
    return SetTrieValue(attrTrie[client], attrName, data);
}

RemoveAttribute(client, const String:attrName[])
{
    if (attrTrie[client] != INVALID_HANDLE)
    {
        new Handle:value = INVALID_HANDLE;
        if (GetTrieValue(attrTrie[client], attrName, value) && value != INVALID_HANDLE)
        {
            CloseHandle(value);

            new Handle:attrData = attrDataArray[client];
            if (attrData != INVALID_HANDLE)
            {
                new index = FindValueInArray(attrData, value);
                if (index >= 0)
                    RemoveFromArray(attrData, index);
            }
        }

        return RemoveFromTrie(attrTrie[client], attrName);
    }
    else
        return false;
}

RemoveAllAttributes(client)
{
    new Handle:attrData = attrDataArray[client];
    if (attrData != INVALID_HANDLE)
    {
        new size = GetArraySize(attrData);
        for (new i =0; i < size; i++)
        {
            new Handle:data = Handle:GetArrayCell(attrData, i);
            if (data != INVALID_HANDLE)
                CloseHandle(data);
        }
        ClearArray(attrData);
    }

    if (attrTrie[client] != INVALID_HANDLE)
        ClearTrie(attrTrie[client]);
}

CreateAttribute(const String:name[])
{
    new attrId = -1;
    if (attrArray == INVALID_HANDLE)
        attrArray = CreateArray(ByteCountToCells(NAME_STRING_LENGTH));
    else        
        attrId = FindStringInArray(attrArray, name);

    if (attrId < 0)
        attrId = PushArrayString(attrArray,name);

    return attrId;
}

bool:HasAttributeId(client, attrId, &Handle:data)
{
    if (attrTrie[client] != INVALID_HANDLE)
    {
        decl String:attrName[NAME_STRING_LENGTH];
        if (GetArrayString(attrArray, attrId, attrName, sizeof(attrName)))
            return GetTrieValue(attrTrie[client], attrName, data);
        else
            return false;
    }
    else
        return false;
}

bool:AssignAttributeId(client, attrId, Handle:data)
{
    decl String:attrName[NAME_STRING_LENGTH];
    if (GetArrayString(attrArray, attrId, attrName, sizeof(attrName)))
        return AssignAttribute(client, attrName, data);
    else
        return false;
}

RemoveAttributeId(client, attrId)
{
    decl String:attrName[NAME_STRING_LENGTH];
    if (GetArrayString(attrArray, attrId, attrName, sizeof(attrName)))
        return RemoveAttribute(client, attrName);
    else
        return false;
}

#if 0

//genericSkillData is an array or trie that modifies behavior of that generic skill
//if NEW HANDLE is passed, OLD one will be closed (i e during create race call after race has been created like on a map change)
//this means you CAN recreate new handles and pass them, the old one will be closed

    // Generic Skills from War3Source_Engine_RaceClass
    CreateNative("War3_CreateGenericSkill",NWar3_CreateGenericSkill);
    CreateNative("War3_UseGenericSkill",NWar3_UseGenericSkill);
    CreateNative("W3_GenericSkillLevel",NW3_GenericSkillLevel);
// Generic Skills

new genericskillcount=0;
enum GenericSkillClass
{
	String:cskillname[32], 
	redirectedfromrace[32], //theset start from 0!!!!
	redirectedfromskill[32],
	redirectedcount,
	Handle:raceskilldatahandle[32], //handle the customer races passed us
}

//55 generic skills
new GenericSkill[55][GenericSkillClass];

native War3_CreateGenericSkill(String:gskillname[]);

public NWar3_CreateGenericSkill(Handle:plugin,numParams)
{
	new String:tempgenskillname[32];
	GetNativeString(1,tempgenskillname,32);
	
	//find existing
	for(new i=1;i<=genericskillcount;i++)
    {
		if(StrEqual(tempgenskillname,GenericSkill[i][cskillname]))
        {
			return i;
		}
	}
	
	//no existing found, add 
	genericskillcount++;
	GetNativeString(1,GenericSkill[genericskillcount][cskillname],32);
	return genericskillcount;
}

native War3_UseGenericSkill(raceid,String:gskillname[],Handle:genericSkillData,String:yourskillname[],
                            String:untranslatedSkillDescription[]="ERR: No Skill Description Entered.",
                            bool:translated=false,bool:isUltimate=false,maxskilllevel=DEF_MAX_SKILL_LEVEL,any:...);

public NWar3_UseGenericSkill(Handle:plugin,numParams)
{
	new raceid=GetNativeCell(1);
	new String:genskillname[32];
	GetNativeString(2,genskillname,sizeof(genskillname));
	new Handle:genericSkillData=Handle:GetNativeCell(3);
	//start from 1
	for(new i=1;i<=genericskillcount;i++)
    {
		//DP("1 %s %s ]",genskillname,GenericSkill[i][cskillname]);
		if(StrEqual(genskillname,GenericSkill[i][cskillname]))
        {
			//DP("2");
			if(raceid>0)
            {
				//DP("3");
				new String:raceskillname[2001];
				new String:raceskilldesc[2001];
				GetNativeString(4,raceskillname,sizeof(raceskillname));
				GetNativeString(5,raceskilldesc,sizeof(raceskilldesc));
				
				//new bool:istranaslated=GetNativeCell(6);
				
				//native War3_UseGenericSkill(raceid,String:gskillname[],Handle:genericSkillData,String:yourskillname[],String:untranslatedSkillDescription[],bool:translated=false,bool:isUltimate=false,maxskilllevel=DEF_MAX_SKILL_LEVEL,any:...);

				new bool:isult=GetNativeCell(7);
				new tmaxskilllevel=GetNativeCell(8);
				
				//W3Log("add skill %s %s",skillname,skilldesc);
				
				new newskillnum;
				newskillnum	= AddRaceSkill(raceid,raceskillname,raceskilldesc,isult,tmaxskilllevel);
                /*
				if(istranaslated){
					skillTranslated[raceid][newskillnum]=true;	
				}
                */
				
				//check that the data handle isnt leaking
				new genericcustomernumber=GenericSkill[i][redirectedcount];
				for(new j=0;j<genericcustomernumber;j++)
                {
					if( GenericSkill[i][redirectedfromrace][j]==raceid &&
					    GenericSkill[i][redirectedfromskill][j]==newskillnum)
                    {
						if(GenericSkill[i][raceskilldatahandle][j]!=INVALID_HANDLE &&
                           GenericSkill[i][raceskilldatahandle][j] !=genericSkillData)
                        {
							//DP("ERROR POSSIBLE HANDLE LEAK, NEW GENERIC SKILL DATA HANDLE PASSED, CLOSING OLD GENERIC DATA HANDLE");
							CloseHandle(GenericSkill[i][raceskilldatahandle][j]);
							GenericSkill[i][raceskilldatahandle][j]=genericSkillData;
						}	
					}
					
				}
				
				//first time creating the race
				//if(ignoreRaceEnd==false)
				{
					//variable args start at 8
                    /*
					for(new arg=9;arg<=numParams;arg++){
					
						GetNativeString(arg,raceSkillDescReplace[raceid][newskillnum][raceSkillDescReplaceNum[raceid][newskillnum]],64);
						raceSkillDescReplaceNum[raceid][newskillnum]++;
					}
					
					SkillRedirected[raceid][newskillnum]=true;
					SkillRedirectedToSkill[raceid][newskillnum]=i;
                    */
					
					
					GenericSkill[i][raceskilldatahandle][genericcustomernumber]=genericSkillData;
					GenericSkill[i][redirectedfromrace][GenericSkill[i][redirectedcount]]=raceid;
					
					GenericSkill[i][redirectedfromskill][GenericSkill[i][redirectedcount]]=newskillnum;
					GenericSkill[i][redirectedcount]++;
					//DP("FOUND GENERIC SKILL %d, real skill id for race %d",i,newskillnum);
				}
				
				return newskillnum;
					
			}
		}
	}
	LogError("NO GENREIC SKILL FOUND");
	return 0;
}

native W3_GenericSkillLevel(client,gskill,&Handle:genericSkillData);

public NW3_GenericSkillLevel(Handle:plugin,numParams)
{
    new client=GetNativeCell(1);
    new genericskill=GetNativeCell(2);
    new count=GenericSkill[genericskill][redirectedcount];
    new found=0;
    new level=0;
    new reallevel=0;
    new customernumber=0;
    //DP("customer count %d genericskill %d",count,genericskill);
    for(new i=0;i<count;i++)
    {
        level = War3_GetSkillLevel( client, GenericSkill[genericskill][redirectedfromrace][i], GenericSkill[genericskill][redirectedfromskill][i]);
        //DP("real skill %d %d %d",GenericSkill[genericskill][redirectedfromrace][i], GenericSkill[genericskill][redirectedfromskill][i],level);
        if(level)
        { 
            found++;
            reallevel=level;
            customernumber=i;
        }
    }
    if(found>1)
    {
        LogError("ERR FOUND MORE THAN 1 GERNIC SKILL MATCH");
        return 0;
    }
    SetNativeCellRef(3,GenericSkill[genericskill][raceskilldatahandle][customernumber]);
    return reallevel;

}

#endif
