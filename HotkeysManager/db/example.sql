PRAGMA foreign_keys = ON;

INSERT INTO programgroup (name) VALUES
('Texteditoren'),
('Grafikprogramme'),
('Group 3'),
('Group 4');

INSERT INTO program (name, abbreviation) VALUES
('CLion', 'CL'),
('Visual Studio', 'VS'),
('Visual Studio Code', 'VSCode'),
('Obsidian', 'Obs'),
('Photoshop', 'Ps'),
('Illustrator', 'Ai'),
('Krita', 'Kr'),
('Firefox', 'FF'),
('Vivaldi', 'Viv'),
('Chrome', 'Chr');

INSERT INTO programgroup_program (programgroup_id, program_id) VALUES
(1, 1),
(1, 2),
(1, 3),
(1, 4),
(2, 5),
(2, 6),
(2, 7),
(3, 7),
(3, 8),
(3, 9),
(3, 10);

INSERT INTO category (name) VALUES
('Navigation'),
('Files'),
('Tabs');

INSERT INTO command (name) VALUES
('Go to File'),
('Go to Next Editor Tab'),
('New Tab'),
('New Window'),
('Close Tab'),
('Close All Tabs');

INSERT INTO command_category (command_id, category_id) VALUES
(1, 1),
(1, 2),
(2, 3);

INSERT INTO program_command (program_id, command_id, name) VALUES
(1, 1, 'Go to File'),
(2, 1, 'Go To File'),
(3, 1, 'Go to File'),
(4, 1, 'Open quick switcher'),
(1, 2, 'Select Next Tab'),
(2, 2, 'Window.NextTab'),
(3, 2, 'View: Open Next Editor'),
(4, 2, 'Go to next tab'),
(8, 3, 'New Tab'),
(10, 5, 'Close Tab');

INSERT INTO program_command_hotkey (program_command_id, hotkey) VALUES
(1, 'Ctrl+Shift+N'),
(2, 'Ctrl+1 F'),
(2, 'Ctrl+1 Ctrl+F'),
(2, 'Ctrl+Shift+T'),
(3, 'Ctrl+P'),
(3, 'Ctrl+,'),
(3, 'Ctrl+E Ctrl+E'),
(4, 'Ctrl+O'),
(5, 'Alt+Right'),
(6, 'Ctrl+Alt+PageDown'),
(7, 'Ctrl+PageDown'),
(8, 'Ctrl+PageDown'),
(9, 'Ctrl+T'),
(10, 'Ctrl+W');

INSERT INTO comment (comment_text) VALUES
('Öffnet ein Suchfeld, in dem man nach Dateinamen suchen kann.'),
('Wechselt zum nächsten Tab.'),
('Nur über Command Palette verfügbar, nicht über Menüs.'),
('In Visual Studio in den allgemeinen Suchdialog integriert.');

INSERT INTO command_comment (command_id, comment_id) VALUES
(1, 1),
(2, 2);

INSERT INTO program_command_comment (program_command_id, comment_id) VALUES
(4, 3);

INSERT INTO user_hotkey (command_id, hotkey) VALUES
(1, 'Ctrl+P'),
(2, 'Ctrl+PageDown'),
(5, 'Ctrl+W'),
(4, 'Ctrl+N');

INSERT INTO user_hotkey_program (user_hotkey_id, program_id) VALUES
(1, 1),
(1, 2),
(1, 3),
(1, 4),
(2, 1),
(2, 2),
(2, 3),
(2, 4),
(3, 7),
(3, 8),
(4, 9);

INSERT INTO user_hotkey_comment (user_hotkey_id, comment_id) VALUES
(2, 4);
