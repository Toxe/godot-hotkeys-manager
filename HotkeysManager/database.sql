PRAGMA foreign_keys = ON;

CREATE TABLE `properties` (
  `version` integer
);

CREATE TABLE `programgroup` (
  `id` integer PRIMARY KEY NOT NULL,
  `name` varchar(255)
);

CREATE TABLE `program` (
  `id` integer PRIMARY KEY NOT NULL,
  `name` varchar(255),
  `icon` blob
);

CREATE TABLE `programgroup_program` (
  `programgroup_id` integer NOT NULL,
  `program_id` integer NOT NULL,
  PRIMARY KEY (`programgroup_id`, `program_id`),
  FOREIGN KEY (`programgroup_id`) REFERENCES `programgroup` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`program_id`) REFERENCES `program` (`id`) ON DELETE CASCADE
);

CREATE TABLE `category` (
  `id` integer PRIMARY KEY NOT NULL,
  `name` varchar(255)
);

CREATE TABLE `command` (
  `id` integer PRIMARY KEY NOT NULL,
  `name` varchar(255)
);

CREATE TABLE `command_category` (
  `command_id` integer NOT NULL,
  `category_id` integer NOT NULL,
  PRIMARY KEY (`command_id`, `category_id`),
  FOREIGN KEY (`command_id`) REFERENCES `command` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`category_id`) REFERENCES `category` (`id`) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE `program_command` (
  `id` integer PRIMARY KEY NOT NULL,
  `program_id` integer NOT NULL,
  `command_id` integer NOT NULL,
  `name` varchar(255),
  FOREIGN KEY (`program_id`) REFERENCES `program` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`command_id`) REFERENCES `command` (`id`) ON DELETE CASCADE
);

CREATE TABLE `program_command_hotkey` (
  `id` integer PRIMARY KEY NOT NULL,
  `program_command_id` integer NOT NULL,
  `hotkey` varchar(64),
  FOREIGN KEY (`program_command_id`) REFERENCES `program_command` (`id`) ON DELETE CASCADE
);

CREATE TABLE `comment` (
  `id` integer PRIMARY KEY NOT NULL,
  `text` text,
  `time_created` datetime DEFAULT (datetime()),
  `time_changed` datetime DEFAULT (datetime())
);

CREATE TABLE `command_comment` (
  `command_id` integer NOT NULL,
  `comment_id` integer NOT NULL,
  PRIMARY KEY (`command_id`, `comment_id`),
  FOREIGN KEY (`command_id`) REFERENCES `command` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`comment_id`) REFERENCES `comment` (`id`) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE `program_command_comment` (
  `program_command_id` integer NOT NULL,
  `comment_id` integer NOT NULL,
  PRIMARY KEY (`program_command_id`, `comment_id`),
  FOREIGN KEY (`program_command_id`) REFERENCES `program_command` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`comment_id`) REFERENCES `comment` (`id`) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE `user_hotkey` (
  `id` integer PRIMARY KEY NOT NULL,
  `command_id` integer NOT NULL,
  `hotkey` varchar(64),
  FOREIGN KEY (`command_id`) REFERENCES `command` (`id`) ON DELETE CASCADE
);

CREATE TABLE `user_hotkey_program` (
  `user_hotkey_id` integer NOT NULL,
  `program_id` integer NOT NULL,
  PRIMARY KEY (`user_hotkey_id`, `program_id`),
  FOREIGN KEY (`user_hotkey_id`) REFERENCES `user_hotkey` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`program_id`) REFERENCES `program` (`id`) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE `user_hotkey_comment` (
  `user_hotkey_id` integer NOT NULL,
  `comment_id` integer NOT NULL,
  PRIMARY KEY (`user_hotkey_id`, `comment_id`),
  FOREIGN KEY (`user_hotkey_id`) REFERENCES `user_hotkey` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`comment_id`) REFERENCES `comment` (`id`) ON DELETE CASCADE
) WITHOUT ROWID;

INSERT INTO `properties` (`version`) VALUES (1);
INSERT INTO `programgroup` (`name`) VALUES ('Texteditoren'), ('Grafikprogramme');
INSERT INTO `program` (`name`) VALUES ('CLion'), ('Visual Studio'), ('Visual Studio Code'), ('Obsidian'), ('Photoshop'), ('Illustrator'), ('Krita');
INSERT INTO `programgroup_program` (`programgroup_id`, `program_id`) VALUES (1, 1), (1, 2), (1, 3), (1, 4), (2, 5), (2, 6), (2, 7);
INSERT INTO `category` (`name`) VALUES ('Navigation'), ('Files'), ('Tabs');
INSERT INTO `command` (`name`) VALUES ('Go to File'), ('Go to Next Editor Tab');
INSERT INTO `command_category` (`command_id`, `category_id`) VALUES (1, 1), (1, 2), (2, 3);
INSERT INTO `program_command` (`program_id`, `command_id`, `name`) VALUES (1, 1, 'Go to File'), (2, 1, 'Go To File'), (3, 1, 'Go to File'), (4, 1, 'Open quick switcher'), (1, 2, 'Select Next Tab'), (2, 2, 'Window.NextTab'), (3, 2, 'View: Open Next Editor'), (4, 2, 'Go to next tab');
INSERT INTO `program_command_hotkey` (`program_command_id`, `hotkey`) VALUES (1, 'Ctrl+Shift+N'), (2, 'Ctrl+1 F'), (2, 'Ctrl+1 Ctrl+F'), (2, 'Ctrl+Shift+T'), (3, 'Ctrl+P'), (3, 'Ctrl+,'), (3, 'Ctrl+E Ctrl+E'), (4, 'Ctrl+O'), (5, 'Alt+Right'), (6, 'Ctrl+Alt+PageDown'), (7, 'Ctrl+PageDown'), (8, 'Ctrl+PageDown');
INSERT INTO `comment` (`text`) VALUES ('Öffnet ein Suchfeld, in dem man nach Dateinamen suchen kann.'), ('Wechselt zum nächsten Tab.'), ('Nur über Command Palette verfügbar, nicht über Menüs.'), ('In Visual Studio in den allgemeinen Suchdialog integriert.');
INSERT INTO `command_comment` (`command_id`, `comment_id`) VALUES (1, 1), (2, 2);
INSERT INTO `program_command_comment` (`program_command_id`, `comment_id`) VALUES (4, 3);
INSERT INTO `user_hotkey` (`command_id`, `hotkey`) VALUES (1, 'Ctrl+P'), (2, 'Ctrl+PageDown');
INSERT INTO `user_hotkey_program` (`user_hotkey_id`, `program_id`) VALUES (1, 1), (1, 2), (1, 3), (1, 4), (2, 1), (2, 2), (2, 3), (2, 4);
INSERT INTO `user_hotkey_comment` (`user_hotkey_id`, `comment_id`) VALUES (2, 4);
