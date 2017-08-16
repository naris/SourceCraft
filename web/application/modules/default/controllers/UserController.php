<?php

/**
 * SourceCraft user controller - Handling user related actions - currently log in and
 * log out.
 * 
 */

require_once 'Zend/Controller/Action.php';
require_once 'Zend/Registry.php';
require_once 'Zend/Session.php';
require_once 'xPaw/SteamID.php';

//require_once 'Zend/Auth/Adapter/DbTable.php';
//require_once 'steamauth/openid.php';

//Include Hybridauth's basic autoloader
include 'hybridauth/src/autoload.php';

//Import Hybridauth's namespace
use Hybridauth\Hybridauth;

class UserController extends Zend_Controller_Action
{
    /**
     * User session
     *
     * @var Zend_Session_Namespace
     */
    protected $session = null;

	// Build configuration array
	protected $config = [
		//Location where to redirect users once they authenticate with Steam
		'callback' => '/sc/player/show/user/',

		// Steam api credentials
		'keys' => [
			'key' => '', // Required: your Steam api key
		]
	];

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
     * Default action - if logged in, log out. If logged out, log in.
     *
     */
    public function indexAction()
    {
        if ($this->session->authenticated) {
            $this->_forward('logout');
        } else {
            $this->_forward('login');
        }
    }

