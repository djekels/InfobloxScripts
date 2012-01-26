#!/usr/bin/perl -w
#
# I wrote this to transfer the SOA for reverse zones from the internal namespace to DNS1
#
use Net::DNS;
use Net::Netrc;
use Infoblox;
use XML::Dumper;
use strict;

my $soa = '134.65.248.24';
my %zonehash;

my $res = Net::DNS::Resolver->new(nameservers => [ $soa ], recurse => 0);

foreach my $int (0 .. 255)
	{
	my $test = $res->query("$int.$subnet.172.in-addr.arpa", 'NS');
	next unless $test;
	my $arrayref = [];
	foreach my $rr ($test->answer)
		{
		push (@$arrayref, $rr->nsdname);
		}
	$zonehash{"172.$subnet.$int.0/24"} = $arrayref;
	}

my $bloxmaster = 'ryentp2.rye.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

foreach my $cidrzone (keys %zonehash)
	{
	#my @zonelist = $session->search("object" => "Infoblox::DNS::Zone", "name" => "$cidrzone") || warn $session->status_detail();
	my @zonelist = $session->search("object" => "Infoblox::DNS::Zone", "name" => "$cidrzone");
	next if ($zonelist[0]);

	foreach my $arrayref ( $zonehash{$cidrzone} )
		{
		my @nsarray = map {Infoblox::DNS::Nameserver->new(name=> $_, ipv4addr=>'255.255.255.255')} @$arrayref;
		my $newzone = Infoblox::DNS::Zone->new(name => $cidrzone, delegate_to => \@nsarray);
		print "Creating new zone, $cidrzone\n";
		$session->add($newzone) || warn $session->status_detail();
		}
	}

