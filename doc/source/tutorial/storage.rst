.. highlightlang:: none

Storage mode
============

Here we explain how to use storage mode of Mroonga

How to use full text search
---------------------------

After confirming the installation, let's create a table. The important point is to specify Mroonga by ``ENGINE = Mroonga``:

.. code-block:: sql

   CREATE TABLE diaries (
     id INT PRIMARY KEY AUTO_INCREMENT,
     content VARCHAR(255),
     FULLTEXT INDEX (content)
   ) ENGINE = Mroonga DEFAULT CHARSET utf8;
   -- Query OK, 0 rows affected (0.10 sec)

We put data by INSERT:

.. code-block:: sql

   INSERT INTO diaries (content) VALUES ("It'll be fine tomorrow.");
   -- Query OK, 1 row affected (0.01 sec)

   INSERT INTO diaries (content) VALUES ("It'll rain tomorrow");
   -- Query OK, 1 row affected (0.00 sec)

Try full text search:

.. code-block:: sql

   SELECT * FROM diaries WHERE MATCH(content) AGAINST("+fine" IN BOOLEAN MODE);
   -- +----+-----------------------------------------+
   -- | id | content                                 |
   -- +----+-----------------------------------------+
   -- |  1 | It'll be fine tomorrow. |
   -- +----+-----------------------------------------+
   -- 1 row in set (0.00 sec)

Yes, full text search works.

How to get search score
-----------------------

.. note::

   In version 1.0.0 or before, Mroonga used a special column named ``_score`` to get search score. From version 1.0.0, it follows MySQL's standard way to get search score.

We often want to display more relevant results first in full text search. We use search score in such case.

We can get search score by MySQL's standard way [#score]_, i.e. we use MATCH...AGAINST in one of columns in SELECT or ORDER BY.

Let's try:

.. code-block:: sql

   INSERT INTO diaries (content) VALUES ("It's fine today. It'll be fine tomorrow as well.");
   -- Query OK, 1 row affected (0.00 sec)

   INSERT INTO diaries (content) VALUES ("It's fine today. But it'll rain tomorrow.");
   -- Query OK, 1 row affected (0.00 sec)

   SELECT *,
          MATCH (content) AGAINST ("+fine" IN BOOLEAN MODE)
     FROM diaries
    WHERE MATCH (content) AGAINST ("+fine" IN BOOLEAN MODE)
    ORDER BY
          MATCH (content) AGAINST ("+fine" IN BOOLEAN MODE) DESC;
   -- +----+--------------------------------------------------+---------------------------------------------------+
   -- | id | content                                          | MATCH (content) AGAINST ("+fine" IN BOOLEAN MODE) |
   -- +----+--------------------------------------------------+---------------------------------------------------+
   -- |  3 | It's fine today. It'll be fine tomorrow as well. |                                                 2 |
   -- |  1 | It'll be fine tomorrow.                          |                                                 1 |
   -- |  4 | It's fine today. But it'll rain tomorrow.        |                                                 1 |
   -- +----+--------------------------------------------------+---------------------------------------------------+
   -- 3 rows in set (0.00 sec)

The result having the search word ``fine`` more, i.e. ``id = 3`` message having the higher search score, is displayed first. And you also get search score by using MATCH AGAINST in SELECT phrase.

You can use ``AS`` to change the attribute name:

.. code-block:: sql

   SELECT *,
          MATCH (content) AGAINST ("+fine" IN BOOLEAN MODE) AS score
     FROM diaries
    WHERE MATCH (content) AGAINST ("+fine" IN BOOLEAN MODE)
    ORDER BY
          MATCH (content) AGAINST ("+fine" IN BOOLEAN MODE) DESC;
   -- +----+--------------------------------------------------+-------+
   -- | id | content                                          | score |
   -- +----+--------------------------------------------------+-------+
   -- |  3 | It's fine today. It'll be fine tomorrow as well. |     2 |
   -- |  1 | It'll be fine tomorrow.                          |     1 |
   -- |  4 | It's fine today. But it'll rain tomorrow.        |     1 |
   -- +----+--------------------------------------------------+-------+
   -- 3 rows in set (0.00 sec)

How to specify the parser for full text search
----------------------------------------------

