<?php

/**
 * Race
 *  
 * @author wilsonmu
 * @version 
 */

require_once ('App_Db_Table_Abstract.php');

class Item extends App_Db_Table_Abstract
{
	protected $_use_adapter = "sc";
	protected $_name = 'sc_items';
	protected $_primary = array("item_ident");
	protected $_cols = array(
		'item_ident'    	=> 'item_ident',
		'item_name'  		=> 'item_name',
		'long_name'  		=> 'long_name',
		'category'  		=> 'category',
		'description'  		=> 'description',
		'crystals'  		=> 'crystals',
		'vespene'  		=> 'vespene',
		'max'  			=> 'max',
		'required_level'  	=> 'required_level',
		'image'  		=> 'image',
		'add_date'		=> 'add_date'
	);

	public function getItemList($fetch=false)
	{
		$select = $this->select()
			->order('long_name');

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getCategoryList($fetch=false)
	{
		$select = $this->select()
			->distinct()
			->from(array("i" => "sc_items"), "category")
			->order('category');

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getItemListForCategory($category, $fetch=false)
	{
		$select = $this->select()
			->where('category = ?', $category)
			->order('long_name');

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getItemListForName($name, $fetch=false)
	{
		$select = $this->select()
			->where('item_name like ?', '%' . $name . '%')
			->order('long_name');

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getItemForIdent($ident)
	{
		$select = $this->select()
			->where('item_ident = ?', $ident);

		return $this->fetchRow($select);
	}

	public function getItemForName($name)
	{
		$select = $this->select()
			->where('item_name like ?', '%' . $name . '%');

		return $this->fetchRow($select);
	}
}
