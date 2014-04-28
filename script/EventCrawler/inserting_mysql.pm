use strict;
use warnings;
use utf8;
use DBIx::Sunny;
use v5.10;
use Time::Piece;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(insert_events _insert_events_tags _insert_tag);

=exampledata_
my $events_data = {
    name        => 'Scala勉強会第124回 in 本郷 ',
    started_at  => '2014-04-23 20:00:00',
    ended_at    => '2014-04-23 21:30:00',
    url         => 'http://rpscala.doorkeeper.jp/events/10734',
    limit       => 15,
    accepted    => 13,
    wating		=> 2,
    location    => '東京都文京区本郷1丁目 28-34 本郷MKビル２F',
    description => '概要 Scala関係なら何でもありの勉強',
  };

my $events_tags_data = {
	event_id 	=> 1,
	tag_id		=> 'PeRL',
};

my $tags_data = {
	name 	=> 'perl',
};

_insert_events($events_data);
_insert_events_tags($events_tags_data);
_insert_tag($tags_data);

=cut

sub _db_connect {
    my $self = shift;

	my $database = "dev_ivent";
	my $host = "localhost";
	my $userid = "root";
	my $passwd = "root";
	my $connectionInfo="dbi:mysql:$database;$host";

    my $dbh = DBIx::Sunny->connect($connectionInfo,$userid,$passwd);

    return $dbh;
}

sub insert_events {
	my ($hash,$search_word) = @_;
	my $dbh = _db_connect();

	#urlの存在を確認
	my $row = $dbh->select_row(
			'SELECT url FROM events where url = ? ',
			$hash->{url},
		);

	if($row){
		say "already a url ";
		# events update 
		$dbh->query(
			# id, name, started_at, ended_at, url, limit, accepted, wating(unusing), location, desription; 
			'UPDATE events SET name=?, started_at=?, ended_at=?, capacity=?, accepted=?, wating=?, location=?, description=? where url =?',
			$hash->{name},
			$hash->{started_at}->epoch,
			$hash->{ended_at}->epoch,
			$hash->{capacity},
			$hash->{accepted},
			$hash->{wating},
			$hash->{location},
			$hash->{description},
			$hash->{url},
		);
	}else{
		# events insert 
		$dbh->query(
			# id, name, started_at, ended_at, url, limit, accepted, wating(unusing), location, desription; 
			'INSERT INTO events values (0,?,?,?,?,?,?,?,?,?);',
			$hash->{name},
			$hash->{started_at}->epoch,
			$hash->{ended_at}->epoch,
			$hash->{url},
			$hash->{capacity},
			$hash->{accepted},
			$hash->{wating},
			$hash->{location},
			$hash->{description},
		);
	}

	#eventIdをGET.
	my $eventid = $dbh->select_row(
			'SELECT id FROM events where url = ? ',
			$hash->{url},
		);

	say "EVENT ID :: ".$eventid->{id};

	_insert_events_tags({
		    event_id    => $eventid->{id},
		    tag_name	=> $search_word,
		});
}

sub _insert_events_tags {
	my ($hash) = @_;
	my $dbh = _db_connect();

	my $row = $dbh->select_row(
			'SELECT * FROM tags where name = ? ',
			$hash->{tag_name},
		);

	if($row){
		say "already a tag.";
	}else{
		say "can't found this tag. create this.";
		_insert_tag($hash->{tag_name});
	}

	my $check_events_tag = $dbh->select_row(
			'SELECT * FROM events_tags where event_id = ? AND tag_id = (SELECT IFNULL(id,\'null\') from tags where name = ?)',
			$hash->{event_id},
			$hash->{tag_name},
	);

	if($check_events_tag){
		say "already this events_tags";
	}
	else{
	 	$dbh->query(
			'insert into events_tags(event_id,tag_id) values(?, (SELECT IFNULL(id,999) from tags where name = ?) )',
			$hash->{event_id},
			$hash->{tag_name},
		);
	}
}

sub _insert_tag {
	my $self = shift;
	my $dbh = _db_connect();
	# tag
	$dbh->query(
		'insert into tags(name) values(?)',
		$self,
	);
}