    /**
     * Log in - show the login form or handle a login request
     * 
     * @todo Implement real authentication
     */
    public function loginAction()
    {
		try
		{
			// Instantiate Steam's adapter directly
			$adapter = new Hybridauth\Provider\Steam($config);

			// Attempt to authenticate the user with Steam
			$adapter->authenticate();

			// Returns a boolean of whether the user is connected with Steam
			$isConnected = $adapter->isConnected();

			// Retrieve the user's profile
			$userProfile = $adapter->getUserProfile();

			// Inspect profile's public attributes
			// var_dump($userProfile);
			
			$s = new SteamID($userProfile->identifier);
			$this->session->steamid = $s->RenderSteam2();
			$this->session->steamid3 = $s->RenderSteam3();
			$this->session->steamid64 = $s->ConvertToUInt64();
			
			$this->session->username = $userProfile->displayName;
			$this->session->firstName = $userProfile->firstName;
			$this->session->photoURL = $userProfile->photoURL;
			$this->session->profileURL = $userProfile->profileURL;
			$this->session->description = $userProfile->description;
			$this->session->country = $userProfile->country;
			$this->session->region = $userProfile->region;

			/*
			require_once 'SteamConfig.php';
			$openid = new LightOpenID($steamauth['domainname']);
			
			if (!$openid->mode)
			{
				$openid->identity = 'http://steamcommunity.com/openid';
				//header('Location: ' . $openid->authUrl());
				$this->_forward($openid->authUrl());
			}
			elseif ($openid->mode == 'cancel')
			{
				//echo 'User has canceled authentication!';
				$view = $this->initView();
				$view->error = 'Authentication cancelled!';
				$this->render();
			}
			else
			{
				if ($openid->validate())
				{ 
					$id = $openid->identity;
					$ptn = "/^http:\/\/steamcommunity\.com\/openid\/id\/(7[0-9]{15,25}+)$/";
					preg_match($ptn, $id, $matches);

					$this->session->logged_in = true;
					try
					{
						$s = new SteamID($matches[1]);
						$this->session->steamid = $s->RenderSteam2();
						$this->session->steamid3 = $s->RenderSteam3();
						$this->session->steamid64 = $s->ConvertToUInt64();
						//$this->session->username = $this->session->steamid;
						
						if (!empty($steamauth['apikey']))
						{
							$url = file_get_contents("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=".$steamauth['apikey']."&steamids=".$matches[1]); 
							$content = json_decode($url, true);
							
							//$this->session->steamid = $content['response']['players'][0]['steamid'];
							$this->session->communityvisibilitystate = $content['response']['players'][0]['communityvisibilitystate'];
							$this->session->profilestate = $content['response']['players'][0]['profilestate'];
							$this->session->personaname = $content['response']['players'][0]['personaname'];
							$this->session->lastlogoff = $content['response']['players'][0]['lastlogoff'];
							$this->session->profileurl = $content['response']['players'][0]['profileurl'];
							$this->session->avatar = $content['response']['players'][0]['avatar'];
							$this->session->avatarmedium = $content['response']['players'][0]['avatarmedium'];
							$this->session->avatarfull = $content['response']['players'][0]['avatarfull'];
							$this->session->personastate = $content['response']['players'][0]['personastate'];
							$this->session->primaryclanid = $content['response']['players'][0]['primaryclanid'];
							$this->session->timecreated = $content['response']['players'][0]['timecreated'];
							$this->session->uptodate = time();
							
							if (isset($content['response']['players'][0]['realname']))
							{ 
								$this->session->realname = $content['response']['players'][0]['realname'];
								//$this->session->username = $this->session->realname;
							}
							else
							{
								$this->session->realname = "Real name not given";
								//$this->session->username = $this->session->personaname;
							}
						}
						
						$player_table = new Player();
						$player = $player_table->getPlayerForSteamid($this->session->steamid);
						if ($player)
						{
							$where = $player_table->getAdapter()->quoteInto('steamid = ?', $this->session->steamid);
							$this->session->username = empty($player->username) ? $player->name : $player->username;
						}

						//$this->_forward('profile');
						$this->_redirect('/sc/player/show/user/' . $username);
					}
					catch( InvalidArgumentException $e )
					{
						$view = $this->initView();
						$view->error = 'SteamID could not be parsed.';
						$this->render();
					}
				}
				else
				{
					//echo "User is not logged in.\n";
					$view = $this->initView();
					$view->error = 'Login failed, please try again';
					$this->render();
				}
			}
			*/
		}
		catch (ErrorException $e)
		{
			//echo $e->getMessage();
			$view = $this->initView();
			$view->error = $e->getMessage();
			$this->render();
		}
        catch (Exception $e)
        {
            //echo $e->getMessage();
            $view = $this->initView();
            $view->error = $e->getMessage();
            $this->render();
        }

	    /*
		if ($this->getRequest()->getMethod() != 'POST')
	    {
		    // Not a POST request, show log-in form
		    $view = $this->initView();
		    $this->render();
	    }
	    else
	    {
		    // Handle log-in form
		    $username = $this->getRequest()->getParam('user');
		    if ($username)
			    $password = $this->getRequest()->getParam('password');
		    else
		    {
			    $username = $this->getRequest()->getParam('suser');
			    $password = $this->getRequest()->getParam('spassword');
		    }

		    // setup Zend_Auth adapter for a database table
		    $dbAdapters = Zend_Registry::get('dbAdapters');
		    $authAdapter = new Zend_Auth_Adapter_DbTable($dbAdapters['user'],
		    						 'nuke_users',
		    						 'username',
		    						 'user_password',
		    						 'MD5(?)');

		    // Set the input credential values to authenticate against
		    $authAdapter->setIdentity($username);
		    $authAdapter->setCredential($password);

		    // do the authentication
		    $auth = Zend_Auth::getInstance();
		    $result = $auth->authenticate($authAdapter);
		    if ($result->isValid())
		    {
			    // success: store database row to auth's storage
			    // system. (Not the password though!)
			    $data = $authAdapter->getResultRowObject(null, 'password');
			    $auth->getStorage()->write($data);

			    Zend_Session::regenerateId();
			    $this->session->logged_in = true;
			    $this->session->username = $username;

			    $member_table = new Members();
			    $member = $member_table->getMember($username);
			    if ($member)
			    {
				    $this->session->steamid = 'STEAM_' . $member->steamid;
			    }
			    //$this->render();
			    $this->_redirect('/sc/player/show/user/' . $username);
		    }
		    else // Wrong user name / password
		    {
			    $view = $this->initView();
			    $view->user = $username;
			    $view->error = 'Wrong user name or password, please try again';
			    $this->render();
		    }
			*/
	    }
    }

    /**
     * Log out - delete user information and clear the session, then redirect to
     * the log in page.
     */
    public function logoutAction()
    {
		// Instantiate Steam's adapter directly
		$adapter = new Hybridauth\Provider\Steam($config);

		//Disconnect the adapter 
		$adapter->disconnect();

        $this->session->name = "";
        $this->session->admin = false;        
        $this->session->steamid = "";
        $this->session->steamid3 = "";
        $this->session->steamid64 = 0;
        $this->session->username = "";
    	$this->session->logged_in = false;
	    Zend_Auth::getInstance()->clearIdentity();
	    $this->_redirect('/user/login');
    }
}
