#!/usr/bin/perl -w

use Infoblox;
use Net::Netrc;
use XML::Dumper;
use strict;

my $bloxmaster = 'ryentp2.rye.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

# Find all the aliases in all the Hosts.

my @allhostaliases;

my @allhosts = $session->search( "object" => "Infoblox::DNS::Host", "name" => ".*" );

foreach my $hostrecord (@allhosts)
	{
	next if ($hostrecord->configure_for_dns() eq "false");
	push (@allhostaliases, @{$hostrecord->aliases});
	}

# Now, collect all CNAME records

print "Phase I!\n\n\n";

my @cnamerecords = $session->search("object" => "Infoblox::DNS::Record::CNAME", "name" => '.*' );

foreach my $cnamerecord (@cnamerecords)
	{
	my $target = $cnamerecord->canonical;
	my $grepresult = grep(/^$target$/, @allhostaliases);
	if ($grepresult > 0)
		{
		print $cnamerecord->name . " points to $target!!!\n";
		}
	}

print "\n\n\nPhase II!\n\n\n";


my @cnamearray;
foreach (@cnamerecords)
	{
	push (@cnamearray, $_->name);
	}

foreach my $cnamerecord (@cnamerecords)
	{
	my $target = $cnamerecord->canonical;
	my $grepresult = grep(/^$target$/, @cnamearray);
	if ($grepresult > 0)
		{
		print $cnamerecord->name . " points to $target!!!\n";
		}
	}
print "\nDONE!\n";
