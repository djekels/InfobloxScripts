#!/usr/bin/perl -w
#
use Infoblox;
use Net::Netrc;
use Getopt::Std;
use XML::Dumper;
use strict;


my $bloxmaster = 'ryeinfoblox.global.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my %options;
getopts("a: ", \%options);
my $address = $options{a} or die;
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

my $ipamobject = $session->get(object=>'Infoblox::IPAM::Address',
	address=>$address,
	);

if ($ipamobject)
	{
	local $, = "\n\t";
	print "$address has the following names:\n\t";
	print @{$ipamobject->names};
	print "\n";
	}
	else {print "No address $address\n"}
