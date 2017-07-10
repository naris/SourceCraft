
#if defined _stocks_precache_included
 #endinput
#endif
#define _stocks_precache_included

/**
 * Returns UNIX time (integer)
 */ 
stock NOW(){
	return GetTime();
}
/**
 * returns the larger integer of the two
 */ 
stock IntMax(one,two){
	return  one>two?one:two;
}
