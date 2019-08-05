.. highlightlang:: none

``mroonga_query_expand()``
==========================

.. versionadded:: 7.07

Summary
-------

``mroonga_query_expand()`` UDF can expand the specified term in query to synonyms if you created synonyms table in the advance.

Note that this UDF requires Groonga 7.0.6 or later.

Syntax
------

``mroonga_query_expand()`` has 4 required parameters::

  mroonga_query_expand(table, term_column, expanded_term_column, query)

Usage
-----

Here is the example schema and data. In this example, ``Rroonga`` in query is expanded to "Rroonga OR (Groonga Ruby)"::

  CREATE TABLE synonyms (
    term varchar(255),
    synonym varchar(255),
    INDEX (term)
  ) ENGINE=Mroonga;
  INSERT INTO synonyms VALUES ('Rroonga', 'Rroonga');
  INSERT INTO synonyms VALUES ('Rroonga', 'Groonga Ruby');

Then, execute the following query::

  SELECT mroonga_query_expand('synonyms', 'term', 'synonym', "Rroonga") as query;

It returns the expanded query::

  +-------------------------------+
  | query                         |
  +-------------------------------+
  | ((Rroonga) OR (Groonga Ruby)) |
  +-------------------------------+
  1 row in set (0.001 sec)

Parameters
----------

Required parameters
^^^^^^^^^^^^^^^^^^^

There is four required parameters, ``table``, ``term_column``, ``expanded_term_column`` and ``query``.

``table``
"""""""""

It specifies the synonyms table which have term column and expanded term column.

``term_column``
"""""""""""""""

It specifies the column which stores terms.

``expanded_term_column``
""""""""""""""""""""""""

It specifies the column which stores expanded terms.

``query``
"""""""""

It specifies the query which you want to apply query expansion.

Return value
------------

It returns the query that query expansion is applied.
