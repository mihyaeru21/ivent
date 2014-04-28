package ivent::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::RouterBoom;
use Data::Dumper;
use URI::Escape;
use Encode qw/encode decode/;
use Time::Local qw(timelocal);

any '/' => sub {
    my ($c) = @_;

#    print Dumper $c->{request}->{env}->{HTTP_COOKIE};

#cookieの取得
    my $cookies = $c->{request}->{env}->{HTTP_COOKIE};    #ブラウザからクッキーの取得
        my %COOKIE;
    my @checked_tags;
    my $checked_location = "";
#取得したクッキーの整形
    my @pairs = split(/;/, $cookies);
    foreach my $pair (@pairs) {
        my ($name, $value) = split(/=/, $pair);
        $name =~ s/ //g;

        $COOKIE{$name} = $value;

#欲しいクッキー内の情報を取り出す
        if($name eq "selected_tags") {
            $value = uri_unescape($value);
            @checked_tags = split(/,/, $value);
#        print Dumper @tags;
        }

        if($name eq "selected_location") {
            $value = uri_unescape($value);
            $checked_location = $value;
#        print Dumper $checked_location;
        }
    }

#都道府県の配列
    my @prefectures = ("北海道","青森県","岩手県","宮城県","秋田県","山形県","福島県", "茨城県","栃木県","群馬県","埼玉県","千葉県","東京都","神奈川県", "新潟県","富山県","石川県","福井県","山梨県","長野県","岐阜県","静岡県","愛知県","三重県","滋賀県","京都府","大阪府","兵庫県","奈良県","和歌山県","鳥取県","島根県","岡山県","広島県","山口県","徳島県","香川県","愛媛県","高知県","福岡県","佐賀県","長崎県","熊本県","大分県","宮崎県","鹿児島県","沖縄県");

#DBからtagを取得する
    my @all_tags;
    my @id_checked_tags;
    my @serch_event_ids;
    my @list_event_info;
    my @eventid_tagid;
    my $tags = $c->db->search_named(
            q{SELECT * FROM tags ORDER BY id DESC},
            );

    while( my $row = $tags->next)
    {
#tagとidのハッシュ
        my $hash_atag = {id => $row->id+0, name => $row->name};
        push(@all_tags, $hash_atag);

#チェックされたtagとidの連想配列
        foreach my $ctag (@checked_tags) {
            if(decode('UTF-8', $ctag) eq $row->name) {
                push(@id_checked_tags, $row->id+0);
            }
        }
    }

#検索日から30日後のunixtimeを計算
    my ($sec, $min, $hh, $dd, $mm, $yy, $weak, $yday, $opt) = gmtime(time());
    $mm += 1;
    $yy += 1900;
    my $search_start_time = timelocal(0, 0, 0, $dd, $mm-1, $yy, $weak, $yday, $opt);
    my $search_end_time = timelocal(0, 0, 0, $dd, $mm, $yy, $weak, $yday, $opt);
#print Dumper $search_time;

#チェックされたタグがあれば、それにに関するイベント情報を取得
    if(@id_checked_tags) {
        my $iter = $c->db->search_named(
                q{SELECT event_id, tag_id FROM events_tags WHERE tag_id IN :ids},
                {ids => \@id_checked_tags}
                );
        while( my $row = $iter->next) {
            push(@serch_event_ids, $row->event_id+0);
            my $hash = {"event_id" => $row->event_id+0, "tag_id" => $row->tag_id+0};
            push(@eventid_tagid, $hash);
        }
    }
    else {
        my $iter = $c->db->search_named(
                q{SELECT event_id, tag_id FROM events_tags},
                );
        while( my $row = $iter->next) {
            push(@serch_event_ids, $row->event_id+0);
            my $hash = {"event_id" => $row->event_id+0, "tag_id" => $row->tag_id+0};
            push(@eventid_tagid, $hash);
        }
    }

    if(@serch_event_ids) {
#取得したイベントIDを検索
        if(!($checked_location eq "")) {
            my $iter_e = $c->db->search_named(
                    q{SELECT * FROM events WHERE location = :location AND started_at < :search_end_time AND started_at > :search_start_time AND id IN :ids ORDER BY started_at ASC},
                    {search_end_time => $search_end_time, search_start_time => $search_start_time , location => $checked_location, ids => \@serch_event_ids}
                    );

            while(my $row = $iter_e->next) {
                my $hash_ev = {id => $row->id, name => $row->name, url => $row->url, capacity => $row->capacity, accepted => $row->accepted, wating => ($row->capacity - $row->accepted), location => $row->location, description => $row->description};
                my $date = changeFromUnixtime($row->started_at, $row->ended_at);
                $hash_ev->{date} = $date;

                push(@list_event_info, $hash_ev); 
            }

        }
        else {
            my $iter_e = $c->db->search_named(
                    q{SELECT * FROM events WHERE location IN :location AND started_at < :search_end_time AND started_at > :search_start_time AND id IN :ids ORDER BY started_at ASC},
                    {search_end_time => $search_end_time, search_start_time => $search_start_time , location => \@prefectures, ids => \@serch_event_ids}
                    );

            while(my $row = $iter_e->next) {
                my $hash_ev = {id => $row->id, name => $row->name, url => $row->url, capacity => $row->capacity, accepted => $row->accepted, wating => ($row->capacity - $row->accepted), location => $row->location, description => $row->description};
                my $date = changeFromUnixtime($row->started_at, $row->ended_at);
                $hash_ev->{date} = $date;

                push(@list_event_info, $hash_ev); 
            }

        }

    }


#    while(my $row = $iter->next) {
#    print Dumper $row->ivent_id;
#   }

#選択されました都道府県の配列番号を探す
    my $array_number_prefectures;
    if(!($checked_location eq "")) {
        for (my $i = 0; $i < 47; $i++) {
            if(decode('UTF-8', $checked_location) eq $prefectures[$i]) {
                $array_number_prefectures = $i;
                last;
            }
        }
    }

    return $c->render('test.tx' => {list_event_info => \@list_event_info, all_tags => \@all_tags, id_checked_tags => \@id_checked_tags, checked_location => $checked_location , prefectures => \@prefectures, array_number_prefectures => $array_number_prefectures, eventid_tagid => \@eventid_tagid});
};

