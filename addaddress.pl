#!/usr/bin/perl -w

use Infoblox;
use Net::Netrc;
use Getopt::Std;
use XML::Dumper;
use strict;

my $bloxmaster = 'ibl01nyc2us.us.wspgroup.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

my %options;
getopts("a:f: ", \%options);

my $address = $options{a};
my $fqdn = lc($options{f});

my $ipamobject = $session->get(object=>'Infoblox::IPAM::Address',
	address=>$address,
	status=>"used",
	);

if ($ipamobject)
	{
	local $, = "\n\t";
	print "$address has the following names:\n\t";
	print @{$ipamobject->names} unless ($ipamobject->status eq "Unused");
	print "\n";
	my $result = $session->remove($ipamobject);
	if ($result) {print "Successfully deleted address $address\n"} else {print $session->status_detail()}
	}
	else {print "No address $address\n"}


my $arecord = Infoblox::DNS::Record::A->new (
	ipv4addr => $address,
	name => $fqdn
	);

my $ptrrecord = Infoblox::DNS::Record::PTR->new (
	ipv4addr => $address,
	ptrdname => $fqdn
	);


$session->add($arecord) || die $session->status_detail();
$session->add($ptrrecord) || die $session->status_detail();
