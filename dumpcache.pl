#!/usr/bin/perl -w
#
# I wrote this to dump the DNS cache
#
use Infoblox;
use Net::Netrc;
use XML::Dumper;
use strict;

my $bloxmaster = 'ibl01nyc2us.us.wspgroup.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

my $ip = shift;

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

my $result = $session->export_data(
	type=>"dnsCache",
	member=>$ip,
	path=>"$ip.tar.gz",
	);

if ($result) {print "Dumped $ip\n"} else {print "Could not dump\n"}

