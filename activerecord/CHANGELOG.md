*   `.with` and `.with_recursive` query methods added. Construct common table
     expressions with ease and get `ActiveRecord::Relation` back.

    Before:

    ```ruby
    posts_with_comments_table = Arel::Table.new(:posts_with_comments)
    posts_with_comments_expression = Post.where("comments_count > ?", 0).arel
    Post.all.arel.with(Arel::Nodes::As.new(posts_with_comments_table, posts_with_comments_expression))
    # => Arel::SelectManager

    non_recursive_relation = Comment.select(:id, :parent_id).where(parent: nil)
    recursive_relation = Comment.select(:id, :parent_id).joins("JOIN replies ON comments.parent_id = replies.id")
    replies_table = Arel::Table.new(:replies)
    union = non_recursive_relation.arel.union(recursive_relation.arel)
    Post.all.arel.with(:recursive, Arel::Nodes::As.new(replies_table, union))
    # => Arel::SelectManager
    ```

    After:

    ```ruby
    Post.with(:posts_with_comments, Post.where("comments_count > ?", 0))
    # => ActiveRecord::Relation

    non_recursive_relation = Comment.select(:id, :parent_id).where(parent: nil)
    recursive_relation = Comment.select(:id, :parent_id).joins("JOIN replies ON comments.parent_id = replies.id")
    Post.with_recursive(:replies, non_recursive_relation, recursive_relation)
    # => ActiveRecord::Relation
    ```

    *Vlado Cingel*

*   Support passing record to uniqueness validator `:conditions` callable:

*   Clear cached `has_one` association after setting `belongs_to` association to `nil`.

    After setting a `belongs_to` relation to `nil` and updating an unrelated attribute on the owner,
    the owner should still return `nil` on the `has_one` relation.

    Fixes #42597.

    *Michiel de Mare*

*   OpenSSL constants are now used for Digest computations.

    *Dirkjan Bussink*

*   Relation#destroy_all perform its work in batches

    Since destroy_all actually loads the entire relation and then iteratively destroys the records one by one,
    you can blow your memory gasket very easily. So let's do the right thing by default
    and do this work in batches of 100 by default and allow you to specify
    the batch size like so: #destroy_all(batch_size: 100).

    Apps upgrading to 7.0 will get a deprecation warning. As of Rails 7.1, destroy_all will no longer
    return the collection of records that were destroyed.

    To transition to the new behaviour set the following in an initializer:

    ```ruby
    config.active_record.destroy_all_in_batches = true
    ```

    *Genadi Samokovarov*, *Roberto Miranda*

*   Adds support for `if_not_exists` to `add_foreign_key` and `if_exists` to `remove_foreign_key`.

    Applications can set their migrations to ignore exceptions raised when adding a foreign key
    that already exists or when removing a foreign key that does not exist.

    Example Usage:

    ```ruby
    class AddAuthorsForeignKeyToArticles < ActiveRecord::Migration[7.0]
      def change
        add_foreign_key :articles, :authors, if_not_exists: true
      end
    end
    ```

    ```ruby
    class RemoveAuthorsForeignKeyFromArticles < ActiveRecord::Migration[7.0]
      def change
        remove_foreign_key :articles, :authors, if_exists: true
      end
    end
    ```

    *Roberto Miranda*

*   Prevent polluting ENV during postgresql structure dump/load

    Some configuration parameters were provided to pg_dump / psql via
    environment variables which persisted beyond the command being run, and may
    have caused subsequent commands and connections to fail. Tasks running
    across multiple postgresql databases like `rails db:test:prepare` may have
    been affected.

    *Samuel Cochran*

*   Set precision 6 by default for `datetime` columns

    By default, datetime columns will have microseconds precision instead of seconds precision.

    *Roberto Miranda*

*   Allow preloading of associations with instance dependent scopes

    *John Hawthorn*, *John Crepezzi*, *Adam Hess*, *Eileen M. Uchitelle*, *Dinah Shi*

*   Do not try to rollback transactions that failed due to a `ActiveRecord::TransactionRollbackError`.

    *Jamie McCarthy*

