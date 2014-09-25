#!/usr/bin/perl -w
use Infoblox;
use DateTime;
use Net::Netrc;
use Net::IP;
use Getopt::Std;
use XML::Dumper;
use strict;

my @imported = qw/
0.20.172.in-addr.arpa
1.20.172.in-addr.arpa
100.21.172.in-addr.arpa
101.21.172.in-addr.arpa
104.21.172.in-addr.arpa
105.21.172.in-addr.arpa
110.16.172.in-addr.arpa
126.65.134.in-addr.arpa
127.65.134.in-addr.arpa
13.20.172.in-addr.arpa
14.20.172.in-addr.arpa
144.20.172.in-addr.arpa
146.20.172.in-addr.arpa
15.20.172.in-addr.arpa
152.20.172.in-addr.arpa
154.20.172.in-addr.arpa
156.20.172.in-addr.arpa
160.16.172.in-addr.arpa
176.20.172.in-addr.arpa
180.65.134.in-addr.arpa
181.65.134.in-addr.arpa
184.65.134.in-addr.arpa
189.65.134.in-addr.arpa
191.65.134.in-addr.arpa
192.65.134.in-addr.arpa
2.20.172.in-addr.arpa
204.20.172.in-addr.arpa
208.65.134.in-addr.arpa
224.21.172.in-addr.arpa
228.20.172.in-addr.arpa
231.20.172.in-addr.arpa
232.20.172.in-addr.arpa
24.20.172.in-addr.arpa
240.20.172.in-addr.arpa
25.20.172.in-addr.arpa
26.20.172.in-addr.arpa
27.20.172.in-addr.arpa
29.20.172.in-addr.arpa
3.20.172.in-addr.arpa
30.20.172.in-addr.arpa
4.20.172.in-addr.arpa
5.20.172.in-addr.arpa
56.20.172.in-addr.arpa
57.20.172.in-addr.arpa
58.20.172.in-addr.arpa
59.20.172.in-addr.arpa
88.21.172.in-addr.arpa
89.21.172.in-addr.arpa
96.21.172.in-addr.arpa
/;
my $reftoany = ['any']; # Just a ref to any so that I declare it once.
my $bloxmaster = 'ibl01nyc2us.us.wspgroup.com';
my %options;
getopts("i:n: ", \%options);
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

foreach my $zone (@imported)
{
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
			warn "Authoritative zone $zone exists!";
			next;
			}
		}

	my $importfrom = $options{i} or die;
	my $newzone = Infoblox::DNS::Zone->new(name => $zone,
		ns_group => $nsgroup,
		disable_forwarding => "true",
		allow_update => $reftoany );
	if ($importfrom){$newzone->import_from($importfrom)}

	$session->add($newzone) || die $session->status_detail();

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
