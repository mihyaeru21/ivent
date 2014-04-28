use strict;
use warnings;
use utf8;
use v5.10;

use lib qw(../);
use Test::More qw(no_plan);

use JSON::Parse qw(parse_json);
use Time::Piece;
use Encode qw(decode encode);
use EventParser;
use inserting_mysql;


test_parse(
  'atnd', {
    name        => 'Titaniumもくもく会 #18',
    started_at  => '2014-04-23 19:30:00',
    ended_at    => '2014-04-23 21:30:00',
    url         => 'http://atnd.org/events/48628',
    limit       => 50,
    accepted    => 25,
    location    => '東京都渋谷区渋谷1-1-8 青山ダイヤモンドビル',
    description => 'Appcelerator オフィシャルT',
  }
);

test_parse(
  'connpass', {
    name        => '第9回 Haskellもくもく会',
    started_at  => '2014-05-17 13:00:00',
    ended_at    => '2014-05-17 19:30:00',
    url         => 'http://connpass.com/event/6063/',
    limit       => 10,
    accepted    => 3,
    location    => '東京都新宿区百人町2-27-6',
    description => 'この勉強会について趣味や仕事で書いてるプ',
  }
);

test_parse(
  'zusaar', {
    name        => 'Perl入学式in東京 #1',
    started_at  => '2014-04-26 13:00:00',
    ended_at    => '2014-04-26 17:00:00',
    url         => 'http://www.zusaar.com/event/4977008',
    limit       => 40,
    accepted    => 40,
    location    => '東京都品川区西五反田1-21-8 KSS五反田ビル',
    description => '&lt; 参加希望者の皆様へ &gt;参',
  }
);

test_parse(
  'doorkeeper', {
    name        => 'Scala勉強会第124回 in 本郷 ',
    started_at  => '2014-04-23 20:00:00',
    ended_at    => '2014-04-23 21:30:00',
    url         => 'http://rpscala.doorkeeper.jp/events/10734',
    limit       => 15,
    accepted    => 13,
    location    => '東京都文京区本郷1丁目 28-34 本郷MKビル２F',
    description => '概要 Scala関係なら何でもありの勉強',
  }
);

test_mysql(
   {
    name        => 'Scala勉強会第124回 in 本郷 ',
    started_at  => '2014-04-23 20:00:00',
    ended_at    => '2014-04-23 21:30:00',
    url         => 'http://rpscala.doorkeeper.jp/events/107342',
    capacity    => 15,
    accepted    => 13,
    wating    => 2,
    location    => '東京都文京区本郷1丁目 28-34 本郷MKビル２F',
    description => '概要 Scala関係なら何でもありの勉強',
  }
  );


sub test_parse {
  my ($name, $hash) = @_;
  my $methods = {
    atnd => \&parse_atnd,
    connpass => \&parse_connpass,
    zusaar => \&parse_zusaar,
    doorkeeper => \&parse_doorkeeper,
  };

  open my $fh, '<', "./t/data/${name}.json" or die "${name} data can not open";
  my $json;
  {
    local $/ = undef;
    $json = readline $fh;
  }

  subtest "${name} parser test" => sub {
    my $perl = parse_json($json);
    my $events = $methods->{$name}($perl);
    my $e = $events->[0];

    ok $e->{name} eq $hash->{name}, 'title';
    ok $e->{started_at} == Time::Piece->strptime($hash->{started_at}, '%Y-%m-%d %H:%M:%S'), 'started_at';
    ok $e->{ended_at} == Time::Piece->strptime($hash->{ended_at}, '%Y-%m-%d %H:%M:%S'), 'ended_at';
    ok $e->{url} eq $hash->{url}, 'url';
    ok $e->{capacity} == $hash->{limit}, 'limit';
    ok $e->{accepted} == $hash->{accepted}, 'accepted';
    ok $e->{location} eq $hash->{location}, 'location';
    ok substr($e->{description}, 0, 20) eq $hash->{description}, 'description';

    done_testing();
  };

  sub test_mysql {
  my ($hash) = @_;
    subtest "mysql test" => sub {
      ok insert_events($hash,'perl');
      done_testing();
    };
  }
}

