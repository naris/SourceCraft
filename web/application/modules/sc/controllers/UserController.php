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

//require_once "Zend/Auth/Adapter/OpenId.php";
require_once 'steamauth/openid.php';
require_once 'xPaw/SteamID.php';

require_once 'Members.php';
require_once 'Player.php';

class Sc_UserController extends Zend_Controller_Action
{
    /**
     * User session
     *
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
     *      then logs in through the Forums
     */
    public function loginAction()
    {
        try
        {
            require_once 'steamauth/SteamConfig.php';
            $openid = new LightOpenID($steamauth['domainname']);
            
            /*
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
            */
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
                            $this->session->username = $player->username;
                            $this->session->name = $player->name;
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
        Zend_Auth::getInstance()->clearIdentity();
        $this->session->name = "";
        $this->session->admin = false;        
        $this->session->steamid = "";
        $this->session->steamid3 = "";
        $this->session->steamid64 = false;
        $this->session->username = "";
        $this->session->logged_in = false;
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
