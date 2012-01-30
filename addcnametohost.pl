#!/usr/bin/perl -w
#
# I wrote this to add an alias to a host record
#
use Infoblox;
use Getopt::Std;
use Net::Netrc;
use XML::Dumper;
use strict;

$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %options;
getopts("m:h:a: ", \%options);
my $bloxmaster = $options{m};
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

for my $host ($options{h})
	{
	my $hostrecord = $session->get(object=>'Infoblox::DNS::Host',
			name=>$host
			);
	unless ($hostrecord) {die ($session->status_detail())}

	local $, = "\n\t";
	print "Current aliases are:\n\t";
	print @{$hostrecord->aliases};
	print "\n\n";

	if ($options{a})
		{
		push (@{$hostrecord->aliases}, $options{a});
		my $result = $session->modify($hostrecord);

		if ($result) { print "Added alias " . $options{a} }
			else {warn $session->status_detail()}
		}
	}


sub HELP_MESSAGE
        {
        print "\n$0 [OPTIONS]|--help|--version
        
        OPTIONS:
        --help (this message)
        -m Infoblox Grid master
        -h Host Record
	-a Desired Alias\n";
        exit 0;
        }   
