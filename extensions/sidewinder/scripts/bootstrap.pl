#!/usr/bin/perl

use strict;
use Cwd;
use File::Basename;

my ($myself, $path) = fileparse($0);
chdir($path);

require 'helpers.pm';

#Go to main source dir
chdir(Build::PathFormat('..'));

#check out the latest CEntity codebase
my($result);
$result = `hg clone http://users.alliedmods.net/~pred/code/index.cgi/centity CEntity`;
print $result;

#update the SourceMod codebase
my($curdir, $hgdir);
$curdir = getcwd();

if ($^O eq "linux")
{
	chdir("/home/builds/common/sourcemod-central");
}
else
{
	chdir("C:/Scripts/common/sourcemod-central");
}

$hgdir = getcwd();
print "Updating Sourcemod HG repo from $hgdir\n";
$result = `hg pull -u`;
print $result;

chdir($curdir);
