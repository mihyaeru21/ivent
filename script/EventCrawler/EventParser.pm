package EventParser;

use strict;
use warnings;
use utf8;
use v5.10;

use Time::Piece;
use Text::Textile qw(textile);
use HTML::Entities;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(parse_atnd parse_connpass parse_zusaar parse_doorkeeper $parse_hash);

our $parse_hash = {
  atnd       => \&parse_atnd,
  connpass   => \&parse_connpass,
  zusaar     => \&parse_zusaar,
  doorkeeper => \&parse_doorkeeper,
};



# ATND
sub parse_atnd {
  my $perl = shift;
  my $ret = [];

  for my $event (@{$perl->{events}}) {
    push @$ret, +{
      name        => $event->{title} . "",
      started_at  => parse_datetime_atnd($event->{started_at}),
      ended_at    => parse_datetime_atnd($event->{ended_at}),
      url         => $event->{event_url} . "",
      capacity    => $event->{limit} + 0,
      accepted    => $event->{accepted} + 0,
      location    => extract_prefecuture($event->{address}),
      description => remove_html_tags($event->{description}),
    };
  }

  return $ret;
}

#connpass
#2014-05-17T20:00:00+09:00
sub parse_connpass {
  my $perl = shift;
  my $ret = [];

  for my $event (@{$perl->{events}}) {
    push @$ret, +{
      name        => $event->{title} . "",
      started_at  => parse_datetime_atnd($event->{started_at}),
      ended_at    => parse_datetime_atnd($event->{ended_at}),
      url         => $event->{event_url} . "",
      capacity    => $event->{limit} + 0,
      accepted    => $event->{accepted} + 0,
      location    => extract_prefecuture($event->{address}),
      description => remove_html_tags($event->{description}),
    };
  }

  return $ret;
}

#zusaar
#2014-05-16T19:30:00+09:00
sub parse_zusaar {
  my $perl = shift;
  my $ret = [];

  for my $event (@{$perl->{event}}) {
    push @$ret, +{
      name        => $event->{title} . "",
      started_at  => parse_datetime_atnd($event->{started_at}),
      ended_at    => parse_datetime_atnd($event->{ended_at}),
      url         => $event->{event_url} . "",
      capacity    => $event->{limit} + 0,
      accepted    => $event->{accepted} + 0,
      location    => extract_prefecuture($event->{address}),
      description => remove_html_tags($event->{description}),
    };
  }

  return $ret;
}

# DoorKeeper
#2014-05-24T08:00:00.000Z
sub parse_doorkeeper {
  my $perl = shift;
  my $ret = [];

  for my $event (@$perl) {
    $event = $event->{event};
    push @$ret, +{
      name        => $event->{title} . "",
      started_at  => parse_datetime_doorkeeper($event->{starts_at}),
      ended_at    => parse_datetime_doorkeeper($event->{ends_at}),
      url         => $event->{public_url} . "",
      capacity    => $event->{ticket_limit} + 0,
      accepted    => $event->{participants} + 0,
      location    => extract_prefecuture($event->{address}),
      description => remove_html_tags($event->{description}),
    };

  }

  return $ret;
}

#google calendar
#json EX) http://www.google.com/calendar/feeds/fvijvohm91uifvd9hratehf65k@group.calendar.google.com/public/full-noattendees?max-results=10&alt=jsonc 
=pod
sub parse_google {
  my $h = shift;
  my $ret = [];

  for my $entry (@{$perl->{data}->{items}}) {
    push @$ret, +{

      url => $entry->{details} . "",

    };
  }

  return $ret;
}
=cut

#siteごとに違う
sub parse_datetime_atnd {
  Time::Piece->strptime(shift, '%Y-%m-%dT%H:%M:%S+09:00');
}

sub parse_datetime_doorkeeper {
  #2014-05-24T08:00:00.000Z
  my $str = shift;
  my $tp = Time::Piece->strptime($str, '%Y-%m-%dT%H:%M:%S.000Z');
  $tp += 9 * (60 * 60);  # 9時間進める(良いやり方あるやろ)
  return $tp;
}

