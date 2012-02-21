#!/usr/bin/perl -w
#
#
#
use Infoblox;
use Getopt::Std;
use Net::Netrc;
use XML::Dumper;
use strict;

$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %options;
getopts("m:r: ", \%options);
my $bloxmaster = $options{m};
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

my $zone = $options{r};

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

my @hostrecords = $session->search(
	object=>"Infoblox::DNS::Host",
	#zone=>$options{z},
	ipv4addr=>$options{r},
	);

foreach my $hostrecord (@hostrecords)
	{
	local $\ = "\n";
	print "Testing " . $hostrecord->name;
	my $arrayipv4 = $hostrecord->ipv4addrs();
	foreach my $ip (@$arrayipv4)
		{
		my @arrayptr = $session->search(object=>"Infoblox::DNS::Record::PTR",
			ipv4addr=>$ip . '$',
			);
		foreach my $ptr (@arrayptr)
			{
			my $result = $session->remove($ptr);
			if ($result) {print "Deleted " . $ptr->ptrdname} else {print "Could not delete " . $ptr->ptrdname}
			}
		}
	}


#if ($result) {print "Dumped $ip\n"} else {print "Could not dump\n"}

sub HELP_MESSAGE
        {
        print "\n$0 [OPTIONS]|--help|--version
        
        OPTIONS:
        --help (this message)
        -m Infoblox Grid master
	-r Desired range\n";
        exit 0;
        }   

