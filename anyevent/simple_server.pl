#!/usr/bin/env perl 
use strict;
use warnings;
use utf8;

use IO::Socket::INET;
use AnyEvent;
use AnyEvent::Util;
$AnyEvent::Util::MAX_FORKS = 15;

# use v5.30.0;
use strict;
use warnings;
use Try::Tiny;
use AnyEvent::HTTPD;

#use JSON qw/encode_json decode_json/;
use Cpanel::JSON::XS;

my $json = Cpanel::JSON::XS->new;

# $json->boolean_values(['false', 'true']);

my $handled = 0;
$|++;

my $port = 3005;

my $host = '165.227.237.186';

my $server = IO::Socket::INET->new(
    'Proto'     => 'tcp',
    'LocalAddr' => $host,
    'LocalPort' => $port,
    'Listen'    => SOMAXCONN,
    'Reuse'     => 1,
) or die "can't setup server: $!\n";
print "Listening on $host:$port\n";

my $cv = AnyEvent->condvar;
my $w;
$w = AnyEvent->io(
    fh   => \*{$server},
    poll => 'r',
    cb   => sub {
        $handled++;
        $cv->begin;
        fork_call sub { &handle_connections }, $server->accept, sub {
            my ($client) = @_;
            print " - Client $client closed\n";
        }
    }
);
$cv->recv;

#
# Subroutines
#
sub handle_connections {
    my ($client) = @_;

    my $host = $client->peerhost;
    print "[Accepted connection from $host]\n";

    while ( my $input = <$client> ) {
        chomp $input;
        print "Got: $input\n";
        my $res = process($input);
        print "Return: " . $res . "\n";
        print $client $res . "\n";
        last if $res eq 'malformed';
    }

    $cv->end;
    return $host;
}

sub process {
    my ($raw_content) = @_;

    #$raw_content = '{"number":"1234","method":"isPrime"}';
    print STDERR "Got a request $raw_content\n";
    my $malformed = 0;

    # $malformed = 1 if $raw_content =~ m/"number"\s*:\s*"/;
    # $malformed = 1 if $raw_content =~ m/"number"\s*:\s*(true|false)/;

    print STDERR "malformed=$malformed\n";
    my $content;
    try {
        $content = $json->decode($raw_content);
    }
    catch {
        $malformed = 1;
    };

    use Data::Dumper;
    print STDERR Dumper($content);
    print STDERR "malformed=$malformed\n";
    $malformed = 1 if !$content;
    print STDERR "malformed=$malformed\n";
    $malformed = 1 if ( $content->{method} || '' ) ne 'isPrime';
    print STDERR "malformed=$malformed\n";
    $malformed = 1 if ( $content->{number} // '' ) !~ /^-?\d+\.?\d*$/;
    print STDERR "malformed=$malformed\n";
    $malformed = 1 if $json->is_bool( $content->{number} );
    print STDERR "malformed=$malformed\n";
    $malformed = 1
      if ( !exists $content->{bignumber} ) && ( !isnum( $content->{number} ) );
    print STDERR "malformed=$malformed\n";

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

sub isnum ($) {
    return 0 if $_[0] eq '';
    $_[0] ^ $_[0] ? 0 : 1;
}