MySQL has the following syntax to specify the parser [#parser]_ for full text search::

  FULLTEXT INDEX (content) WITH PARSER parser_name

To use this syntax, you need to register all parsers in MySQL beforehand. On the other hand, Groonga can dynamically add a tokenizer, that is a parser in MySQL. So if use this syntax in Mroonga, tokenizers that are added in Groonga dynamically cannot be supported. We think that this limitation decreases the convenience, and we choose our own syntax using COMMENT like the following::

  FULLTEXT INDEX (content) COMMENT 'tokenizer "TokenMecab"'

.. note::

   ``COMMENT`` in ``FULLTEXT INDEX`` is only supported MySQL 5.5 or later. If you use MySQL 5.1, use ``mroonga_default_tokenizer`` variable described below.

You can specify one of the following values as the tokenizer. "tokenizer" in Mroonga equals to "parser" in MySQL.

.. include:: tokenizer-list.inc

You can specify the default parser by passing ``--with-default-tokenizer`` option in ``configure`` when you build Mroonga::

  ./configure --with-default-tokenizer TokenMecab ...

Or you can set ``mroonga_default_tokenizer`` variable in ``my.cnf`` or by SQL. If you specify it in ``my.cnf``, the change will not be lost after restarting MySQL, but you need to restart MySQL to make it effective. On the other hand, if you set it in SQL, the change is effective immediately, but it will be lost when you restart MySQL.

my.cnf::

  [mysqld]
  mroonga_default_tokenizer=TokenMecab

SQL:

.. code-block:: sql

   SET GLOBAL mroonga_default_tokenizer = TokenMecab;
   -- Query OK, 0 rows affected (0.00 sec)

How to specify the normalizer
-----------------------------

Mroonga uses normalizer corresponding to the encoding of document.
It is used when tokenizing text and storing table key.

It is used ``NormalizerMySQLGeneralCI`` normalizer when the encoding is
``utf8_general_ci`` or ``utf8mb4_general_ci``.

It is used ``NormalizerMySQLUnicodeCI`` normalizer when the encoding is
``utf8_unicode_ci`` or ``utf8mb4_unicode_ci``.

It isn't used normalizer when the encoding is ``utf8_bin``.

Here is an example that uses ``NormalizerMySQLUnicodeCI`` normalizer by specifying ``utf8_unicode_ci``:

.. code-block:: sql

   SET NAMES utf8;
   -- Query OK, 0 rows affected (0.00 sec)

   CREATE TABLE diaries (
     day DATE PRIMARY KEY,
     content VARCHAR(64) NOT NULL,
     FULLTEXT INDEX (content)
   ) Engine=Mroonga DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
   -- Query OK, 0 rows affected (0.18 sec)

   INSERT INTO diaries VALUES ("2013-04-23", "ブラックコーヒーを飲んだ。");
   -- Query OK, 1 row affected (0.00 sec)

   SELECT *
     FROM diaries
    WHERE MATCH (content) AGAINST ("+ふらつく" IN BOOLEAN MODE);
   -- +------------+-----------------------------------------+
   -- | day        | content                                 |
   -- +------------+-----------------------------------------+
   -- | 2013-04-23 | ブラックコーヒーを飲んだ。 |
   -- +------------+-----------------------------------------+
   -- 1 row in set (0.00 sec)

   SELECT *
     FROM diaries
    WHERE MATCH (content) AGAINST ("+ﾌﾞﾗｯｸ" IN BOOLEAN MODE);
   -- +------------+-----------------------------------------+
   -- | day        | content                                 |
   -- +------------+-----------------------------------------+
   -- | 2013-04-23 | ブラックコーヒーを飲んだ。 |
   -- +------------+-----------------------------------------+
   -- 1 row in set (0.00 sec)

Mroonga has the following syntax to specify Groonga's normalizer::

  FULLTEXT INDEX (content) COMMENT 'normalizer "NormalizerAuto"'

See `Groonga's document <http://groonga.org/docs/reference/normalizers.html>`_ document about Groonga's normalizer.

Here is an example that uses ``NormalizerAuto`` normalizer:

.. code-block:: sql

   SET NAMES utf8;
   -- Query OK, 0 rows affected (0.00 sec)

   CREATE TABLE diaries (
     day DATE PRIMARY KEY,
     content VARCHAR(64) NOT NULL,
     FULLTEXT INDEX (content) COMMENT 'normalizer "NormalizerAuto"'
   ) Engine=Mroonga DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
   -- Query OK, 0 rows affected (0.19 sec)

   INSERT INTO diaries VALUES ("2013-04-23", "ブラックコーヒーを飲んだ。");
   -- Query OK, 1 row affected (0.00 sec)

   SELECT *
     FROM diaries
    WHERE MATCH (content) AGAINST ("+ふらつく" IN BOOLEAN MODE);
   -- Empty set (0.00 sec)

   SELECT *
     FROM diaries
    WHERE MATCH (content) AGAINST ("+ﾌﾞﾗｯｸ" IN BOOLEAN MODE);
   -- +------------+-----------------------------------------+
   -- | day        | content                                 |
   -- +------------+-----------------------------------------+
   -- | 2013-04-23 | ブラックコーヒーを飲んだ。 |
   -- +------------+-----------------------------------------+
   -- 1 row in set (0.00 sec)

How to specify the token filters
--------------------------------

Mroonga has the following syntax to specify Groonga's token filters.::

  FULLTEXT INDEX (content) COMMENT 'token_filters "TokenFilterStem"'

Here is an example that uses ``TokenFilterStem`` token filter:

.. code-block:: sql

   SELECT mroonga_command('register token_filters/stem');
   -- +------------------------------------------------+
   -- | mroonga_command('register token_filters/stem') |
   -- +------------------------------------------------+
   -- | true                                           |
   -- +------------------------------------------------+
   -- 1 row in set (0.00 sec)

   CREATE TABLE memos (
     id INT NOT NULL PRIMARY KEY,
     content TEXT NOT NULL,
     FULLTEXT INDEX (content) COMMENT 'normalizer "NormalizerAuto", token_filters "TokenFilterStem"'
   ) Engine=Mroonga DEFAULT CHARSET=utf8;
   -- Query OK, 0 rows affected (0.18 sec)

   INSERT INTO memos VALUES (1, "I develop Groonga");
   -- Query OK, 1 row affected (0.00 sec)

   INSERT INTO memos VALUES (2, "I'm developing Groonga");
   -- Query OK, 1 row affected (0.00 sec)

   INSERT INTO memos VALUES (3, "I developed Groonga");
   -- Query OK, 1 row affected (0.00 sec)

   SELECT *
     FROM memos
    WHERE MATCH (content) AGAINST ("+develops" IN BOOLEAN MODE);
   -- +----+------------------------+
   -- | id | content                |
   -- +----+------------------------+
   -- |  1 | I develop Groonga      |
   -- |  2 | I'm developing Groonga |
   -- |  3 | I developed Groonga    |
   -- +----+------------------------+
   -- 3 rows in set (0.01 sec)

See `Groonga's document <http://groonga.org/docs/reference/token_filters.html>`_ document about Groonga's token filter.

Here is an example that uses ``TokenFilterStopWord`` token filter:

.. code-block:: sql

   SELECT mroonga_command("register token_filters/stop_word");
   -- +-----------------------------------------------------+
   -- | mroonga_command("register token_filters/stop_word") |
   -- +-----------------------------------------------------+
   -- | true                                                |
   -- +-----------------------------------------------------+
   -- 1 row in set (0.00 sec)

   CREATE TABLE terms (
     term VARCHAR(64) NOT NULL PRIMARY KEY,
     is_stop_word BOOL NOT NULL
   ) Engine=Mroonga COMMENT='tokenizer "TokenBigram", token_filters "TokenFilterStopWord"' DEFAULT CHARSET=utf8;
   -- Query OK, 0 rows affected (0.12 sec)

   CREATE TABLE memos (
     id INT NOT NULL PRIMARY KEY,
     content TEXT NOT NULL,
     FULLTEXT INDEX (content) COMMENT 'table "terms"'
   ) Engine=Mroonga DEFAULT CHARSET=utf8;
   -- Query OK, 0 rows affected (0.17 sec)

   INSERT INTO terms VALUES ("and", true);
   -- Query OK, 1 row affected (0.00 sec)

   INSERT INTO memos VALUES (1, "Hello");
   -- Query OK, 1 row affected (0.00 sec)

   INSERT INTO memos VALUES (2, "Hello and Good-bye");
   -- Query OK, 1 row affected (0.00 sec)

   INSERT INTO memos VALUES (3, "Good-bye");
   -- Query OK, 1 row affected (0.00 sec)

   SELECT *
     FROM memos
    WHERE MATCH (content) AGAINST ('+"Hello and"' IN BOOLEAN MODE);
   -- +----+--------------------+
   -- | id | content            |
   -- +----+--------------------+
   -- |  1 | Hello              |
   -- |  2 | Hello and Good-bye |
   -- +----+--------------------+
   -- 2 rows in set (0.01 sec)

It's used that specifying the lexicon table for fulltext search.

How to specify Groonga's column flags
-------------------------------------

Mroonga has the following syntax to specify Groonga's column flags::

  content TEXT COMMENT 'flags "COLUMN_SCALAR|COMPRESS_ZLIB"'

Here is an example that uses ``COMPRESS_ZLIB`` flag:

.. code-block:: sql

   CREATE TABLE entries (
     id INT UNSIGNED PRIMARY KEY,
     content TEXT COMMENT 'flags "COLUMN_SCALAR|COMPRESS_ZLIB"'
   ) Engine=Mroonga DEFAULT CHARSET=utf8;
   -- Query OK, 0 rows affected (0.12 sec)

See `Groonga's document <http://groonga.org/docs/reference/commands/column_create.html#parameters>`_ document about Groonga's column flags.

How to use geolocation search
-----------------------------

In storage mode, you can use fast geolocation search in addition to full text search. But unlike MyISAM, you can only store POINT type data. You cannot store other types data like LINE. And fast search using index only supports MBRContains. It does not support MBRDisjoint.

For the table definition for geolocation search, you need to define a POINT type column like in MyISAM and define SPATIAL INDEX for it.:

.. code-block:: sql

   CREATE TABLE shops (
     id INT PRIMARY KEY AUTO_INCREMENT,
     name VARCHAR(255),
     location POINT NOT NULL,
     SPATIAL INDEX (location)
   ) ENGINE = Mroonga;
   -- Query OK, 0 rows affected (0.06 sec)

To store data, you create POINT type data by using geomFromText() function like in MyISAM:

.. code-block:: sql

   INSERT INTO shops VALUES (null, 'Nezu''s Taiyaki', GeomFromText('POINT(139.762573 35.720253)'));
   -- Query OK, 1 row affected (0.00 sec)

   INSERT INTO shops VALUES (null, 'Naniwaya', GeomFromText('POINT(139.796234 35.730061)'));
   -- Query OK, 1 row affected (0.00 sec)

   INSERT INTO shops VALUES (null, 'Yanagiya Taiyaki', GeomFromText('POINT(139.783981 35.685341)'));
   -- Query OK, 1 row affected (0.00 sec)

If you want to find shops within the rectangle where Ikebukuro station (139.7101 35.7292) is the top-left point and Tokyo Station (139.7662 35.6815) is the bottom-right point, SELECT phrase is like the following:

.. code-block:: sql

   SELECT id, name, AsText(location)
     FROM shops
    WHERE MBRContains(GeomFromText('LineString(139.7101 35.7292, 139.7662 35.6815)'), location);
   -- +----+-----------------------+------------------------------------------+
   -- | id | name                  | AsText(location)                         |
   -- +----+-----------------------+------------------------------------------+
   -- |  1 | Nezu's Taiyaki        | POINT(139.762572777778 35.7202527777778) |
   -- +----+-----------------------+------------------------------------------+
   -- 1 row in set (0.00 sec)

Here you can search by geolocation!

How to get the record ID
------------------------

Groonga assigns a unique number to identify the record when a record is added in the table.

To make the development of applications easier, you can get this record ID by SQL in Mroonga

To get the record ID, you need to create a column named ``_id`` when you create a table:

.. code-block:: sql

   CREATE TABLE memos (
     _id INT,
     content VARCHAR(255),
     UNIQUE KEY (_id) USING HASH
   ) ENGINE = Mroonga;
   -- Query OK, 0 rows affected (0.04 sec)

Tye typo of ``_id`` column should be integer one (TINYINT, SMALLINT, MEDIUMINT, INT or BIGINT).

You can create an index for _id column, but it should be HASH type.

Let's add records in the table by INSERT. Since _id column is implemented as a virtual column and its value is assigned by Groonga, you cannot specify the value when updating.
So you need to exclude it from setting columns, or you need to use ``null`` as its value:

.. code-block:: sql

   INSERT INTO memos VALUES (null, "Saury for today's dinner.");
   -- Query OK, 1 row affected (0.00 sec)

   INSERT INTO memos VALUES (null, "Update mroonga tomorrow.");
   -- Query OK, 1 row affected (0.00 sec)

   INSERT INTO memos VALUES (null, "Buy some dumpling on the way home.");
   -- Query OK, 1 row affected (0.00 sec)

   INSERT INTO memos VALUES (null, "Thank God It's meat day.");
   -- Query OK, 1 row affected (0.00 sec)

To get the record ID, you invoke SELECT with _id column:

.. code-block:: sql

   SELECT * FROM memos;
   -- +------+------------------------------------------+
   -- | _id  | content                                  |
   -- +------+------------------------------------------+
   -- |    1 | Saury for today's dinner.                |
   -- |    2 | Update mroonga tomorrow.                 |
   -- |    3 | Buy some dumpling on the way home.       |
   -- |    4 | Thank God It's meat day.                 |
   -- +------+------------------------------------------+
   -- 4 rows in set (0.00 sec)

By using last_insert_grn_id function, you can also get the record ID that is assigned by the last INSERT:

.. code-block:: sql

   INSERT INTO memos VALUES (null, "Just one bottle of milk in the fridge.");
   -- Query OK, 1 row affected (0.00 sec)

   SELECT last_insert_grn_id();
   -- +----------------------+
   -- | last_insert_grn_id() |
   -- +----------------------+
   -- |                    5 |
   -- +----------------------+
   -- 1 row in set (0.00 sec)

last_insert_grn_id function is included in Mroonga as a User-Defined Function (UDF), but if you have not yet register it in MySQL by CREATE FUNCTION, you need to invoke the following SQL for defining a function:

.. code-block:: sql

   CREATE FUNCTION last_insert_grn_id RETURNS INTEGER SONAME 'ha_mroonga.so';

As you can see in the example above, you can get the record ID by _id column or last_insert_grn_id function. It will be useful to use this value in the ensuing SQL queries like UPDATE:

.. code-block:: sql

   UPDATE memos SET content = "So much milk in the fridge." WHERE _id = last_insert_grn_id();
   -- Query OK, 1 row affected (0.00 sec)
   -- Rows matched: 1  Changed: 1  Warnings: 0

How to get snippet (Keyword in context)
---------------------------------------

Mroonga provides functionality to get keyword in context.
It is implemented as :doc:`/reference/udf/mroonga_snippet` UDF.

How to use similar search
-------------------------

Similar search is supported by specifying document itself instead of specifying keywords in query.

It is useful if you want to find documents which is related to specific document.

Here is the schema definition for execution examples:

.. code-block:: sql

   CREATE TABLE similarities (
     id INT PRIMARY KEY AUTO_INCREMENT,
     title VARCHAR(32),
     content VARCHAR(255),
     FULLTEXT INDEX (content)
   ) ENGINE = Mroonga DEFAULT CHARSET utf8;

Here is the sample data for execution examples:

.. code-block:: sql

   INSERT INTO similarities (title, content)
          VALUES ('Groonga similar search', 'Groonga is an open-source fulltext search engine and column store.');
   INSERT INTO similarities (title, content)
          VALUES ('Mroonga similar search', 'Mroonga is an open-source storage engine for fast fulltext search with MySQL.');
   INSERT INTO similarities (title, content)
          VALUES ('Rroonga library', 'A library to use Groonga features from Ruby.');

Here is the example of similar search by content itself.

.. code-block:: sql

   SELECT title FROM similarities WHERE MATCH(content) AGAINST ('There are many open-source fulltext search engine.' IN NATURAL LANGUAGE MODE);

Note that you need to specify an content of document in `AGAINST('...' IN NATURAL LANGUAGE MODE)`.

.. code-block:: sql

   SELECT title FROM similarities WHERE MATCH(content) AGAINST ('There are many open-source fulltext search engine.' IN NATURAL LANGUAGE MODE);
   -- +------------------------+
   -- | title                  |
   -- +------------------------+
   -- | Groonga similar search |
   -- | Mroonga similar search |
   -- +------------------------+
   -- 2 rows in set (0.00 sec)

To improve degree of similarity, you may need to use language specific tokenizer or use labeled data such as tag to get rid of some undesirable search results.

For example, if you want to execute similar search against Japanese text, it is recommended to use language specific tokenizer - `TokenMecab`.
Here is the schema definition to use `TokenMecab` tokenizer:

.. code-block:: sql

   CREATE TABLE similarities (
     id INT PRIMARY KEY AUTO_INCREMENT,
     title VARCHAR(32),
     content VARCHAR(255),
     FULLTEXT INDEX (content) COMMENT 'tokenizer "TokenMecab"'
   ) ENGINE = Mroonga DEFAULT CHARSET utf8;

How to run Groonga command
--------------------------

In storage mode, Mroonga stores all your data into Groonga
database. You can access Groonga database by SQL with Mroonga. SQL is
very powerful but it is not good for some operations such as faceted
search.

Faceted search is popular recently. Many online shopping sites such as
amazon.com and ebay.com support faceted search. Faceted search refines
the current search by available search parameters before users refine
their search. And faceted search shows refined searches. Users just
select a refined search. Users benefit from faceted search:

* Users don't need to think about how to refine their search.
  Users just select a showed refined search.
* Users don't get boared "not match" page. Faceted search showes only
  refined searches that has one or more matched items.

Faceted search needs multiple `GROUP BY` operations against searched
result set. To do faceted search by SQL, multiple `SELECT` requests
are needed. It is not effective.

Groonga can do faceted search by only one groonga command. It is
effective. Groonga has the `select` command that can search records
with faceted search. Faceted search is called as `drilldown` in
Groonga. See `Groonga's document
<http://groonga.org/docs/reference/commands/select.html>`_ about
Groonga's `select` command.

Mroonga provides `mroonga_command()` function. You can run groonga
command in SQL by the function. But you should use only `select`
command. Other commands that change schema or data may break
consistency.

Here is the schema definition for execution examples:

.. code-block:: sql

   CREATE TABLE diaries (
     id INT PRIMARY KEY AUTO_INCREMENT,
     content VARCHAR(255),
     date DATE,
     year YEAR,
     `year_month` VARCHAR(9),
     tag VARCHAR(32),
     FULLTEXT INDEX (content)
   ) ENGINE = Mroonga DEFAULT CHARSET utf8;

Here is the sample data for execution examples:

.. code-block:: sql

   INSERT INTO diaries (content, date, year, `year_month`, tag)
          VALUES ('Groonga is an open-source fulltext search engine and column store.',
                  '2013-04-08',
                  '2013',
                  '2013-04',
                  'groonga');
   INSERT INTO diaries (content, date, year, `year_month`, tag)
          VALUES ('Mroonga is an open-source storage engine for fast fulltext search with MySQL.',
                  '2013-04-09',
                  '2013',
                  '2013-04',
                  'MySQL');
   INSERT INTO diaries (content, date, year, `year_month`, tag)
          VALUES ('Tritonn is a patched version of MySQL that supports better fulltext search function with Senna.',
                  '2013-03-29',
                  '2013',
                  '2013-03',
                  'MySQL');

Each record has `groonga` or `MySQL` as `tag`. Each record also has
`year` and `year_month`. You can use `tag`, `year` and `year_month` as
faceted search keys.

Groonga calls faceted search as drilldown. So parameter key in Groonga
is `--drilldown`. Groonga returns search result as JSON. So
`mroonga_command()` also returns search result as JSON. It is not SQL
friendly. You need to parse search result JSON by yourself.

Here is the example of faceted search by all available faceted search
keys (result JSON is pretty printed):

.. code-block:: sql

   SELECT mroonga_command("select diaries --output_columns _id --limit 0 --drilldown tag,year,year_month") AS faceted_result;
   -- +-----------------------------+
   -- | faceted_result              |
   -- +-----------------------------+
   -- | [[[3],                      |
   -- |   [["_id","UInt32"]]],      |
   -- |  [[2],                      |
   -- |   [["_key","ShortText"],    |
   -- |    ["_nsubrecs","Int32"]],  |
   -- |   ["groonga",1],            |
   -- |   ["MySQL",2]],             |
   -- |  [[1],                      |
   -- |   [["_key","Time"],         |
   -- |    ["_nsubrecs","Int32"]],  |
   -- |   [1356998400.0,3]],        |
   -- |  [[2],                      |
   -- |   [["_key","ShortText"],    |
   -- |    ["_nsubrecs","Int32"]],  |
   -- |   ["2013-04",2],            |
   -- |   ["2013-03",1]]]           |
   -- +-----------------------------+
   -- 1 row in set (0.00 sec)

See `Groonga's select command document
<http://groonga.org/docs/reference/commands/select.html>`_ for more
details.

How to search by regular expression
-----------------------------------

In storage mode, you can use a Groonga's functionality from Mroonga as described above.
Thus, you can search records by using a regular expression via Groonga's functionality.

There are some conditions to use regular expression in Mroonga.

* Create an index with ``TokenRegexp`` tokenizer which is used in ``COMMENT``
* Use ``*SS`` pragma and ``@~`` in ``WHERE MATCH ... AGAINST`` clause

Here is the example of search by regular expression.

.. code-block:: sql

  CREATE TABLE paths (
    content text,
    FULLTEXT INDEX content_index (content) COMMENT 'tokenizer "TokenRegexp", normalizer "NormalizerAuto"'
  ) ENGINE=Mroonga DEFAULT CHARSET=utf8mb4;

  INSERT INTO paths VALUES ('/usr/bin/groonga');
  INSERT INTO paths VALUES ('/var/log/auth.log');
  INSERT INTO paths VALUES ('/var/log/messages');
  INSERT INTO paths VALUES ('/tmp/local/var/log/auth.log');

  SELECT * FROM paths WHERE MATCH(content) AGAINST ('*SS content @~ "\\\\A/var/log/auth"' IN BOOLEAN MODE);
  -- +-------------------+
  -- | content           |
  -- +-------------------+
  -- | /var/log/auth.log |
  -- +-------------------+
  -- 1 row in set (0.024 sec)

By using :ref:`boolean-mode-pragma-ss` pragma, you can search the records which matches ``/var/log/auth.log`` with ``content @~ "\\\\A/var/log/auth"``.
``@~`` is a Groonga's operator which executes a regular expression search, so ``content @~ "\\\\A/var/log/auth"`` matches ``/var/log/auth.log`` because it begin with ``/var/log/auth`` (prefix search).

See `Groonga's regular expression document
<http://groonga.org/docs/reference/regular_expression.html#syntax>`_ for more syntax details.

Logging
-------

Mroonga outputs the logs by default.

Log files are located in MySQL's data directory with the filename  ``groonga.log``.

Here is the example of the log. ::

  2010-10-07 17:32:39.209379|n|b1858f80|mroonga 1.10 started.
  2010-10-07 17:32:44.934048|d|46953940|hash get not found (key=test)
  2010-10-07 17:32:44.936113|d|46953940|hash put (key=test)

The default log level is NOTICE, i.e. we have important information only and we don't have debug information etc.).

You can get the log level by ``mroonga_log_level`` system variable, that is a global variable. You can also modify it dynamically by using SET phrase:

.. code-block:: sql

   SHOW VARIABLES LIKE 'mroonga_log_level';
   -- +-------------------+--------+
   -- | Variable_name     | Value  |
   -- +-------------------+--------+
   -- | mroonga_log_level | NOTICE |
   -- +-------------------+--------+
   -- 1 row in set (0.00 sec)

   SET GLOBAL mroonga_log_level=DUMP;
   -- Query OK, 0 rows affected (0.00 sec)

   SHOW VARIABLES LIKE 'mroonga_log_level';
   -- +-------------------+-------+
   -- | Variable_name     | Value |
   -- +-------------------+-------+
   -- | mroonga_log_level | DUMP  |
   -- +-------------------+-------+
   -- 1 row in set (0.00 sec)

Available log levels are the followings.

* NONE
* EMERG
* ALERT
* CRIT
* ERROR
* WARNING
* NOTICE
* INFO
* DEBUG
* DUMP

See :ref:`server-variable-mroonga-log-level` about details.

You can reopen the log file by FLUSH LOGS. If you want to rotate the log file without stopping MySQL server, you can do in the following procedure.

1. change the file name of ``groonga.log`` (by using OS's mv command etc.).
2. invoke "FLUSH LOGS" in MySQL server (by mysql command or mysqladmin command).

Next step
---------

Now, you can use Mroonga as storage mode! If you want Mroonga to be
faster, see also :doc:`/reference/optimizations`.

.. rubric:: Footnotes

.. [#score] `MySQL 5.1 Reference Manual :: 11 Functions and Operations :: 11.7 Full-Text Search Functions <http://dev.mysql.com/doc/refman/5.1/ja/fulltext-search.html>`_
.. [#parser] In Groonga, we call it a 'tokenizer'.
