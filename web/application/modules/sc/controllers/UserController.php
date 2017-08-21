<?php

/**
 * SourceCraft user controller - Handling user related actions - currently log in and
 * log out.
 * 
 */

require_once 'Zend/Controller/Action.php';
require_once 'Zend/Auth/Adapter/DbTable.php';
require_once 'Zend/Registry.php';
require_once 'Zend/Session.php';
require_once 'xPaw/SteamID.php';
require_once 'Members.php';
require_once 'Player.php';

//require_once "Zend/Auth/Adapter/OpenId.php";
//require_once 'steamauth/openid.php';
require_once 'hybridauth/Hybrid/Auth.php';

class Sc_UserController extends Zend_Controller_Action
{
    /**
     * User session
     *
     * @var Zend_Session_Namespace
     */
    protected $session = null;

    // Build configuration array
    protected $config = [
        // "base_url" the url that point to HybridAuth Endpoint (where index.php and config.php are found)
        "base_url" => "/sc/user/auth",        //Location where to redirect users once they authenticate with Steam
        'callback' => '/sc/player/show/user/',

        "providers" => [
            "Steam" => [
               "enabled" => true,
                // Steam api credentials
                'keys' => [
                    'key' => '', // Required: your Steam api key
                ]
            ],
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
     *          then logs in through steam using openid
     */
    public function loginAction()
    {
        try
        {
            // Instantiate Steam's adapter directly
            $adapter = new Hybrid_Auth($this->config);

            // Attempt to authenticate the user with Steam
            $adapter->authenticate("Steam");

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
        $this->session->steamid64 = false;
        $this->session->username = "";
        $this->session->logged_in = false;
        Zend_Auth::getInstance()->clearIdentity();
        $this->_redirect('/sc/user/login');
    }

    /**
     * Profile - show the user profile screen
     * 
     * @todo Implement real profile screen
     */
    public function profileAction()
    {
        $user = $this->session->username;
        if ($user)
        {
            $this->_redirect('/sc/player/show/user/' . $user);
            //$this->_forward('show', 'player', 'sc', array('user' => $user));
        }
        else
        {
            $this->_forward('index','index', 'sc');
        }
    }
}
