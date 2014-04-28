
# mysql -u root -p dev_ivent < event.sql
DROP TABLE IF EXISTS `events`;

CREATE TABLE `events` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` TEXT NOT NULL,
  `started_at` int(10) unsigned,
  `ended_at` int(10) unsigned,
 # `started_at` int(20) unsigned NOT NULL,
 # `ended_at` int(20) unsigned NOT NULL,
  `url` TEXT NOT NULL,
  `capacity` int(5) unsigned,
  `accepted` int(5) unsigned,
  `wating` int(5) unsigned,
  `location` text,
  `description` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `events_tags`;

CREATE TABLE `events_tags` (
     `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
     `event_id` int(10) unsigned,
     `tag_id` int(10) unsigned,
     PRIMARY KEY(`id`)
 )  ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `tags`;

CREATE TABLE `tags` (
     `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
     `name` text NOT NULL,
     PRIMARY KEY(`id`)
 )  ENGINE=InnoDB DEFAULT CHARSET=utf8;



