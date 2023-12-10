#!/usr/bin/env perl 

#use v5.30.0;
use warnings;
use utf8;

use IO::Socket::INET;
use AnyEvent;
use AnyEvent::Util;
use Try::Tiny;
use Cpanel::JSON::XS;
use Getopt::Long;

$AnyEvent::Util::MAX_FORKS = 15;

$|++; # Flush

my $json = Cpanel::JSON::XS->new;

my $port = 3005;

my $host = '165.227.237.186';

my $verbose = 0;

my ($server, $cv, $w);

GetOptions ("port=i" => \$port,    # numeric
            "host=s"   => \$host,      # string
            "verbose"  => \$verbose)   # flag
or die("Error in command line arguments\n");


sub main {
$server = IO::Socket::INET->new(
    'Proto'     => 'tcp',
    'LocalAddr' => $host,
    'LocalPort' => $port,
    'Listen'    => SOMAXCONN,
    'Reuse'     => 1,
) or die "can't setup server: $!\n";
print "Listening on $host:$port\n";

$cv = AnyEvent->condvar;

$w = AnyEvent->io(
    fh   => \*{$server},
    poll => 'r',
    cb   => sub {
        $cv->begin;
        fork_call sub { &handle_connections }, $server->accept, sub {
            my ($client) = @_;
            print STDERR " - Client $client closed\n" if $verbose;
        }
    }
);
$cv->recv;
}

main() if ! caller;

#
# Subroutines
#
sub handle_connections {
    my ($client) = @_;

    my $host = $client->peerhost;
    print STDERR "[Accepted connection from $host]\n" if $verbose;

    while ( my $input = <$client> ) {
        chomp $input;
        print STDERR "Got: $input\n" if $verbose;

        my $res = process($input);
        print STDERR "Return: " . $res . "\n" if $verbose;

        print $client $res . "\n";
        last if $res eq 'malformed';
    }

    $cv->end;
    return $host;
}

sub process {
    my ($raw_content) = @_;

    print STDERR "Got a request $raw_content\n" if $verbose;
    my $malformed = 0;

    my $content;
    try {
        $content = $json->decode($raw_content);
    }
    catch {
        $malformed = 1;
    };

    $malformed = 1 if !$content;

    $malformed = 1 if ( $content->{method} || '' ) ne 'isPrime';

    $malformed = 1 if ( $content->{number} // '' ) !~ /^-?\d+\.?\d*$/;

    $malformed = 1 if $json->is_bool( $content->{number} );

    if (( !exists($content->{bignumber}) ) && ( !is_num( $content->{number} ) )) {
	print STDERR "$content->{number} looks like it is a string\n" if $verbose;
	$malformed = 1;
    }

    if ($malformed) {
        return "malformed";
    }

    if ( !is_prime( $content->{number} ) ) {
        return encode_json( { method => 'isPrime', prime => $json->false } ),;
    }

    return encode_json( { "method" => "isPrime", "prime" => $json->true } );
}

sub is_prime {
    my $number = shift;
    return 0 if $number < 2;
    my $sqrt = sqrt $number;
    my $i    = 2;
    while ( $i <= $sqrt ) {
        return 0 if $number % $i == 0;
        $i++;
    }
    return 1;
}

# https://stackoverflow.com/questions/1804311/how-can-i-tell-if-a-number-is-a-whole-number-in-perl
# Doesn't work with v5.30.
sub is_num ($) {
    no warnings;
    return 0 if $_[0] eq '';
    $_[0] ^ $_[0] ? 0 : 1;
}

