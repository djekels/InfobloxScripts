#!/usr/bin/perl -w
use Infoblox;
use List::MoreUtils qw/indexes/;
use Net::Netrc;
use Getopt::Std;
#use XML::Dumper;
use strict;

local $\ = "\n";
my $bloxmaster = 'dns1.avon.com';
my %options;
getopts("a:t: ", \%options);
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session)
	{	
        die("Construct session failed: ",
           Infoblox::status_code() . ":" . Infoblox::status_detail());
	}

my $alias = $options{a} or die;

my $sourcehost = $session->get ( object=> 'Infoblox::DNS::Host',
                        alias=>$alias,
                        );

my $targethost = $session->get ( object=> 'Infoblox::DNS::Host',
                        name=>$options{t},
                        ) or die $session->status_detail;

if ($targethost->name ne $sourcehost->name)
	{
	my $result = 0;
	local $, = "\n";
	print "Source host is " . $sourcehost->name;

	my $sourcealiasref = $sourcehost->aliases();
	if (scalar @$sourcealiasref > 0)
		{
		print "Here is s the current list of aliases:\n";
		print @$sourcealiasref;
		}

	print "Target host is " . $targethost->name;

	my $targetaliasref = $targethost->aliases();
	if (scalar @$targetaliasref > 0)
		{
		print "Here is s the current list of aliases:\n";
		print @$targetaliasref;
		}

	my @deleteindexes = indexes { $_ eq $alias } @$sourcealiasref; # There will be only one.
	push (@$targetaliasref, splice (@$sourcealiasref, $deleteindexes[0], 1));

	$result = $session->modify($sourcehost);

	if ($result) {print "Successfully deleted alias."} else {print $session->status_detail()}

	$result = $session->modify($targethost);

	if ($result) {print "Successfully recreated alias."} else {print $session->status_detail()}
	}
else
	{
	print "\nSource and Destination the same. Not moving anything.\n";
	}

