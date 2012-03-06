#!/usr/bin/perl -w

use Infoblox;
use Net::Netrc;
use XML::Dumper;
use strict;

local $\ = "\n";

my $bloxmaster = 'dns1.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session)
	{	
        die("Construct session failed: ",
           Infoblox::status_code() . ":" . Infoblox::status_detail());
	}

my @allzones = $session->search(object => "Infoblox::DNS::Zone",
			name => "^[0-9].*4\$"); # Get all zones that are ARPAs

foreach my $zone (@allzones)
	{
	next if ($zone->name eq "127.0.0.0/24");
	my $delegated = ($zone->delegate_to()) ? 1:0;
	my @oop = $zone->name =~ /^(\d+)\.(\d+)\.(\d+)\./;
	print "$oop[2].$oop[1].$oop[0].in-addr.arpa" unless ($delegated);
	}
