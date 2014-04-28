package ivent::DB::Schema;
use strict;
use warnings;
use utf8;

use Teng::Schema::Declare;

base_row_class 'ivent::DB::Row';

table {
    name 'events';
    pk 'id';
    columns qw(id name started_at ended_at url capacity accepted wating location description);
};

table {
    name 'events_tags';
    pk 'id';
    columns qw(id event_id tag_id);
};

table {
    name 'tags';
    pk 'id';
    columns qw(id name);
};

1;
