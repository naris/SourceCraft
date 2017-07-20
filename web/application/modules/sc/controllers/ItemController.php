<?php

/**
 * ItemController
 * 
 * @author
 * @version 
 */

require_once 'Zend/Controller/Action.php';

require_once 'Item.php';

class Sc_ItemController extends Zend_Controller_Action
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
		if ($this->getRequest()->getMethod() == 'POST')
		{
			$item = $this->getRequest()->getParam('item');
			if ($item)
			{
				$this->_redirect('/sc/item/match/name/' . urlencode($item));
			}
			else
			{
				$category = $this->getRequest()->getParam('category');
				if ($category)
				{
					$this->_redirect('/sc/item/match/category/' . urlencode($category));
				}
				else
				{
					$list_item = $this->getRequest()->getParam('list_item');
					if ($list_item)
					{
						$this->_redirect('/sc/item/list');
					}
					else
					{
						$this->showAction();
					}
				}
			}
		}
		else
		{
			// Not a POST request, show find item form
			$view = $this->initView();
			$this->render();
		}
	}

	public function showAction()
	{
		$ident = $this->getRequest()->getParam('ident');
		if ($ident)
		{
			$item_table = new Item();
			$view = $this->initView();
			$item = $item_table->getItemForIdent($ident);
			if ($item)
			{
				$view->item = $item;
			}
			else
			{
				$view->error = 'Item Ident ' . $ident . ' was not found';
				$this->render();
				return;
			}
		}
		else
		{
			$name = $this->getRequest()->getParam('name');
			if ($name)
			{
				$item_table = new Item();
				$view = $this->initView();
				$item_rowset = $item_table->getItemListForName($name, true);
				$item_count = count($item_rowset);
				if ($item_count == 1)
				{
					$item = $item_rowset->current();
					$ident = $item->item_ident;
					$view->item = $item;
				}
				else if ($item_count > 1)
				{
					$this->_forward('match', 'item', 'sc',
						array('name' => $name));
					return;
				}
				else
				{
					$view->error = 'Item ' . $name . ' was not found';
					$this->render();
					return;
				}
			}
			else
			{
				$category = $this->getRequest()->getParam('category');
				if ($category)
				{
					$item_table = new Item();
					$view = $this->initView();
					$item_rowset = $item_table->getItemListForCategory($category, true);
					$item_count = count($item_rowset);
					if ($item_count == 1)
					{
						$item = $item_rowset->current();
						$ident = $item->item_ident;
						$view->item = $item;
					}
					else if ($item_count > 1)
					{
						$this->_forward('match', 'item', 'sc',
							array('category' => $category));
						return;
					}
					else
					{
						$view->error = 'There are no ' . $category . ' items!';
						$this->render();
						return;
					}
				}
			}
		}

		if (isset($item) && $item)
		{
			$this->render();
		}
		else
		{
			$this->_forward('list');
		}
	}

	public function matchAction()
	{
		$name = $this->getRequest()->getParam('name');
		if ($name)
		{
   			$item_table = new Item();
			$rowset = $item_table->getItemListForName($name, true);
			$count = count($rowset);
			if ($count > 1)
			{
				$view = $this->initView();
				$paginator = Zend_Paginator::factory($rowset);
				$paginator->setItemCountPerPage(25);
				$paginator->setCurrentPageNumber($this->_getParam('page'));
				$paginator->setView($view);
				$this->view->paginator = $paginator;
				$this->render();
			}
			elseif ($count == 1)
			{
				$this->_forward('show', 'item', 'sc',
						array('name' => $name));
			}
			else
			{
				$view = $this->initView();
				$view->error = 'No item matching ' . $name . ' was found';
				$this->render();
			}
		}
		else
		{
			$category = $this->getRequest()->getParam('category');
			if ($category)
			{
				$item_table = new Item();
				$rowset = $item_table->getItemListForCategory($category, true);
				$count = count($rowset);
				if ($count > 1)
				{
					$view = $this->initView();
					$paginator = Zend_Paginator::factory($rowset);
					$paginator->setItemCountPerPage(25);
					$paginator->setCurrentPageNumber($this->_getParam('page'));
					$paginator->setView($view);
					$this->view->paginator = $paginator;
					$this->view->category = $category;
					$this->render();
				}
				elseif ($count == 1)
				{
					$this->_forward('show', 'item', 'sc',
							array('category' => $category));
				}
				else
				{
					$view = $this->initView();
					$view->error = 'There are no ' . $category . ' items!';
					$this->render();
				}
			}
			else
			{
				$this->_forward('list');
			}
		}
	}

	public function listAction()
	{
		$view = $this->initView();
		$item_table = new Item();
		$paginator = Zend_Paginator::factory($item_table->getItemList());
		$paginator->setItemCountPerPage(25);
		$paginator->setCurrentPageNumber($this->_getParam('page'));
		$paginator->setView($view);
		$this->view->paginator = $paginator;
		$this->render();
	}
}
?>
