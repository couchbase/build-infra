import mariadb
import sys
import time


def get_connection():
    db = mariadb.connect(
        host="database",
        port=3306,
        user="user",
        password="password",
        database="pathdiff"
    )
    cursor = db.cursor(prepared=True, buffered=True)
    return [db, cursor]


def bootstrap():
    """
    Runs when the API comes up
    new tables should be created in here
    """
    [db, cursor] = get_connection()
    print("Ensuring listings table present")
    cursor.execute("""create table if not exists listings(
        id bigint auto_increment,
        status  VARCHAR(12),
        product VARCHAR(24),
        edition VARCHAR(16),
        version VARCHAR(16),
        build   VARCHAR(8),
        distro  VARCHAR(12),
        files   LONGTEXT,
        url     VARCHAR(128),
        runcmd  BLOB,
        msg   BLOB,
        PRIMARY KEY (id))
    """)
    db.close()


def exec(q, p):
    """ Execute a prepared statement """
    [db, cursor] = get_connection()
    cursor.execute(q, p)
    cursor.close()
    db.commit()
    db.close()


def query(q, p=()):
    """ Execute a prepared statement and retrieve results """
    [db, cursor] = get_connection()
    cursor.execute(q, p)
    records = cursor.fetchall()
    cursor.close()
    db.commit()
    db.close()
    return records
