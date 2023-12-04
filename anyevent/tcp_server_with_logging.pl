use v5.30.0;
use warnings;

use AnyEvent::Socket;
use AnyEvent::Log;
use HTTP::Response;
use HTTP::Status qw(:constants :is status_message);

# Can't get this to work. Doesn't change the level.
AnyEvent::Log::ctx->level ('debug');

AE::log error => "Division by zero attempted.";
AE::log warn  => "Couldn't delete the file.";
AE::log note  => "Attempted to create config, but config already exists.";
AE::log info  => "File soandso successfully deleted.";
AE::log debug => "the function returned 3";
AE::log trace => "going to call function abc";

my $cv1 = AnyEvent->condvar;

# a simple tcp server
# my $server = tcp_server '127.0.0.1', 8888, sub {
my $server = tcp_server '165.227.237.186', 3001, sub {
   my ($fh, $host, $port) = @_;
 
   say 'Got something!';
   my $response = HTTP::Response->new(200, 'OK', ['Content-Type' => 'text/html'], 'Hello World');
   say $response->as_string;
   syswrite $fh, 'HTTP/1.0 ' . $response->as_string;
}, sub {
   my ($fh, $thishost, $thisport) = @_;
   say 'Hello ' . "Bound to $thishost, port $thisport.";

   
   AnyEvent::Log::ctx->level ('debug');
   AE::log info => "INFO Bound to $thishost, port $thisport.";
};

say 'Starting at ' . localtime();
$cv1->recv;
say 'Ending at ' . localtime();