*   Active Record Encryption will now encode values as UTF-8 when using deterministic
    encryption. The encoding is part of the encrypted payload, so different encodings for
    different values result in different ciphertexts. This can break unique constraints and
    queries.

    The new behavior is configurable via `active_record.encryption.forced_encoding_for_deterministic_encryption`
    that is `Encoding::UTF_8` by default. It can be disabled by setting it to `nil`.

    *Jorge Manrubia*

*   The MySQL adapter now cast numbers and booleans bind parameters to to string for safety reasons.

    When comparing a string and a number in a query, MySQL convert the string to a number. So for
    instance `"foo" = 0`, will implicitly cast `"foo"` to `0` and will evaluate to `TRUE` which can
    lead to security vulnerabilities.

    Active Record already protect against that vulnerability when it knows the type of the column
    being compared, however until now it was still vulnerable when using bind parameters:

    ```ruby
    User.where("login_token = ?", 0).first
    ```

    Would perform:

    ```sql
    SELECT * FROM `users` WHERE `login_token` = 0 LIMIT 1;
    ```

    Now it will perform:

    ```sql
    SELECT * FROM `users` WHERE `login_token` = '0' LIMIT 1;
    ```

    *Jean Boussier*

*   Fixture configurations (`_fixture`) are now strictly validated.

    If an error will be raised if that entry contains unknown keys while previously it
    would silently have no effects.

    *Jean Boussier*

*   Add `ActiveRecord::Base.update!` that works like `ActiveRecord::Base.update` but raises exceptions.

    This allows for the same behavior as the instance method `#update!` at a class level.

    ```ruby
    Person.update!(:all, state: "confirmed")
    ```

    *Dorian Marié*

*   Add `ActiveRecord::Base#attributes_for_database`

    Returns attributes with values for assignment to the database.

    *Chris Salzberg*

*   Use an empty query to check if the PostgreSQL connection is still active

    An empty query is faster than `SELECT 1`.

    *Heinrich Lee Yu*

*   Add `ActiveRecord::Base#previously_persisted?`

    Returns `true` if the object has been previously persisted but now it has been deleted.

*   Deprecate `partial_writes` in favor of `partial_inserts` and `partial_updates`.

    This allows to have a different behavior on update and create.

    *Jean Boussier*

*   Fix compatibility with `psych >= 4`.

    Starting in Psych 4.0.0 `YAML.load` behaves like `YAML.safe_load`. To preserve compatibility
    Active Record's schema cache loader and `YAMLColumn` now uses `YAML.unsafe_load` if available.

    *Jean Boussier*

*   `ActiveRecord::Base.logger` is now a `class_attribute`.

    This means it can no longer be accessed directly through `@@logger`, and that setting `logger =`
    on a subclass won't change the parent's logger.

    *Jean Boussier*

*   Add `.asc.nulls_first` for all databases. Unfortunately MySQL still doesn't like `nulls_last`.

    *Keenan Brock*

*   Improve performance of `one?` and `many?` by limiting the generated count query to 2 results.

    *Gonzalo Riestra*

*   Don't check type when using `if_not_exists` on `add_column`.

    Previously, if a migration called `add_column` with the `if_not_exists` option set to true
    the `column_exists?` check would look for a column with the same name and type as the migration.

    Recently it was discovered that the type passed to the migration is not always the same type
    as the column after migration. For example a column set to `:mediumblob` in the migration will
    be casted to `binary` when calling `column.type`. Since there is no straightforward way to cast
    the type to the database type without running the migration, we opted to drop the type check from
    `add_column`. This means that migrations adding a duplicate column with a different type will no
    longer raise an error.

    *Eileen M. Uchitelle*

*   Log a warning message when running SQLite in production

    Using SQLite in production ENV is generally discouraged. SQLite is also the default adapter
    in a new Rails application.
    For the above reasons log a warning message when running SQLite in production.

    The warning can be disabled by setting `config.active_record.sqlite3_production_warning=false`.

    *Jacopo Beschi*

