#!/usr/bin/perl -w

use Infoblox;
use Net::Netrc;
use XML::Dumper;
use strict;

my $bloxmaster = 'ryeinfoblox.global.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

# Find all the aliases in all the Hosts.

my @cnamerecords = $session->search("object" => "Infoblox::DNS::Record::CNAME", "name" => '.*' );

foreach my $cnamerecord (@cnamerecords)
	{
	my $target = lc($cnamerecord->canonical);
	my $hostrecord = $session->get(object=>"Infoblox::DNS::Host",
		name=>$target,
		);
	if ($hostrecord)
		{
		local $\ = "\n";
		local $, = "\n\t";
		
		my $cname =  $cnamerecord->name;
		print "Found that $cname  points to " . $hostrecord->name;
		my $hostaliases = $hostrecord->aliases();

		if (scalar @$hostaliases > 0)
			{
			print "Current aliases are:\n\t";
			print @$hostaliases;
			}
		print "Attempting to add $cname.";
		$session->remove($cnamerecord);
		push (@$hostaliases, $cname);
		my $result = $session->modify($hostrecord);
		if ($result) { print "Success!"} else {print $session->status_detail()}
		}
	}

