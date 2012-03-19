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
getopts("m:d: ", \%options);
my $bloxmaster = 'dns1.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

my $ip = $options{m};

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

my $domain = ($options{d}) ? $options{d} : '';

my $result = $session->clear_dns_cache(
	member=>$ip,
	domain=>$domain,
	);

unless ($result)  {print "Could not clear cache.\n"}

sub HELP_MESSAGE
        {
        print "\n$0 [OPTIONS]|--help|--version
        
        OPTIONS:
        --help (this message)
        -m Infoblox Grid master
	-g Desired Member\n";
        exit 0;
        }   