*   Add option to disable joins for `has_one` associations.

    In a multiple database application, associations can't join across
    databases. When set, this option instructs Rails to generate 2 or
    more queries rather than generating joins for `has_one` associations.

    Set the option on a has one through association:

    ```ruby
    class Person
      belongs_to :dog
      has_one :veterinarian, through: :dog, disable_joins: true
    end
    ```

    Then instead of generating join SQL, two queries are used for `@person.veterinarian`:

    ```
    SELECT "dogs"."id" FROM "dogs" WHERE "dogs"."person_id" = ?  [["person_id", 1]]
    SELECT "veterinarians".* FROM "veterinarians" WHERE "veterinarians"."dog_id" = ?  [["dog_id", 1]]
    ```

    *Sarah Vessels*, *Eileen M. Uchitelle*

*   `Arel::Visitors::Dot` now renders a complete set of properties when visiting
    `Arel::Nodes::SelectCore`, `SelectStatement`, `InsertStatement`, `UpdateStatement`, and
    `DeleteStatement`, which fixes #42026. Previously, some properties were omitted.

    *Mike Dalessio*

*   `Arel::Visitors::Dot` now supports `Arel::Nodes::Bin`, `Case`, `CurrentRow`, `Distinct`,
    `DistinctOn`, `Else`, `Except`, `InfixOperation`, `Intersect`, `Lock`, `NotRegexp`, `Quoted`,
    `Regexp`, `UnaryOperation`, `Union`, `UnionAll`, `When`, and `With`. Previously, these node
    types caused an exception to be raised by `Arel::Visitors::Dot#accept`.

    *Mike Dalessio*

*   Optimize `remove_columns` to use a single SQL statement.

    ```ruby
    remove_columns :my_table, :col_one, :col_two
    ```

    Now results in the following SQL:

    ```sql
    ALTER TABLE "my_table" DROP COLUMN "col_one", DROP COLUMN "col_two"
    ```

    *Jon Dufresne*

*   Ensure `has_one` autosave association callbacks get called once.

    Change the `has_one` autosave callback to be non cyclic as well.
    By doing this the autosave callback are made more consistent for
    all 3 cases: `has_many`, `has_one`, and `belongs_to`.

    *Petrik de Heus*

*   Add option to disable joins for associations.

    In a multiple database application, associations can't join across
    databases. When set, this option instructs Rails to generate 2 or
    more queries rather than generating joins for associations.

    Set the option on a has many through association:

    ```ruby
    class Dog
      has_many :treats, through: :humans, disable_joins: true
      has_many :humans
    end
    ```

    Then instead of generating join SQL, two queries are used for `@dog.treats`:

    ```
    SELECT "humans"."id" FROM "humans" WHERE "humans"."dog_id" = ?  [["dog_id", 1]]
    SELECT "treats".* FROM "treats" WHERE "treats"."human_id" IN (?, ?, ?)  [["human_id", 1], ["human_id", 2], ["human_id", 3]]
    ```

    *Eileen M. Uchitelle*, *Aaron Patterson*, *Lee Quarella*

*   Add setting for enumerating column names in SELECT statements.

    Adding a column to a PostgreSQL database, for example, while the application is running can
    change the result of wildcard `SELECT *` queries, which invalidates the result
    of cached prepared statements and raises a `PreparedStatementCacheExpired` error.

    When enabled, Active Record will avoid wildcards and always include column names
    in `SELECT` queries, which will return consistent results and avoid prepared
    statement errors.

    Before:

    ```ruby
    Book.limit(5)
    # SELECT * FROM books LIMIT 5
    ```

    After:

    ```ruby
    # config/application.rb
    module MyApp
      class Application < Rails::Application
        config.active_record.enumerate_columns_in_select_statements = true
      end
    end

    # or, configure per-model
    class Book < ApplicationRecord
      self.enumerate_columns_in_select_statements = true
    end
    ```

    ```ruby
    Book.limit(5)
    # SELECT id, author_id, name, format, status, language, etc FROM books LIMIT 5
    ```

    *Matt Duszynski*

*   Allow passing SQL as `on_duplicate` value to `#upsert_all` to make it possible to use raw SQL to update columns on conflict:

    ```ruby
    Book.upsert_all(
      [{ id: 1, status: 1 }, { id: 2, status: 1 }],
      on_duplicate: Arel.sql("status = GREATEST(books.status, EXCLUDED.status)")
    )
    ```

    *Vladimir Dementyev*

