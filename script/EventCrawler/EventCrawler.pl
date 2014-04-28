package EventCrawler;

use strict;
use warnings;
use utf8;
use v5.10;
use File::Spec;
use File::Basename;
use lib File::Spec->rel2abs(dirname(__FILE__), '.');

use LWP::UserAgent;
use URI;
use Time::Piece;
use Try::Tiny;
use JSON::Parse qw(parse_json);
use Data::Dumper;
use Encode qw(encode decode);

use EventParser;
use inserting_mysql;


sub crawl {
  my ($keywords, $site_name) = @_;
  my $months = _get_next_months();

# 各サイトのURLとパラメータ
  my $site_requests = {
    atnd => {
      url => 'http://api.atnd.org/events/',
      params => {
        keyword_or => $keywords,
        format     => 'json',
        ym         => $months,
        count      => 100,
        start      => 1,
      }
    },
    connpass => {
      url => 'http://connpass.com/api/v1/event/',
      params => {
        keyword_or => $keywords,
        format     => 'json',
        ym         => $months,
        count      => 100,
        start      => 1,
      }
    },
    zusaar => {
      url => 'http://www.zusaar.com/api/event/',
      params => {
        keyword_or => $keywords,
        format     => 'json',
        ym         => $months,
        count      => 100,
        start      => 1,
      }
    },
    doorkeeper => {
      url => 'http://api.doorkeeper.jp/events/',
      params => {
        q      => $keywords,
        locale => 'ja',
        since  => _since_time($months),
        until  => _until_time($months),
      }
    }
  };

  my $json = download($site_requests->{$site_name}->{url}, $site_requests->{$site_name}->{params});
  $json = decode('UTF-8', $json);
  return [] unless defined $json;

  my $perl = parse_json($json);
  return &{$parse_hash->{$site_name}}($perl);
}

sub  download {
  my ($url, $params) = @_;

  my $uri = URI->new($url);
  $uri->query_form($params);

  my $user_agent = LWP::UserAgent->new(
    timeout => 30,
  );

  my $response = $user_agent->get($uri);
  unless ($response->is_success) {
    die "Fetch error: " . $response->status_line;
    return undef;
  }

  return $response->content;
}


sub _get_next_months {
  my $tp = localtime;
  return [
    $tp->strftime('%Y%m'),
    $tp->add_months(1)->strftime('%Y%m'),
    $tp->add_months(2)->strftime('%Y%m'),
  ];
}

sub _since_time {
  my $months = shift;
  my $tp = Time::Piece->strptime($months->[0], '%Y%m');
  $tp -= 9 * (60 * 60);  # 9時間引く
  return $tp->strftime('%Y-%m-%dT%H:%M:%S'),
}

sub _until_time {
  my $months = shift;
  my $tp = Time::Piece->strptime($months->[-1], '%Y%m');
  $tp = $tp->add_months(1);
  $tp -= 9 * (60 * 60);  # 9時間引く
  return $tp->strftime('%Y-%m-%dT%H:%M:%S'),
}



my $tags_config_file = 'tags.pl';
my $tags = do $tags_config_file or die "$!$@";
my @site_names = qw(atnd connpass zusaar doorkeeper);

while (my ($key, $tag) = each %$tags) {
  say 'keyword = ' . $key . ":";
  for my $site_name (@site_names) {
    say '    target = ' . $site_name . ':'; 
    my $events = crawl($tag->{keywords}, $site_name);
    for my $event (@$events) {
      say '        event title: ' . encode('UTF-8', $event->{name});
      insert_events($event, $tag->{name});
    }
  }
  sleep 1;
  say "";
}

