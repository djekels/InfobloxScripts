#!/usr/bin/perl -w
#
# I wrote this to add an alias to a host record
#
use Infoblox;
use Getopt::Std;
use Net::Netrc;
#use XML::Dumper;
use strict;

$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %options;
getopts("h:a: ", \%options);
my $bloxmaster = 'ryeinfoblox.global.avon.com';
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
	
	my $aliasref = $hostrecord->aliases;
	print "Current aliases are:\n\t";
	print @{$aliasref};
	print "\n\n";

	if ($options{a})
		{
		push (@{$aliasref}, $options{a});
		my $result = $session->modify($hostrecord);

		if ($result) { print "Added alias " . $options{a} . "\n" }
			else {warn $session->status_detail()}
		}
	}


sub HELP_MESSAGE
        {
        print "\n$0 [OPTIONS]|--help|--version
        
        OPTIONS:
        --help (this message)
        -h Host Record
	-a Desired Alias\n";
        exit 0;
        }   
