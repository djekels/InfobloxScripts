#!/usr/bin/perl -w
#
use Infoblox;
use Net::Netrc;
#use XML::Dumper;
use strict;

$\ = "\n";
my $bloxmaster = 'ryentp2.rye.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

my @zones = $session->search(object=>'Infoblox::DNS::Zone',
		name => '.*',
		);

foreach (@zones)
	{
	next if ($_->name eq '127.0.0.0/24');   # Gotta skip loopback

	if (($_->ns_group) && ($_->ns_group ne "corbyPrimary-NS"))
		{
		print $_->name . " needs changing";
		$_->ns_group("corbyPrimary-NS");
		my $result = $session->modify($_);
		if ($result) { print $_->name . " changed!"} else { print $_->name . " could not be changed!"}
		}
	}


print '';

if (grep(/dns/, $session->restart_status())) # Restart stuff if needed
	{
	print "Have to restart DNS services.";
	my $result = $session->restart();
	if ($result) {print "Succesfully restarted members."} else { print "Problem restarting."}
	}
