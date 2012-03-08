#!/usr/bin/perl -w
use Infoblox;
use DateTime;
use Net::Netrc;
use Net::IP;
use Getopt::Std;
use XML::Dumper;
use strict;

my $bloxmaster = 'dns1.avon.com';
my %options;
getopts("z:i:n: ", \%options);
my $nsgroup = $options{n} or die;
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session)
	{	
        die("Construct session failed: ",
           Infoblox::status_code() . ":" . Infoblox::status_detail());
	}

my $possiblensgroup = $session->get ( object=> 'Infoblox::Grid::DNS::Nsgroup',
                        name=>$nsgroup,
                        );

die "New NS Group not found!" unless ($possiblensgroup);

my $ipobj = new Net::IP($options{z});
die unless ($ipobj->prefixlen() eq 24);
my $zone = $ipobj->reverse_ip();

chop $zone; #Needed because it ends in period.

my $oldzone = $session->get(object=>'Infoblox::DNS::Zone',
	name=>$zone,
	);

if ($oldzone) #Check for delegated zone and delete if found.
	{
	local $\ = "\n";
	my $delegation = $oldzone->delegate_to();
	if ($delegation)
		{
		print "Need to delete delegated zone " . $oldzone->name;
		my $result = $session->remove($oldzone);
		if ($result){print "Removed!"}else{die $session->status_detail()}
		}
	else
		{
		die "Authoritative zone exists!";
		}
	}

my $importfrom = $options{i};
my $newzone = Infoblox::DNS::Zone->new(name => $zone,
	ns_group => $nsgroup,
	disable_forwarding => "true",
	allow_update => ["any"] );
if ($importfrom){$newzone->import_from($importfrom)}

$session->add($newzone) || warn $session->status_detail();

#Restart Section
if (grep(/dns/, $session->restart_status())) # Restart stuff if needed
        {
	local $\ = "\n";
        print "Have to restart DNS services.";
	my $future = DateTime->now(time_zone=>'EST')->add(minutes=>5);
	my $futurerestart = $session->get(object=>'Infoblox::Grid::ScheduledTask',
		scheduled_time=>"< $future",
		action=>'Restart Services',
		);
	if ($futurerestart){print "Restart already Scheduled."}
	else
		{
        	my $result = $session->restart(delay_between_members=>60,
			scheduled_at=>$future,
			);
        	if ($result) {print "Succesfully restarted members."} else { print "Problem restarting."}
		}
        }
