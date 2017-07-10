<?php

/**
 * RaceList
 *  
 * @author wilsonmu
 * @version 
 */

require_once ('App_Db_Table_Abstract.php');

class RaceList extends App_Db_Table_Abstract
{
	protected $_use_adapter = "sc";
	protected $_name = 'sc_race_list';
	protected $_primary = array("race_ident");
	protected $_cols = array(
		'race_ident'    	=> 'race_ident',
		'race_name'  		=> 'race_name',
		'long_name'  		=> 'long_name',
		'parent_name'  		=> 'parent_name',
		'faction'  		=> 'faction',
		'type'  		=> 'type',
		'description'  		=> 'description',
		'image'  		=> 'image',
		'required_level'  	=> 'required_level',
		'tech_level'  		=> 'tech_level',
		'add_date'		=> 'add_date',
		'faction_name'		=> 'faction_name',
		'parent_long_name'	=> 'parent_long_name'
	);
}
