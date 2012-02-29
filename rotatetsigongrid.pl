#!/usr/bin/perl -w
#
#
use Infoblox;
use Getopt::Std;
use Net::Netrc;
use XML::Dumper;
use strict;

$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %options;
getopts("m:k: ", \%options);
my $bloxmaster = $options{m};
my $keyname = $options{k};
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

local $\ = "\n";
my $neednewtsig = 1;
my $newkey = $session->gen_tsig_key(keylen=>512, algorithm=>'HMAC-MD5');
print "New generated key:\n$newkey";

my $gridobject = $session->get(object=>"Infoblox::Grid::DNS",
	name=>'AvonDNSRye',
	);

my $currenttransferlist = $gridobject->allow_transfer(); #Return Array Reference

foreach my $transferentry (@$currenttransferlist)
	{
	next unless ($transferentry->isa('Infoblox::DNS::TSIGKey'));
	if ($keyname eq $transferentry->name)
		{
		$neednewtsig = 0;
		print "Need to update keyname $keyname";
		$transferentry->key($newkey);
		unless ($transferentry->algorithm() eq 'HMAC-MD5') {$transferentry->algorithm('HMAC-MD5')}
		my $result = $session->modify($gridobject);
		if ($result) {print "Successfully added $keyname"} else {print $session->status_detail()}
		}
	}

if ($neednewtsig)
	{
	my $tsigrecord = Infoblox::DNS::TSIGKey->new(name=>$keyname, key=>$newkey);
	print "Need to add new key $keyname";
	push (@$currenttransferlist, $tsigrecord);
	my $result = $session->modify($gridobject);
	if ($result) {print "Successfully added $keyname"} else {print $session->status_detail()}
	}

if (grep(/dns/, $session->restart_status())) # Restart stuff if needed
        {
        print "Have to restart DNS services.";
        my $result = $session->restart(delay_between_members=>60);
        if ($result) {print "Succesfully restarted members."} else { print "Problem restarting."}
        }

sub HELP_MESSAGE
        {
        print "\n$0 [OPTIONS]|--help|--version
        
        OPTIONS:
        --help (this message)
        -m Infoblox Grid master
	-k Keyname\n";
        exit 0;
        }   
