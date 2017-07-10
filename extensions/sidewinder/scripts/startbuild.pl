#!/usr/bin/perl

use File::Basename;

our (@LIBRARIES);
my ($myself, $path) = fileparse($0);
chdir($path);

require 'helpers.pm';

#Get to top of source tree
chdir('..');

#	   Folder			.vcproj				Engine			Binary				Suffix type
Build('', 'sdk', 'OrangeBox', 	'sidewinder.ext', 	'');

#Structure our output folder
mkdir('OUTPUT');
mkdir(Build::PathFormat('OUTPUT/sourcemod'));
mkdir(Build::PathFormat('OUTPUT/sourcemod/extensions'));
mkdir(Build::PathFormat('OUTPUT/sourcemod/gamedata'));

my ($i);
for ($i = 0; $i <= $#LIBRARIES; $i++)
{
	my $library = $LIBRARIES[$i];
	Copy($library, Build::PathFormat('OUTPUT/sourcemod/extensions'));
}
Copy(Build::PathFormat('CEntity/centity.offsets.txt'),
	 Build::PathFormat('OUTPUT/sourcemod/gamedata'));
Copy(Build::PathFormat('sidewinder.autoload'),
	 Build::PathFormat('OUTPUT/sourcemod/extensions'));


sub Copy
{
	my ($a, $b) = (@_);

	die "Could not copy $a to $b!\n" if (!Build::Copy($a, $b));
}

sub Build
{
	my ($srcdir, $vcproj, $objdir, $binary, $suffix) = (@_);

	if ($^O eq "linux")
	{
		if ($suffix eq 'full')
		{
			$binary .= '_i486.so';
		}
		else
		{
			$binary .= '.so';
		}
		BuildLinux($srcdir, $objdir, $binary);
	}
	else
	{
		my ($pdb);
		$pdb = "$binary.pdb";
		$binary .= '.dll';
		BuildWindows($srcdir, $vcproj, $objdir, $binary, $pdb);
	}
}

sub BuildWindows
{
	my ($srcdir, $vcproj, $build, $binary, $pdb) = (@_);
	my ($dir, $file, $param, $vcbuilder, $cmd, $curdir);

	$dir = getcwd();
	chdir("msvc9");
	$curdir = getcwd();
	print "$curdir\n";
	
	ChangeVersion($vcproj);

	$param = "Release";
	if ($build eq "OrangeBox")
	{
		$param = "Release - Orange Box";
	}
	elsif ($build eq "Left4Dead")
	{
		$param = "Release - Left 4 Dead";
	}

	print "Clean building $srcdir...\n";
	$vcbuilder = $ENV{'VC9BUILDER'};
	$cmd = "\"$vcbuilder\" /rebuild \"$vcproj.vcproj\" \"$param\"";
	print "$cmd\n";
	system($cmd);
	CheckFailure();

	$file = "$param\\$binary";

	die "Output library not found: $file\n" if (!-f $file);

	chdir($dir);

	push(@LIBRARIES, "msvc9\\$file");
	push(@LIBRARIES, "msvc9\\$param\\$pdb");
}

sub ChangeVersion
{
	my ($vcproj) = (@_);
	
	my ($version);
	$version = Build::ProductVersion(Build::PathFormat('../product.version'));
	$version .= '-hg' . Build::HgRevNum('..');
	
	$filename = "$vcproj.vcproj";
	open ( INFILE, $filename) or die "Cannot open file: $!";

	while ( $line = <INFILE> ) 
	{
	    $line =~ s/531.8008/$version/i;
	    push(@outLines, $line);
	}
	
	close INFILE;
	
	open ( OUTFILE, ">$filename" );
	print ( OUTFILE @outLines );
	close ( OUTFILE );	
}

sub BuildLinux
{
	my ($srcdir, $build, $binary) = (@_);
	my ($dir, $file, $param);

	$param = "";
	$file = "Release";
	if ($build eq "OrangeBox")
	{
		$param = "ENGINE=orangebox";
		$file .= '.orangebox';
	}
	elsif ($build eq "Left4Dead")
	{
		$param = "ENGINE=left4dead";
		$file .= '.left4dead';
	}
	$file .= '/' . $binary;

	print "Building $srcdir for $binary...\n";
	print "$param\n";
	system("make $param");
	CheckFailure();

	die "Output library not found: $file\n" if (!-f $file);

	
	push(@LIBRARIES, $file);
}

sub CheckFailure
{
	die "Build failed: $!\n" if $? == -1;
	die "Build died :(\n" if $^O eq "linux" and $? & 127;
	die "Build failed with exit code: " . ($? >> 8) . "\n" if ($? >> 8 != 0);
}

