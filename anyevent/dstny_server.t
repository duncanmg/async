#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Differences;
use Cpanel::JSON::XS;

require './dstny_server.pl';

my $json = Cpanel::JSON::XS->new;

ok( is_num(123),       '123 is a number' );
ok( is_num(123.45),    '123.45 is a number' );
ok( !is_num("123"),    '"123" is not a number' );
ok( !is_num("123.45"), '"123.45" is not a number' );

ok( !is_prime(125), '125 is not a prime number' );
ok( is_prime(13),   '13 is a prime number' );

cmp_json(
    process(
            '{"method":"isPrime",'
          . '"number":58167621602249282114632629139453318045707752387257598698'
          . ',"bignumber":true}'
    ),
    '{"prime":false,"method":"isPrime"}',
    'Accepts big non-prime number'
);

cmp_json(
    process('{"number":192931,"method":"isPrime"}'),
    '{"prime":true,"method":"isPrime"}',
    'Accepts prime number'
);

cmp_json(
    process('{"number":192932,"method":"isPrime"}'),
    '{"prime":false,"method":"isPrime"}',
    'Accepts non-prime number'
);

is( process('{"number":"192931","method":"isPrime"}'),
    'malformed', 'Rejects string that looks like a number.' );
is( process('{"number":"ABC","method":"isPrime"}'),
    'malformed', 'Rejects string.' );
is( process('{"numberr":123,"method":"isPrime"}'),
    'malformed', 'Rejects bad name.' );
is( process('{"number":123,"mmethod":"isPrime"}'),
    'malformed', 'Rejects bad method name.' );
is( process('{"number":123,"method":"isPrimex"}'),
    'malformed', 'Rejects bad method value.' );

done_testing;

sub cmp_json {
    my ( $got, $expected, $msg ) = @_;
    return eq_or_diff( $json->decode($got), $json->decode($expected), $msg );
}