post '/account/logout' => sub {
    my ($c) = @_;
    $c->session->expire();
    return $c->redirect('/');
};

#unixtimeから年、月、日、開始時刻と終了時刻を計算
#(started_unixtime, ended_unixtime) -> 文字列：yy/mm/dd time ~ time
#時間が正しくないかも・・・修正は後回しで
sub changeFromUnixtime {
#ここで引数を@_受け取る
    my ($started_unixtime, $ended_unixtime) = @_;

    my ($started_sec, $started_min, $started_hour, $started_day, $started_month, $started_year) = gmtime($started_unixtime);
    $started_year += 1900;
    $started_month += 1;

    my ($ended_sec, $ended_min, $ended_hour, $ended_day, $ended_month, $ended_year) = gmtime($ended_unixtime);
    $ended_year += 1900;
    $ended_month += 1;

    my $dis_s_min;
    my $dis_e_min;
    my $dis_s_hour;
    my $dis_e_hour;

#数が1桁の場合に先頭に0をつける
    if($started_min < 10) {
        $dis_s_min = ":"."0".$started_min;
    } else {
        $dis_s_min = ":".$started_min;
    }
    if($ended_min < 10) {
        $dis_e_min = ":"."0".$ended_min;
    }else {
        $dis_e_min = ":".$ended_min;
    }

    if($started_hour < 10 ) {
        $dis_s_hour = " "."0".$started_hour;
    }else{
        $dis_s_hour = " ".$started_hour;
    }

    if($ended_hour < 10) {
        $dis_e_hour = " "."0".$ended_hour;
    } else {
        $dis_e_hour = " ".$ended_hour;
    }

    return $started_year."/".$started_month."/".$started_day."\n".$started_hour.$dis_s_min." ~ ".$dis_e_hour.$dis_e_min;
}

1;