sub remove_html_tags {
  my $html = shift;

  $html = textile($html);
  $html =~ s/<.*?>/ /g;
  $html =~ s/\s+/ /g;
  my $text = HTML::Entities::decode_entities($html);
  my $text = HTML::Entities::decode_entities($text);

  my $max_length = 100;
  return length $text > $max_length
    ? substr($text, 0, $max_length - 1) . '…'
    : $text;
}


# 住所から都道府県を絞り込む
sub extract_prefecuture {
  my $address = shift;

  return undef unless defined $address;

  my @prefs = (
    {name => '東京都', re => qr/東京都|足立区|荒川区|板橋区|江戸川区|大田区|葛飾区|江東区|品川区|渋谷区|新宿区|杉並区|墨田区|世田谷区|台東区|千代田区|豊島区|中野区|練馬区|文京区|港区|目黒区/},
    {name => '北海道', re => qr/北海道|札幌市|釧路市/},
    {name => '青森県', re => qr/青森[県市]/},
    {name => '岩手県', re => qr/岩手県|盛岡市/},
    {name => '宮城県', re => qr/宮城県|仙台市/},
    {name => '秋田県', re => qr/秋田[県市]/},
    {name => '山形県', re => qr/山形[県市]/},
    {name => '福島県', re => qr/福島[県市]/},
    {name => '茨城県', re => qr/茨城県|水戸市/},
    {name => '栃木県', re => qr/栃木県|宇都宮市/},
    {name => '群馬県', re => qr/群馬県|前橋市|高崎市/},
    {name => '埼玉県', re => qr/埼玉県|さいたま市/},
    {name => '千葉県', re => qr/千葉[県市]/},
    {name => '神奈川県', re => qr/神奈川県|横浜市|鎌倉市/},
    {name => '新潟県', re => qr/新潟[県市]|長岡市/},
    {name => '富山県', re => qr/富山[県市]/},
    {name => '石川県', re => qr/石川[県市]/},
    {name => '福井県', re => qr/福井[県市]/},
    {name => '山梨県', re => qr/山梨県|甲府市/},
    {name => '長野県', re => qr/長野[県市]/},
    {name => '岐阜県', re => qr/岐阜[県市]/},
    {name => '静岡県', re => qr/静岡[県市]|浜松市/},
    {name => '愛知県', re => qr/愛知県|名古屋市/},
    {name => '三重県', re => qr/三重県|津市/},
    {name => '滋賀県', re => qr/滋賀県|大津市/},
    {name => '京都府', re => qr/京都[府市]/},
    {name => '大阪府', re => qr/大阪[府市]|堺市/},
    {name => '兵庫県', re => qr/兵庫県|神戸市/},
    {name => '奈良県', re => qr/奈良[県市]/},
    {name => '和歌山県', re => qr/和歌山[県市]/},
    {name => '鳥取県', re => qr/鳥取[県市]/},
    {name => '島根県', re => qr/島根県|松江市/},
    {name => '岡山県', re => qr/岡山[県市]/},
    {name => '広島県', re => qr/広島[県市]/},
    {name => '山口県', re => qr/山口[県市]/},
    {name => '徳島県', re => qr/徳島[県市]/},
    {name => '香川県', re => qr/香川県|高松市/},
    {name => '愛媛県', re => qr/愛媛県|松山市/},
    {name => '高知県', re => qr/高知[県市]/},
    {name => '福岡県', re => qr/福岡[県市]|北九州市/},
    {name => '佐賀県', re => qr/佐賀[県市]/},
    {name => '長崎県', re => qr/長崎[県市]/},
    {name => '熊本県', re => qr/熊本[県市]/},
    {name => '大分県', re => qr/大分[県市]/},
    {name => '宮崎県', re => qr/宮崎[県市]/},
    {name => '鹿児島県', re => qr/鹿児島[県市]/},
    {name => '沖縄県', re => qr/沖縄県|那覇市/},
  );

  for my $pref (@prefs) {
    return $pref->{name}
      if $address =~ $pref->{re};
  }

  return undef;
}

1;
