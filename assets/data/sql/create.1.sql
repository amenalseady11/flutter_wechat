
CREATE TABLE t_contact (
    serializeId INTEGER NOT NULL
                        PRIMARY KEY AUTOINCREMENT
                        UNIQUE,
    profileId    TEXT    NOT NULL,
    friendId    TEXT    NOT NULL,
    mobile      TEXT    NOT NULL,
    nickname    TEXT    NOT NULL,
    remark      TEXT    NOT NULL,
    avatar      TEXT    NOT NULL,
    initials    TEXT    DEFAULT '#',
    black       INTEGER NOT NULL
                        DEFAULT (3),
    status       INTEGER NOT NULL
                        DEFAULT (0)
);
CREATE UNIQUE INDEX t_contact_unique ON t_contact(profileId, friendId);
CREATE UNIQUE INDEX t_contact_unique2 ON t_contact(profileId, mobile);

CREATE TABLE t_group (
    serializeId  INTEGER NOT NULL
                         PRIMARY KEY AUTOINCREMENT
                         UNIQUE,
    profileId    TEXT    NOT NULL,
    groupId      TEXT    NOT NULL,
    name         TEXT    NOT NULL,
    announcement TEXT    NOT NULL,
    createId     TEXT    NOT NULL,
    forbidden    INTEGER NOT NULL
                        DEFAULT (1),
    status       INTEGER NOT NULL
                        DEFAULT (0),
    instTime     INTEGER NOT NULL,
    updtTime     INTEGER NOT NULL,
    members      TEXT    NOT NULL
);
CREATE UNIQUE INDEX t_group_unique ON t_group(profileId, groupId);


CREATE TABLE t_chat(
    serializeId      INTEGER NOT NULL
                             PRIMARY KEY AUTOINCREMENT
                             UNIQUE,
    profileId    TEXT    NOT NULL,
    sourceType       INTEGER NOT NULL
                             DEFAULT (0),
    sourceId         TEXT    NOT NULL,
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
CREATE UNIQUE INDEX t_chat_unique ON t_chat(profileId, sourceId);


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
    readStatus   INTEGER NOT NULL
);
CREATE UNIQUE INDEX t_chat_message_unique ON t_chat_message(profileId, sourceId, sendId);