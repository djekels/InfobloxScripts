#!/usr/bin/perl -w
#
use Infoblox;
use Net::Netrc;
#use XML::Dumper;
use strict;

$\ = "\n";
my $bloxmaster = 'ibl01nyc2us.us.wspgroup.com';
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
	next unless ($_->disable_forwarding());

	if ($_->disable_forwarding() eq "false") # Turn on if it's off
		{
		print $_->name . " status is " . $_->disable_forwarding();
		$_->disable_forwarding("true");
		my $result = $session->modify($_);
		if ($result) {print "Succesfully modified " . $_->name} else { print "Problem correcting " . $_->name }
		}
	}

print '';

if (grep(/dns/, $session->restart_status(delay_between_members=>60))) # Restart stuff if needed
	{
	print "Have to restart DNS services.";
	my $result = $session->restart();
	if ($result) {print "Succesfully restarted members."} else { print "Problem restarting."}
	}
