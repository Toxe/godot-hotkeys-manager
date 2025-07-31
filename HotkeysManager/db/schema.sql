PRAGMA foreign_keys = ON;

CREATE TABLE properties (
    version integer
);

CREATE TABLE programgroup (
    id integer PRIMARY KEY NOT NULL,
    name varchar(255)
);

CREATE TABLE program (
    id integer PRIMARY KEY NOT NULL,
    name varchar(255),
    icon blob
);

CREATE TABLE programgroup_program (
    programgroup_id integer NOT NULL,
    program_id integer NOT NULL,
    PRIMARY KEY (programgroup_id, program_id),
    FOREIGN KEY (programgroup_id) REFERENCES programgroup (id) ON DELETE CASCADE,
    FOREIGN KEY (program_id) REFERENCES program (id) ON DELETE CASCADE
);

CREATE TABLE category (
    id integer PRIMARY KEY NOT NULL,
    name varchar(255)
);

CREATE TABLE command (
    id integer PRIMARY KEY NOT NULL,
    name varchar(255)
);

CREATE TABLE command_category (
    command_id integer NOT NULL,
    category_id integer NOT NULL,
    PRIMARY KEY (command_id, category_id),
    FOREIGN KEY (command_id) REFERENCES command (id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE program_command (
    id integer PRIMARY KEY NOT NULL,
    program_id integer NOT NULL,
    command_id integer NOT NULL,
    name varchar(255),
    FOREIGN KEY (program_id) REFERENCES program (id) ON DELETE CASCADE,
    FOREIGN KEY (command_id) REFERENCES command (id) ON DELETE CASCADE
);

CREATE TABLE program_command_hotkey (
    id integer PRIMARY KEY NOT NULL,
    program_command_id integer NOT NULL,
    hotkey varchar(64),
    FOREIGN KEY (program_command_id) REFERENCES program_command (id) ON DELETE CASCADE
);

CREATE TABLE comment (
    id integer PRIMARY KEY NOT NULL,
    comment_text text,
    time_created datetime DEFAULT (datetime()),
    time_changed datetime DEFAULT (datetime())
);

CREATE TABLE command_comment (
    command_id integer NOT NULL,
    comment_id integer NOT NULL,
    PRIMARY KEY (command_id, comment_id),
    FOREIGN KEY (command_id) REFERENCES command (id) ON DELETE CASCADE,
    FOREIGN KEY (comment_id) REFERENCES comment (id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE program_command_comment (
    program_command_id integer NOT NULL,
    comment_id integer NOT NULL,
    PRIMARY KEY (program_command_id, comment_id),
    FOREIGN KEY (program_command_id) REFERENCES program_command (id) ON DELETE CASCADE,
    FOREIGN KEY (comment_id) REFERENCES comment (id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE user_hotkey (
    id integer PRIMARY KEY NOT NULL,
    command_id integer NOT NULL,
    hotkey varchar(64),
    FOREIGN KEY (command_id) REFERENCES command (id) ON DELETE CASCADE
);

CREATE TABLE user_hotkey_program (
    user_hotkey_id integer NOT NULL,
    program_id integer NOT NULL,
    PRIMARY KEY (user_hotkey_id, program_id),
    FOREIGN KEY (user_hotkey_id) REFERENCES user_hotkey (id) ON DELETE CASCADE,
    FOREIGN KEY (program_id) REFERENCES program (id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE TABLE user_hotkey_comment (
    user_hotkey_id integer NOT NULL,
    comment_id integer NOT NULL,
    PRIMARY KEY (user_hotkey_id, comment_id),
    FOREIGN KEY (user_hotkey_id) REFERENCES user_hotkey (id) ON DELETE CASCADE,
    FOREIGN KEY (comment_id) REFERENCES comment (id) ON DELETE CASCADE
) WITHOUT ROWID;

INSERT INTO properties (version) VALUES (1);
