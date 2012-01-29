#!/usr/bin/perl -w

use Infoblox;
use Net::Netrc;
#use XML::Dumper;
use strict;

local $\ = "\n";
my $identical = 1;
my $bloxmaster = 'ryentp2.rye.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

my $bloxmaster2 = 'dns1.avon.com';
my $creds2 = Net::Netrc->lookup($bloxmaster2);
my $session2 = Infoblox::Session->new("master"=> $bloxmaster2, "username"=>$creds2->login, "password"=>$creds2->password);

unless (($session) && ($session2))
	{	
        die("Construct session failed: ",
           Infoblox::status_code() . ":" . Infoblox::status_detail());
	}

# Get all NSGroups on source grid

my @allzones = $session->search(object => "Infoblox::DNS::Zone",
			name => "^[0-9].*4\$"); # Get all zones that are ARPAs

foreach my $zone (@allzones)
	{
	next if ($zone->name eq "127.0.0.0/24");
	my $nsgroupname = $zone->ns_group();
	my $nsgroup = $session->get(object=> 'Infoblox::Grid::DNS::Nsgroup',
			name=>$nsgroupname
			);
	
	my $delegatedzone = $session2->get(object=>"Infoblox::DNS::Zone",
		name=>$zone->name,
		);

	# Define new delegation array to be put in parent domain.
	my $nsarray = [];
	push (@$nsarray,
		Infoblox::DNS::Nameserver->new(name=>$nsgroup->primary()->name,
			ipv4addr=>'255.255.255.255'));

	foreach (@{$nsgroup->secondaries()})
		{
		push (@$nsarray,
			Infoblox::DNS::Nameserver->new(name=>$_->name,
				ipv4addr=>'255.255.255.255'));
		}
	### 

	if ($delegatedzone)
		{
		next unless ($delegatedzone->delegate_to());
		print "Checking " . $delegatedzone->name();

		# Compare the two delegations. If they are the same, don't bother continuing
		$identical = 1;
		my @currentdelegation = map {$_->name} @{$delegatedzone->delegate_to()};
		my @newdelegation = map {$_->name} @$nsarray;
		$identical = 0 if (scalar @currentdelegation != scalar @newdelegation);
		BLORF: while  ($identical) 
			{
			foreach my $doop (@newdelegation)
				{
				$identical = grep(/$doop/, @currentdelegation);
				goto BLORF unless ($identical);
				}
			last if ($identical);
			}
		next if ($identical);
		### 

		print "Changing " . $delegatedzone->name();
		$delegatedzone->delegate_to($nsarray);
		my $result = $session2->modify($delegatedzone);
		if ($result) {print "Sucessfully changed " . $delegatedzone->name}
			else {print "Problem Changing ". $delegatedzone->name}
		}
	else
		{
		print "Need to create new zone " . $zone->name;
		my $newzone = Infoblox::DNS::Zone->new(name => $zone->name,
			delegate_to=>$nsarray,
			);
		my $result = $session2->add($newzone);
		if ($result) {print "Sucessfully added " . $newzone->name}
			else {print "Problem adding ". $newzone->name}
		}
	}
