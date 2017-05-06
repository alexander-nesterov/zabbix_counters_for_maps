#!/usr/bin/perl

#documentation

#example:
#perl get_number_of_item.pl --h 'Zabbix server' --k item
#perl get_number_of_item.pl --h 'Zabbix server' --k trigger

use strict;
use warnings;
use JSON::RPC::Client;
use Getopt::Long;
use Data::Dumper;

#================================================================
#Constants
#================================================================
#ZABBIX
use constant ZABBIX_USER	=> 'Admin';
use constant ZABBIX_PASSWORD	=> '78%Ytn#4Wq32!Hynm90';
use constant ZABBIX_SERVER	=> 'localhost';

#DEBUG
use constant DEBUG		=> 1; #0 - False, 1 - True

#================================================================
##Global variables
#================================================================
my $ZABBIX_AUTH_ID;
my $HOST_NAME;
my $KEY;


main();

#================================================================
sub parse_argv
{
    GetOptions('h=s' => \$HOST_NAME, 'k=s' => \$KEY);
}

#================================================================
sub zabbix_auth
{
    my %data;

    $data{'jsonrpc'} = '2.0';
    $data{'method'} = 'user.login';
    $data{'params'}{'user'} = ZABBIX_USER;
    $data{'params'}{'password'} = ZABBIX_PASSWORD;
    $data{'id'} = 1;

    my $response = send_to_zabbix(\%data);

    if (!defined($response))
    {
	print "Authentication failed, zabbix server: " . ZABBIX_SERVER . "\n" if DEBUG;

	return 0;
    }

    $ZABBIX_AUTH_ID = $response->content->{'result'};

    if (!defined($ZABBIX_AUTH_ID))
    {
	print "Authentication failed, zabbix server: " . ZABBIX_SERVER . "\n" if DEBUG;

	return 0; 
    }

    print "Authentication successful. Auth ID: $ZABBIX_AUTH_ID\n" if DEBUG;

    undef $response;

    return 1;
}

#================================================================
sub zabbix_logout
{
    my %data;

    $data{'jsonrpc'} = '2.0';
    $data{'method'} = 'user.logout';
    $data{'params'} = [];
    $data{'auth'} = $ZABBIX_AUTH_ID;
    $data{'id'} = 1;

    my $response = send_to_zabbix(\%data);

    if (!defined($response))
    {
	print "Logout failed, zabbix server: " . ZABBIX_SERVER . "\n" if DEBUG;

	return 0;
    }

    print "Logout successful. Auth ID: $ZABBIX_AUTH_ID\n" if DEBUG;

    return 1;
}


#================================================================
sub send_to_zabbix
{
    my $json = shift;

    my $response;

    my $url = "http://" . ZABBIX_SERVER . "/api_jsonrpc.php";

    my $client = new JSON::RPC::Client;

    $response = $client->call($url, $json);

    return $response;
}

#================================================================
sub get_number_of_item
{
    my %data;

    $data{'jsonrpc'} = '2.0';
    $data{'method'} = 'host.get';

    $data{'params'}{'output'} = ['hostid'];
    $data{'params'}{'selectItems'} = 'count';
    $data{'params'}{'filter'}{'host'} = $HOST_NAME;

    $data{'auth'} = $ZABBIX_AUTH_ID;
    $data{'id'} = 1;

    my $response = send_to_zabbix(\%data);
    #print Dumper $response;
	
	my $items_count;
	foreach my $items(@{$response->content->{'result'}}) 
    {
		$items_count = $items->{'items'};
	}
	
	print("Items: $items_count\n") if DEBUG;
	print($items_count) if !DEBUG;
}

#================================================================
sub get_number_of_trigger
{
    my %data;

    $data{'jsonrpc'} = '2.0';
    $data{'method'} = 'host.get';

    $data{'params'}{'output'} = ['hostid'];
    $data{'params'}{'selectTriggers'} = 'count';
    $data{'params'}{'filter'}{'host'} = $HOST_NAME;

    $data{'auth'} = $ZABBIX_AUTH_ID;
    $data{'id'} = 1;

    my $response = send_to_zabbix(\%data);
	
	my $triggers_count;
	foreach my $triggers(@{$response->content->{'result'}}) 
    {
		$triggers_count = $triggers->{'triggers'};
	}
	
	print("Triggers: $triggers_count\n") if DEBUG;
	print($triggers_count) if !DEBUG;
}

#================================================================
sub main
{
    parse_argv();

    if (!defined($HOST_NAME))
    {
	print("You need to set HOST_NAME\n");

	return 0;
    }

	if (!defined($KEY))
    {
	print("You need to set KEY\n");

	return 0;
    }

    if (zabbix_auth)
    {
	if ($KEY eq 'item')
	{
	    get_number_of_item();
	}
	elsif ($KEY eq 'trigger')
	{
	    get_number_of_trigger();
	}

	zabbix_logout();
    }
}

