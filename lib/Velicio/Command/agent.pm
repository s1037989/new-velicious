package Velicio::Command::agent;

use Mojo::Base 'Mojolicious::Command';

has description => "Start Velicio as an agent.\n";
has usage => <<"EOF";
usage: $0 agent
EOF

has config => sub { shift->app->config->{probe} };

sub run {
  my($self, @args) = @_;

  my $loop = Mojo::IOLoop->singleton;
  $SIG{QUIT} = sub { $loop->max_connnections(0) };

  $self->app->agent->probe if $self->config;

  $loop->start;
  return 0;
}

1;
