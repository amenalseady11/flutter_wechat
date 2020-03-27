
CREATE TABLE t_contact (
    serializeId INTEGER NOT NULL
                        PRIMARY KEY AUTOINCREMENT
                        UNIQUE,
    profileId    TEXT    NOT NULL,
    friendId    TEXT    NOT NULL
                        UNIQUE,
    mobile      TEXT    NOT NULL
                        UNIQUE,
    nickname    TEXT    NOT NULL,
    remark      TEXT    NOT NULL,
    avatar      TEXT    NOT NULL,
    initials    TEXT    DEFAULT '#',
    black       INTEGER NOT NULL
                        DEFAULT (3)
);


CREATE TABLE t_group (
    serializeId  INTEGER NOT NULL
                         PRIMARY KEY AUTOINCREMENT
                         UNIQUE,
    profileId    TEXT    NOT NULL,
    groupId      TEXT    NOT NULL
                         UNIQUE,
    name         TEXT    NOT NULL,
    announcement TEXT    NOT NULL,
    createId     TEXT    NOT NULL,
    status       INTEGER NOT NULL,
    members      TEXT    NOT NULL
);



CREATE TABLE t_chat(
    serializeId      INTEGER NOT NULL
                             PRIMARY KEY AUTOINCREMENT
                             UNIQUE,
    profileId    TEXT    NOT NULL,
    sourceType       INTEGER NOT NULL
                             DEFAULT (0),
    sourceId         TEXT    NOT NULL
                             UNIQUE,
    unread           INTEGER NOT NULL
                             DEFAULT (0),
    unreadTag        INTEGER NOT NULL
                             DEFAULT (0),
    top              INTEGER NOT NULL
                             DEFAULT (0),
    visible          INTEGER NOT NULL
                             DEFAULT (0),
    [offset]         INTEGER NOT NULL
                             DEFAULT (0),
    latestUpdateTime INTEGER NOT NULL
);


CREATE TABLE t_chat_message (
    serializeId  INTEGER NOT NULL
                         PRIMARY KEY AUTOINCREMENT
                         UNIQUE,
    profileId    TEXT    NOT NULL,
    sourceId     TEXT    NOT NULL,
    [offset]     INT     NOT NULL,
    type         TEXT    NOT NULL,
    body         TEXT    NOT NULL,
    fromFriendId TEXT    NOT NULL,
    fromNickname TEXT    NOT NULL,
    fromAvatar   TEXT    NOT NULL,
    toFriendId   TEXT,
    sendId       TEXT    NOT NULL,
    sendTime     INTEGER NOT NULL,
    status       INTEGER NOT NULL,
    state        INTEGER NOT NULL,
    extra1       TEXT,
    extra2       TEXT,
    extra3       TEXT,
    extra4       TEXT
);
