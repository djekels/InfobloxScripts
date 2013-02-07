#!/usr/bin/perl -w
use Infoblox;
use Net::Netrc;
#use XML::Dumper;
use strict;

my $cname = shift || die 'No CNAME specified.';
$cname =~ s/\.$//; # Make tolerant of trailing dot
my $bloxmaster = 'ryeinfoblox.global.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session)
	{	
        die("Construct session failed: ",
           Infoblox::status_code() . ":" . Infoblox::status_detail());
	}

my $targetcname = $session->get ( object=> 'Infoblox::DNS::Record::CNAME',
                        name=>$cname,
                        );

local $\ = "\n";
if ($targetcname)
	{
	local $, = "\n";
	print "Target host is " . $targetcname->name;

	my $result = $session->remove($targetcname);

	if ($result) {print "Successfully deleted alias."} else {print $session->status_detail()}
	}
else
	{
	print "No applicable cname.";
	}
