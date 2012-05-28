#!/usr/bin/perl -w
#
# I wrote this to dump the DNS cache
#
use Infoblox;
use Net::Netrc;
#use XML::Dumper;
use strict;

my $bloxmaster = 'ryeinfoblox.global.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

my $result = $session->export_data(
	type=>"backup",
	path=>"database.tar.gz",
	);

if ($result) {print "Database Backed Up"} else {print $session->status_detail()}
