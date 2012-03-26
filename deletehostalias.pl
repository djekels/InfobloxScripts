#!/usr/bin/perl -w
use Infoblox;
use List::MoreUtils qw/indexes/;
use Net::Netrc;
use Getopt::Std;
use XML::Dumper;
use strict;

local $\ = "\n";
my $bloxmaster = 'ryeinfoblox.global.avon.com';
my %options;
getopts("a: ", \%options);
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session)
	{	
        die("Construct session failed: ",
           Infoblox::status_code() . ":" . Infoblox::status_detail());
	}

my $alias = $options{a} or die;

my $targethost = $session->get ( object=> 'Infoblox::DNS::Host',
                        alias=>$alias,
                        );

if ($targethost)
	{
	local $, = "\n";
	print "Target host is " . $targethost->name;

	my $aliasref = $targethost->aliases();
	if (scalar @$aliasref > 0)
		{
		print "Here is s the current list of aliases:\n";
		print @$aliasref;
		}

	my @deleteindexes = indexes { $_ eq $alias } @$aliasref; # There will be only one.
	splice (@$aliasref, $deleteindexes[0], 1);

	my $result = $session->modify($targethost);

	if ($result) {print "Successfully deleted alias."} else {print $session->status_detail()}
	}
else
	{
	print "No applicable host.";
	}

