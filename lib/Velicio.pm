package Velicio;

use Mojo::Base 'Mojolicious';

use Velicio::Agent;

our $VERSION = "0.01";

has version => sub { $VERSION };
has protocol => sub { int($_[1] || $VERSION) };
has agent => sub { Velicio::Agent->new({app=>shift->app}) };

sub startup {
  my $self = shift;

  $self->plugin('Config' => {default=>{
    manager => {
      listen => 'http://*:3500',
      #relay => {
      #  manager => 'localhost',
      #  manager_port => 3500,
      #},
    },
    agent => {
      manager_url => 'localhost:3500',
      #probe => {
      #  scan => '192.168.0.0/24',
      #}
    },
  }});

  $ENV{MOJO_LISTEN} = $self->app->config->{manager}->{listen};

  my $r = $self->routes;
  $r->get('/' => sub { shift->render(text => "Hello, World!") });
  $r->websocket('/manager')->to('Manager#websocket');
}

1;
