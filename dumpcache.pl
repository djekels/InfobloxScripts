#!/usr/bin/perl -w
#
# I wrote this to dump the DNS cache
#
use Infoblox;
use Getopt::Std;
use Net::Netrc;
use XML::Dumper;
use strict;

$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %options;
getopts("m:g: ", \%options);
my $bloxmaster = $options{m};
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

my $ip = $options{g};

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

my $result = $session->export_data(
	type=>"dnsCache",
	member=>$ip,
	path=>"$ip.tar.gz",
	);

if ($result) {print "Dumped $ip\n"} else {print "Could not dump\n"}

sub HELP_MESSAGE
        {
        print "\n$0 [OPTIONS]|--help|--version
        
        OPTIONS:
        --help (this message)
        -m Infoblox Grid master
	-g Desired Member\n";
        exit 0;
        }   
