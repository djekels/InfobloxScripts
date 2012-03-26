#!/usr/bin/perl -w

use Infoblox;
use Getopt::Std;
use DateTime;
use Net::Netrc;
use XML::Dumper;
use strict;

local $\ = "\n";

my %options;
getopts("n: ", \%options);
my $nsgroup = $options{n} or die;

my $bloxmaster = 'ryeinfoblox.global.avon.com';
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

my @allzones = $session->get(object => "Infoblox::DNS::Zone",
			extensible_attributes=>{'HITME'=>1},
			);

foreach my $zone (@allzones)
	{
	my $currentnsgroup = $zone->ns_group;
	if ($currentnsgroup eq $nsgroup)
		{
		print 'NSGroup already set to desired value!';
		}
	else
		{
		print 'Updating ' . $zone->name;
		$zone->ns_group($nsgroup);
		my $hashref = $zone->extensible_attributes();
		delete $$hashref{'HITME'};

		my $result = $session->modify($zone);
		if ($result){print "Succesfully modified."}else{print 'Could not modify'}
		}
	}

#Restart Section
if (grep(/dns/, $session->restart_status())) # Restart stuff if needed
        {
        local $\ = "\n";
        print "Have to restart DNS services.";
        my $future = DateTime->now(time_zone=>'US/Eastern')->add(minutes=>5);
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

