use v5.30.0;
use warnings;

use AnyEvent::Socket;
use HTTP::Response;
use HTTP::Status qw(:constants :is status_message);

my $cv1 = AnyEvent->condvar;

# a simple tcp server
# Call as http://dgc100.com:3001
my $server = tcp_server '165.227.237.186', 3001, sub {
   my ($fh, $host, $port) = @_;
 
   say STDERR 'Got something!';

   my $response = HTTP::Response->new(200, 'OK', ['Content-Type' => 'text/html'], 'Hello World');
   say $response->as_string;

   syswrite $fh, 'HTTP/1.0 ' . $response->as_string;
}, sub {
   my ($fh, $thishost, $thisport) = @_;
   say STDERR 'Hello ' . "Bound to $thishost, port $thisport.";
   
};

say STDERR 'Starting at ' . localtime();
$cv1->recv;
say STDERR 'Ending at ' . localtime();
