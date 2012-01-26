#!/usr/bin/perl -w
#
# I wrote this to create a bunch of reverses on DNS1
#
use Infoblox;
use Net::Netrc;
#use XML::Dumper;
use strict;

my $bloxmaster = 'dns1.avon.com';
my %zonehash;
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

foreach my $int (16 .. 31)
	{
	my $cidrzone = "172.$int.0.0/16";
	my $newzone = Infoblox::DNS::Zone->new(name => $cidrzone,
		ns_group => "Recursives",
		disable_forwarding => "true",
		allow_update => ["any"] );

	$session->add($newzone) || warn $session->status_detail();
	}

