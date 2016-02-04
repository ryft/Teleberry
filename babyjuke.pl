#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(lib);

use Mojolicious::Lite;
use BabyJuke::Control;

my $omxd = BabyJuke::Control->new;

plugin 'TagHelpers';

helper status => sub {
    my $c = shift;

    my $omxd_status = $omxd->status;
    my ($status, $progress, $total, $id) = ("Unknown", 0, 0);

    if ($omxd_status =~ /^(\w+) (\d+)\/(\d+) .*\/([\w-]{11})\b/) {
        ($status, $progress, $total, $id) = ($1, $2, $3, $4);
    } elsif ($omxd_status =~ /^(\w+) (\d+)\/(\d+)\b/) {
        ($status, $progress, $total) = ($1, $2, $3);
    }

    my $media = $id ? $omxd->cache->get($id) : {};
    my $icon  = $status =~ /stopped/i ? 'stop'  :
                $status =~ /playing/i ? 'play'  :
                $status =~ /paused/i  ? 'pause' :
                                        'question';
    my $change_icon = $status =~ /playing/i ? 'pause' : 'play';
    $progress = $total == 0 ? $total : ($progress / $total) * 100;

    $c->stash(
        status_text => $status,
        status_icon => $icon,
        change_icon => $change_icon,
        progress    => $progress,
        id          => $id,
        artist      => $media->{artist},
        title       => $media->{title},
    );
};

get '/' => sub {
    my $c = shift;
    $c->status;
    $c->render(template => 'index');
};

post '/navigate/:function' => sub {
    my $c = shift;
    $c->render(json => $omxd->navigate($c->param('function')));
};
post '/volume/:direction' => sub {
    my $c = shift;
    $c->render(json => $omxd->volume($c->param('direction')));
};
post '/download/:id/:function' => sub {
    my $c = shift;
    my $result = $omxd->download_and_queue($c->param('id'), $c->param('function'));
    $c->render(json => $result);
};
post '/queue/:id/:function' => sub {
    my $c = shift;
    my $result = $omxd->queue($c->param('id'), $c->param('function'));
    $c->render(json => $result);
};

app->start;

