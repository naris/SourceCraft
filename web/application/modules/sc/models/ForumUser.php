<?php

/**
 * ForumUser
 *  
 * @author wilsonmu
 * @version 
 */

require_once ('App_Db_Table_Abstract.php');

class ForumUser extends App_Db_Table_Abstract
{
	protected $_use_adapter = "user";
	protected $_name = 'phpbb_users';
	protected $_primary = array("user_id");
	protected $_cols = array(
		'user_id'    	=> 'user_id',
		'user_type'    	=> 'user_type',
		'group_id'  	=> 'group_id',
		'username'	=> 'username',
		'user_password'  => 'user_password',
		'user_rank'  	=> 'user_rank',
		'user_colour'  	=> 'user_colour'
	);

	public function getUserList($fetch=false)
	{
		$select = $this->select()
			->order('username');

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getUsersInGroup($groupid, $fetch=false)
	{
		$select = $this->select()
			->setIntegrityCheck(false)
			->from(array('u' => 'phpbb_users'),
				array('username'))
			->join(array('g' => 'phpbb_user_group'),
				"g.user_id = u.user_id")
			->where("groupnumber = ?", groupid)
			->order('username');

		return $fetch ? $this->fetchAll($select) : $select;		
	}

	public function getFinancialBackers($fetch=false)
	{
		return $this->getUsersInGroup(34, $fetch);
	}

	public function getMembers($fetch=false)
	{
		return $this->getUsersInGroup(26, $fetch);
	}

	public function getSeniorAdmins($fetch=false)
	{
		return $this->getUsersInGroup(3, $fetch);
	}

	public function getAdmins($fetch=false)
	{
		return $this->getUsersInGroup(25, $fetch);
	}
}