*   Allow passing SQL as `returning` statement to `#upsert_all`:

    ```ruby
    Article.insert_all(
    [
        { title: "Article 1", slug: "article-1", published: false },
        { title: "Article 2", slug: "article-2", published: false }
      ],
      returning: Arel.sql("id, (xmax = '0') as inserted, name as new_name")
    )
    ```

    *Vladimir Dementyev*

*   Deprecate `legacy_connection_handling`.

    *Eileen M. Uchitelle*

*   Add attribute encryption support.

    Encrypted attributes are declared at the model level. These
    are regular Active Record attributes backed by a column with
    the same name. The system will transparently encrypt these
    attributes before saving them into the database and will
    decrypt them when retrieving their values.


    ```ruby
    class Person < ApplicationRecord
      encrypts :name
      encrypts :email_address, deterministic: true
    end
    ```

    You can learn more in the [Active Record Encryption
    guide](https://edgeguides.rubyonrails.org/active_record_encryption.html).

    *Jorge Manrubia*

*   Changed Arel predications `contains` and `overlaps` to use
    `quoted_node` so that PostgreSQL arrays are quoted properly.

    *Bradley Priest*

*   Add mode argument to record level `strict_loading!`

    This argument can be used when enabling strict loading for a single record
    to specify that we only want to raise on n plus one queries.

    ```ruby
    developer.strict_loading!(mode: :n_plus_one_only)

    developer.projects.to_a # Does not raise
    developer.projects.first.client # Raises StrictLoadingViolationError
    ```

    Previously, enabling strict loading would cause any lazily loaded
    association to raise an error. Using `n_plus_one_only` mode allows us to
    lazily load belongs_to, has_many, and other associations that are fetched
    through a single query.

    *Dinah Shi*

*   Fix Float::INFINITY assignment to datetime column with postgresql adapter

    Before:

    ```ruby
    # With this config
    ActiveRecord::Base.time_zone_aware_attributes = true

    # and the following schema:
    create_table "postgresql_infinities" do |t|
      t.datetime "datetime"
    end

    # This test fails
    record = PostgresqlInfinity.create!(datetime: Float::INFINITY)
    assert_equal Float::INFINITY, record.datetime # record.datetime gets nil
    ```

    After this commit, `record.datetime` gets `Float::INFINITY` as expected.

    *Shunichi Ikegami*

*   Type cast enum values by the original attribute type.

    The notable thing about this change is that unknown labels will no longer match 0 on MySQL.

    ```ruby
    class Book < ActiveRecord::Base
      enum :status, { proposed: 0, written: 1, published: 2 }
    end
    ```

    Before:

    ```ruby
    # SELECT `books`.* FROM `books` WHERE `books`.`status` = 'prohibited' LIMIT 1
    Book.find_by(status: :prohibited)
    # => #<Book id: 1, status: "proposed", ...> (for mysql2 adapter)
    # => ActiveRecord::StatementInvalid: PG::InvalidTextRepresentation: ERROR:  invalid input syntax for type integer: "prohibited" (for postgresql adapter)
    # => nil (for sqlite3 adapter)
    ```

    After:

    ```ruby
    # SELECT `books`.* FROM `books` WHERE `books`.`status` IS NULL LIMIT 1
    Book.find_by(status: :prohibited)
    # => nil (for all adapters)
    ```

    *Ryuta Kamizono*

*   Fixtures for `has_many :through` associations now load timestamps on join tables

    Given this fixture:

    ```yml
    ### monkeys.yml
    george:
      name: George the Monkey
      fruits: apple

    ### fruits.yml
    apple:
      name: apple
    ```

    If the join table (`fruit_monkeys`) contains `created_at` or `updated_at` columns,
    these will now be populated when loading the fixture. Previously, fixture loading
    would crash if these columns were required, and leave them as null otherwise.

    *Alex Ghiculescu*

*   Allow applications to configure the thread pool for async queries

    Some applications may want one thread pool per database whereas others want to use
    a single global thread pool for all queries. By default, Rails will set `async_query_executor`
    to `nil` which will not initialize any executor. If `load_async` is called and no executor
    has been configured, the query will be executed in the foreground.

    To create one thread pool for all database connections to use applications can set
    `config.active_record.async_query_executor` to `:global_thread_pool` and optionally define
    `config.active_record.global_executor_concurrency`. This defaults to 4. For applications that want
    to have a thread pool for each database connection, `config.active_record.async_query_executor` can
    be set to `:multi_thread_pool`. The configuration for each thread pool is set in the database
    configuration.

    *Eileen M. Uchitelle*

*   Allow new syntax for `enum` to avoid leading `_` from reserved options.

    Before:

    ```ruby
    class Book < ActiveRecord::Base
      enum status: [ :proposed, :written ], _prefix: true, _scopes: false
      enum cover: [ :hard, :soft ], _suffix: true, _default: :hard
    end
    ```

    After:

    ```ruby
    class Book < ActiveRecord::Base
      enum :status, [ :proposed, :written ], prefix: true, scopes: false
      enum :cover, [ :hard, :soft ], suffix: true, default: :hard
    end
    ```

    *Ryuta Kamizono*

*   Add `ActiveRecord::Relation#load_async`.

    This method schedules the query to be performed asynchronously from a thread pool.

    If the result is accessed before a background thread had the opportunity to perform
    the query, it will be performed in the foreground.

    This is useful for queries that can be performed long enough before their result will be
    needed, or for controllers which need to perform several independent queries.

    ```ruby
    def index
      @categories = Category.some_complex_scope.load_async
      @posts = Post.some_complex_scope.load_async
    end
    ```

    Active Record logs will also include timing info for the duration of how long
    the main thread had to wait to access the result. This timing is useful to know
    whether or not it's worth to load the query asynchronously.

    ```
    DEBUG -- :   Category Load (62.1ms)  SELECT * FROM `categories` LIMIT 50
    DEBUG -- :   ASYNC Post Load (64ms) (db time 126.1ms)  SELECT * FROM `posts` LIMIT 100
    ```

    The duration in the first set of parens is how long the main thread was blocked
    waiting for the results, and the second set of parens with "db time" is how long
    the entire query took to execute.

    *Jean Boussier*

*   Implemented `ActiveRecord::Relation#excluding` method.

    This method excludes the specified record (or collection of records) from
    the resulting relation:

    ```ruby
    Post.excluding(post)
    Post.excluding(post_one, post_two)
    ```

    Also works on associations:

    ```ruby
    post.comments.excluding(comment)
    post.comments.excluding(comment_one, comment_two)
    ```

    This is short-hand for `Post.where.not(id: post.id)` (for a single record)
    and `Post.where.not(id: [post_one.id, post_two.id])` (for a collection).

    *Glen Crawford*

*   Skip optimised #exist? query when #include? is called on a relation
    with a having clause

    Relations that have aliased select values AND a having clause that
    references an aliased select value would generate an error when
    #include? was called, due to an optimisation that would generate
    call #exists? on the relation instead, which effectively alters
    the select values of the query (and thus removes the aliased select
    values), but leaves the having clause intact. Because the having
    clause is then referencing an aliased column that is no longer
    present in the simplified query, an ActiveRecord::InvalidStatement
    error was raised.

    A sample query affected by this problem:

    ```ruby
    Author.select('COUNT(*) as total_posts', 'authors.*')
          .joins(:posts)
          .group(:id)
          .having('total_posts > 2')
          .include?(Author.first)
    ```

    This change adds an addition check to the condition that skips the
    simplified #exists? query, which simply checks for the presence of
    a having clause.

    Fixes #41417

    *Michael Smart*

*   Increment postgres prepared statement counter before making a prepared statement, so if the statement is aborted
    without Rails knowledge (e.g., if app gets killed during long-running query or due to Rack::Timeout), app won't end
    up in perpetual crash state for being inconsistent with Postgres.

    *wbharding*, *Martin Tepper*

*   Add ability to apply `scoping` to `all_queries`.

    Some applications may want to use the `scoping` method but previously it only
    worked on certain types of queries. This change allows the `scoping` method to apply
    to all queries for a model in a block.

    ```ruby
    Post.where(blog_id: post.blog_id).scoping(all_queries: true) do
      post.update(title: "a post title") # adds `posts.blog_id = 1` to the query
    end
    ```

    *Eileen M. Uchitelle*

*   `ActiveRecord::Calculations.calculate` called with `:average`
    (aliased as `ActiveRecord::Calculations.average`) will now use column-based
    type casting. This means that floating-point number columns will now be
    aggregated as `Float` and decimal columns will be aggregated as `BigDecimal`.

    Integers are handled as a special case returning `BigDecimal` always
    (this was the case before already).

    ```ruby
    # With the following schema:
    create_table "measurements" do |t|
      t.float "temperature"
    end

    # Before:
    Measurement.average(:temperature).class
    # => BigDecimal

    # After:
    Measurement.average(:temperature).class
    # => Float
    ```

    Before this change, Rails just called `to_d` on average aggregates from the
    database adapter. This is not the case anymore. If you relied on that kind
    of magic, you now need to register your own `ActiveRecord::Type`
    (see `ActiveRecord::Attributes::ClassMethods` for documentation).

    *Josua Schmid*

*   PostgreSQL: introduce `ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type`

    This setting controls what native type Active Record should use when you call `datetime` in
    a migration or schema. It takes a symbol which must correspond to one of the configured
    `NATIVE_DATABASE_TYPES`. The default is `:timestamp`, meaning `t.datetime` in a migration
    will create a "timestamp without time zone" column. To use "timestamp with time zone",
    change this to `:timestamptz` in an initializer.

    You should run `bin/rails db:migrate` to rebuild your schema.rb if you change this.

    *Alex Ghiculescu*

*   PostgreSQL: handle `timestamp with time zone` columns correctly in `schema.rb`.

    Previously they dumped as `t.datetime :column_name`, now they dump as `t.timestamptz :column_name`,
    and are created as `timestamptz` columns when the schema is loaded.

    *Alex Ghiculescu*

*   Removing trailing whitespace when matching columns in
    `ActiveRecord::Sanitization.disallow_raw_sql!`.

    *Gannon McGibbon*, *Adrian Hirt*

*   Expose a way for applications to set a `primary_abstract_class`

    Multiple database applications that use a primary abstract class that is not
    named `ApplicationRecord` can now set a specific class to be the `primary_abstract_class`.

    ```ruby
    class PrimaryApplicationRecord
      self.primary_abstract_class
    end
    ```

    When an application boots it automatically connects to the primary or first database in the
    database configuration file. In a multiple database application that then call `connects_to`
    needs to know that the default connection is the same as the `ApplicationRecord` connection.
    However, some applications have a differently named `ApplicationRecord`. This prevents Active
    Record from opening duplicate connections to the same database.

    *Eileen M. Uchitelle*, *John Crepezzi*

*   Support hash config for `structure_dump_flags` and `structure_load_flags` flags
    Now that Active Record supports multiple databases configuration
    we need a way to pass specific flags for dump/load databases since
    the options are not the same for different adapters.
    We can use in the original way:

    ```ruby
    ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = ['--no-defaults', '--skip-add-drop-table']
    #or
    ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = '--no-defaults --skip-add-drop-table'
    ```

    And also use it passing a hash, with one or more keys, where the key
    is the adapter

    ```ruby
    ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = {
      mysql2: ['--no-defaults', '--skip-add-drop-table'],
      postgres: '--no-tablespaces'
    }
    ```

    *Gustavo Gonzalez*

*   Connection specification now passes the "url" key as a configuration for the
    adapter if the "url" protocol is "jdbc", "http", or "https". Previously only
    urls with the "jdbc" prefix were passed to the Active Record Adapter, others
    are assumed to be adapter specification urls.

    Fixes #41137.

    *Jonathan Bracy*

*   Allow to opt-out of `strict_loading` mode on a per-record base.

    This is useful when strict loading is enabled application wide or on a
    model level.

    ```ruby
    class User < ApplicationRecord
      has_many :bookmarks
      has_many :articles, strict_loading: true
    end

    user = User.first
    user.articles                        # => ActiveRecord::StrictLoadingViolationError
    user.bookmarks                       # => #<ActiveRecord::Associations::CollectionProxy>

    user.strict_loading!(true)           # => true
    user.bookmarks                       # => ActiveRecord::StrictLoadingViolationError

    user.strict_loading!(false)          # => false
    user.bookmarks                       # => #<ActiveRecord::Associations::CollectionProxy>
    user.articles.strict_loading!(false) # => #<ActiveRecord::Associations::CollectionProxy>
    ```

    *Ayrton De Craene*

*   Add `FinderMethods#sole` and `#find_sole_by` to find and assert the
    presence of exactly one record.

    Used when you need a single row, but also want to assert that there aren't
    multiple rows matching the condition; especially for when database
    constraints aren't enough or are impractical.

    ```ruby
    Product.where(["price = %?", price]).sole
    # => ActiveRecord::RecordNotFound      (if no Product with given price)
    # => #<Product ...>                    (if one Product with given price)
    # => ActiveRecord::SoleRecordExceeded  (if more than one Product with given price)

    user.api_keys.find_sole_by(key: key)
    # as above
    ```

    *Asherah Connor*

*   Makes `ActiveRecord::AttributeMethods::Query` respect the getter overrides defined in the model.

    Before:

    ```ruby
    class User
      def admin
        false # Overriding the getter to always return false
      end
    end

    user = User.first
    user.update(admin: true)

    user.admin # false (as expected, due to the getter overwrite)
    user.admin? # true (not expected, returned the DB column value)
    ```

    After this commit, `user.admin?` above returns false, as expected.

    Fixes #40771.

    *Felipe*

*   Allow delegated_type to be specified primary_key and foreign_key.

    Since delegated_type assumes that the foreign_key ends with `_id`,
    `singular_id` defined by it does not work when the foreign_key does
    not end with `id`. This change fixes it by taking into account
    `primary_key` and `foreign_key` in the options.

    *Ryota Egusa*

*   Expose an `invert_where` method that will invert all scope conditions.

    ```ruby
    class User
      scope :active, -> { where(accepted: true, locked: false) }
    end

    User.active
    # ... WHERE `accepted` = 1 AND `locked` = 0

    User.active.invert_where
    # ... WHERE NOT (`accepted` = 1 AND `locked` = 0)
    ```

    *Kevin Deisz*

*   Restore possibility of passing `false` to :polymorphic option of `belongs_to`.

    Previously, passing `false` would trigger the option validation logic
    to throw an error saying :polymorphic would not be a valid option.

    *glaszig*

*   Remove deprecated `database` kwarg from `connected_to`.

    *Eileen M. Uchitelle*, *John Crepezzi*

*   Allow adding nonnamed expression indexes to be revertible.

    Fixes #40732.

    Previously, the following code would raise an error, when executed while rolling back,
    and the index name should be specified explicitly. Now, the index name is inferred
    automatically.
    ```ruby
    add_index(:items, "to_tsvector('english', description)")
    ```

    *fatkodima*

*   Only warn about negative enums if a positive form that would cause conflicts exists.

    Fixes #39065.

    *Alex Ghiculescu*

*   Add option to run `default_scope` on all queries.

    Previously, a `default_scope` would only run on select or insert queries. In some cases, like non-Rails tenant sharding solutions, it may be desirable to run `default_scope` on all queries in order to ensure queries are including a foreign key for the shard (i.e. `blog_id`).

    Now applications can add an option to run on all queries including select, insert, delete, and update by adding an `all_queries` option to the default scope definition.

    ```ruby
    class Article < ApplicationRecord
      default_scope -> { where(blog_id: Current.blog.id) }, all_queries: true
    end
    ```

    *Eileen M. Uchitelle*

*   Add `where.associated` to check for the presence of an association.

    ```ruby
    # Before:
    account.users.joins(:contact).where.not(contact_id: nil)

    # After:
    account.users.where.associated(:contact)
    ```

    Also mirrors `where.missing`.

    *Kasper Timm Hansen*

*   Allow constructors (`build_association` and `create_association`) on
    `has_one :through` associations.

    *Santiago Perez Perret*


Please check [6-1-stable](https://github.com/rails/rails/blob/6-1-stable/activerecord/CHANGELOG.md) for previous changes.
