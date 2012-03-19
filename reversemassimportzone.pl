#!/usr/bin/perl -w
use Infoblox;
use DateTime;
use Net::Netrc;
use Net::IP;
use Getopt::Std;
use XML::Dumper;
use strict;

my @imported = qw/
112.26.172.in-addr.arpa
117.26.172.in-addr.arpa
118.26.172.in-addr.arpa
119.26.172.in-addr.arpa
12.65.134.in-addr.arpa
128.27.172.in-addr.arpa
129.28.172.in-addr.arpa
130.27.172.in-addr.arpa
131.27.172.in-addr.arpa
132.27.172.in-addr.arpa
133.28.172.in-addr.arpa
135.27.172.in-addr.arpa
136.27.172.in-addr.arpa
137.27.172.in-addr.arpa
140.27.172.in-addr.arpa
142.27.172.in-addr.arpa
160.27.172.in-addr.arpa
161.27.172.in-addr.arpa
162.27.172.in-addr.arpa
163.27.172.in-addr.arpa
164.27.172.in-addr.arpa
165.27.172.in-addr.arpa
166.27.172.in-addr.arpa
167.27.172.in-addr.arpa
168.26.172.in-addr.arpa
168.27.172.in-addr.arpa
170.27.172.in-addr.arpa
171.27.172.in-addr.arpa
172.27.172.in-addr.arpa
174.27.172.in-addr.arpa
175.27.172.in-addr.arpa
178.27.172.in-addr.arpa
179.27.172.in-addr.arpa
180.27.172.in-addr.arpa
182.27.172.in-addr.arpa
183.27.172.in-addr.arpa
186.27.172.in-addr.arpa
191.27.172.in-addr.arpa
210.27.172.in-addr.arpa
211.27.172.in-addr.arpa
212.27.172.in-addr.arpa
213.27.172.in-addr.arpa
234.65.134.in-addr.arpa
235.65.134.in-addr.arpa
236.65.134.in-addr.arpa
237.65.134.in-addr.arpa
238.65.134.in-addr.arpa
239.65.134.in-addr.arpa
240.65.134.in-addr.arpa
242.65.134.in-addr.arpa
243.65.134.in-addr.arpa
244.65.134.in-addr.arpa
248.65.134.in-addr.arpa
249.65.134.in-addr.arpa
250.65.134.in-addr.arpa
251.65.134.in-addr.arpa
252.65.134.in-addr.arpa
253.65.134.in-addr.arpa
56.27.172.in-addr.arpa
58.27.172.in-addr.arpa
9.65.134.in-addr.arpa
/;
my $reftoany = ['any']; # Just a ref to any so that I declare it once.
my $bloxmaster = 'dns1.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session)
	{	
        die("Construct session failed: ",
           Infoblox::status_code() . ":" . Infoblox::status_detail());
	}

my @nsarray = map {Infoblox::DNS::Nameserver->new(name=>$_, ipv4addr=>'255.255.255.255')} ('ryemsnadc2.na.avonet.net', 'ryemsnadc1.na.avonet.net');

foreach my $zone (@imported)
{
	my $oldzone = $session->get(object=>'Infoblox::DNS::Zone',
		name=>$zone,
		);

	if ($oldzone) #Check for delegated zone and delete if found.
		{
		local $\ = "\n";
		print "Need to delete delegated zone " . $oldzone->name;
		my $result = $session->remove($oldzone);
		if ($result){print "Removed!"}else{die $session->status_detail()}
		}

	my $newzone = Infoblox::DNS::Zone->new(name => $zone,
		delegate_to=>\@nsarray);

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
