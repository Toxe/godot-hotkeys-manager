PRAGMA foreign_keys = ON;

CREATE TABLE properties (
    version INTEGER
);

CREATE TABLE programgroup (
    programgroup_id INTEGER PRIMARY KEY NOT NULL,
    name TEXT COLLATE nocase
);

CREATE TABLE program (
    program_id INTEGER PRIMARY KEY NOT NULL,
    name TEXT COLLATE nocase,
    abbreviation TEXT COLLATE nocase
);

CREATE TABLE program_icon (
    program_id INTEGER NOT NULL,
    icon BLOB,
    PRIMARY KEY (program_id),
    FOREIGN KEY (program_id) REFERENCES program (program_id) ON DELETE CASCADE
);

CREATE TABLE programgroup_program (
    programgroup_id INTEGER NOT NULL,
    program_id INTEGER NOT NULL,
    PRIMARY KEY (programgroup_id, program_id),
    FOREIGN KEY (programgroup_id) REFERENCES programgroup (programgroup_id) ON DELETE CASCADE,
    FOREIGN KEY (program_id) REFERENCES program (program_id) ON DELETE CASCADE
);

CREATE TABLE category (
    category_id INTEGER PRIMARY KEY NOT NULL,
    name TEXT COLLATE nocase
);

CREATE TABLE command (
    command_id INTEGER PRIMARY KEY NOT NULL,
    name TEXT COLLATE nocase
);

CREATE TABLE command_category (
    command_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    PRIMARY KEY (command_id, category_id),
    FOREIGN KEY (command_id) REFERENCES command (command_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES category (category_id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE program_command_hotkey (
    program_id INTEGER NOT NULL,
    command_id INTEGER NOT NULL,
    hotkey TEXT NOT NULL,
    PRIMARY KEY (program_id, command_id, hotkey),
    FOREIGN KEY (program_id) REFERENCES program (program_id) ON DELETE CASCADE,
    FOREIGN KEY (command_id) REFERENCES command (command_id) ON DELETE CASCADE
);

CREATE TABLE comment (
    comment_id INTEGER PRIMARY KEY NOT NULL,
    comment_text TEXT,
    time_created DATETIME DEFAULT (datetime()),
    time_changed DATETIME DEFAULT (datetime())
);

CREATE TABLE command_comment (
    command_id INTEGER NOT NULL,
    comment_id INTEGER NOT NULL,
    PRIMARY KEY (command_id, comment_id),
    FOREIGN KEY (command_id) REFERENCES command (command_id) ON DELETE CASCADE,
    FOREIGN KEY (comment_id) REFERENCES comment (comment_id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE program_command_comment (
    program_id INTEGER NOT NULL,
    command_id INTEGER NOT NULL,
    comment_id INTEGER NOT NULL,
    PRIMARY KEY (program_id, command_id, comment_id),
    FOREIGN KEY (program_id) REFERENCES program (program_id) ON DELETE CASCADE,
    FOREIGN KEY (command_id) REFERENCES command (command_id) ON DELETE CASCADE,
    FOREIGN KEY (comment_id) REFERENCES comment (comment_id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE user_hotkey (
    user_hotkey_id INTEGER PRIMARY KEY NOT NULL,
    command_id INTEGER NOT NULL,
    hotkey TEXT,
    FOREIGN KEY (command_id) REFERENCES command (command_id) ON DELETE CASCADE
);

CREATE TABLE user_hotkey_program (
    user_hotkey_id INTEGER NOT NULL,
    program_id INTEGER NOT NULL,
    PRIMARY KEY (user_hotkey_id, program_id),
    FOREIGN KEY (user_hotkey_id) REFERENCES user_hotkey (user_hotkey_id) ON DELETE CASCADE,
    FOREIGN KEY (program_id) REFERENCES program (program_id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE user_hotkey_comment (
    user_hotkey_id INTEGER NOT NULL,
    comment_id INTEGER NOT NULL,
    PRIMARY KEY (user_hotkey_id, comment_id),
    FOREIGN KEY (user_hotkey_id) REFERENCES user_hotkey (user_hotkey_id) ON DELETE CASCADE,
    FOREIGN KEY (comment_id) REFERENCES comment (comment_id) ON DELETE CASCADE
) WITHOUT ROWID;

INSERT INTO properties (version) VALUES (1);
