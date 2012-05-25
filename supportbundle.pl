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
getopts("m: ", \%options);
my $bloxmaster = 'ryeinfoblox.global.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

my $ip = $options{m};

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

my $result = $session->export_data(
	type=>"support_bundle",
	member=>$ip,
	path=>"${ip}-Bundle.tar.gz",
	core_files=>0,
	);

if ($result) {print "Downloaded Bundle for $ip\n"} else {print $session->status_detail()}

sub HELP_MESSAGE
        {
        print "\n$0 [OPTIONS]|--help|--version
        
        OPTIONS:
        --help (this message)
	-m Desired Member\n";
        exit 0;
        }   
