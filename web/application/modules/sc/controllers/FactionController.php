<?php

/**
 * FactionController
 * 
 * @author
 * @version 
 */

require_once 'Zend/Controller/Action.php';

require_once 'Faction.php';
require_once 'Upgrade.php';
require_once 'Race.php';

class Sc_FactionController extends Zend_Controller_Action
{
    /**
     * @var Zend_Session_Namespace
     */
    protected $session = null;

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
    
	/**
	 * The default action - show the home page
	 */
	public function indexAction()
	{
		$this->_forward('list');
	}
	
	public function findAction()
	{
		$this->showAction();
	}
	
	public function showAction()
	{
		$factionId = $this->getRequest()->getParam('id');
		if ($factionId)
		{
			$faction_table = new Faction();
			$view = $this->initView();
			$faction = $faction_table->getFaction($factionId);
			if ($faction)
			{
				$view->faction 	= $faction;

				$race_table 	= new Race();
				$view->races 	= $race_table->getRaceListForFaction($factionId, true);

				$upgrade_table 	= new Upgrade();
				$view->upgrades = $upgrade_table->getUpgradeListForFaction($factionId, true);
			}
			else
			{
				$view->error = 'Faction ' . $factionId . ' was not found';
			}
			$this->render();
		}
		else
		{
			$this->_forward('list');
		}
	}
	
	public function listAction()
	{
		$view = $this->initView();
		$faction_table = new Faction();
		$has_races = $this->getRequest()->getParam('has_races');
		$paginator = Zend_Paginator::factory($faction_table->getFactionList($has_races));
		$paginator->setItemCountPerPage(4);
		$paginator->setCurrentPageNumber($this->_getParam('page'));
		$paginator->setView($view);
		$this->view->paginator = $paginator;
		$this->render();
	}
}
?>

