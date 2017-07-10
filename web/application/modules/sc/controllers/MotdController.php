<?php

/**
 * IndexController - The default controller class
 * 
 * @author
 * @version 
 */

require_once 'Zend/Controller/Action.php';

require_once 'Server.php';
require_once 'ForumUser.php';

class Sc_MotdController extends Zend_Controller_Action 
{
	/**
	 * Overriding the init method to also load the session from the registry
	 *
	 */
	public function init()
	{
		parent::init();
		$this->session = Zend_Registry::get('session');
	}

	public function initView()
	{
		$view = parent::initView();
		if (isset($this->session))
		{
			$view->session = $this->session;        
		}
		return $view;
	}

	public function indexAction()
	{
		// show form
		$view = $this->initView();
		$user_table = new ForumUser();
		$server_table = new Server();
		//$this->view->backers = $user_table->getFinancialBackers(true);
		$this->view->active_servers = $server_table->getActiveServerList(true);
		$this->render();
	}
}
