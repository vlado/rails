# frozen_string_literal: true

require "cases/helper"
require "models/bird"
require "byebug"

class BasePreventWritesTest < ActiveRecord::TestCase
  if !in_memory_db?
    test "creating a record raises if preventing writes" do
      ActiveRecord::Base.while_preventing_writes do
        error = assert_raises ActiveRecord::ReadOnlyError do
          Bird.create! name: "Bluejay"
        end

        assert_match %r/\AWrite query attempted while in readonly mode: INSERT /, error.message
      end
    end

    test "updating a record raises if preventing writes" do
      bird = Bird.create! name: "Bluejay"

      ActiveRecord::Base.while_preventing_writes do
        error = assert_raises ActiveRecord::ReadOnlyError do
          bird.update! name: "Robin"
        end

        assert_match %r/\AWrite query attempted while in readonly mode: UPDATE /, error.message
      end
    end

    test "deleting a record raises if preventing writes" do
      bird = Bird.create! name: "Bluejay"

      ActiveRecord::Base.while_preventing_writes do
        error = assert_raises ActiveRecord::ReadOnlyError do
          bird.destroy!
        end

        assert_match %r/\AWrite query attempted while in readonly mode: DELETE /, error.message
      end
    end

    test "selecting a record does not raise if preventing writes" do
      bird = Bird.create! name: "Bluejay"

      ActiveRecord::Base.while_preventing_writes do
        assert_equal bird, Bird.where(name: "Bluejay").last
      end
    end

    test "an explain query does not raise if preventing writes" do
      Bird.create!(name: "Bluejay")

      ActiveRecord::Base.while_preventing_writes do
        assert_queries(2) { Bird.where(name: "Bluejay").explain }
      end
    end

    test "an empty transaction does not raise if preventing writes" do
      ActiveRecord::Base.while_preventing_writes do
        assert_queries(2, ignore_none: true) do
          Bird.transaction do
            ActiveRecord::Base.connection.materialize_transactions
          end
        end
      end
    end

    test "preventing writes applies to all connections in block" do
      ActiveRecord::Base.while_preventing_writes do
        conn1_error = assert_raises ActiveRecord::ReadOnlyError do
          assert_equal ActiveRecord::Base.connection, Bird.connection
          assert_not_equal ARUnit2Model.connection, Bird.connection
          Bird.create!(name: "Bluejay")
        end

        assert_match %r/\AWrite query attempted while in readonly mode: INSERT /, conn1_error.message
      end

      ActiveRecord::Base.while_preventing_writes do
        conn2_error = assert_raises ActiveRecord::ReadOnlyError do
          assert_not_equal ActiveRecord::Base.connection, Professor.connection
          assert_equal ARUnit2Model.connection, Professor.connection
          Professor.create!(name: "Professor Bluejay")
        end

        assert_match %r/\AWrite query attempted while in readonly mode: INSERT /, conn2_error.message
      end
    end

    test "current_preventing_writes" do
      ActiveRecord::Base.while_preventing_writes do
        assert ActiveRecord::Base.current_preventing_writes, "expected connection current_preventing_writes to return true"
      end
    end
  end

  class BasePreventWritesLegacyTest < ActiveRecord::TestCase
    def setup
      @old_value = ActiveRecord.legacy_connection_handling
      ActiveRecord.legacy_connection_handling = true
      ActiveRecord::Base.establish_connection :arunit
      ARUnit2Model.establish_connection :arunit2
    end

    def teardown
      clean_up_legacy_connection_handlers
      ActiveRecord.legacy_connection_handling = @old_value
    end

    if !in_memory_db?
      test "creating a record raises if preventing writes" do
        ActiveRecord::Base.connection_handler.while_preventing_writes do
          error = assert_raises ActiveRecord::ReadOnlyError do
            Bird.create! name: "Bluejay"
          end

          assert_match %r/\AWrite query attempted while in readonly mode: INSERT /, error.message
        end
      end

      test "updating a record raises if preventing writes" do
        bird = Bird.create! name: "Bluejay"

        ActiveRecord::Base.connection_handler.while_preventing_writes do
          error = assert_raises ActiveRecord::ReadOnlyError do
            bird.update! name: "Robin"
          end

          assert_match %r/\AWrite query attempted while in readonly mode: UPDATE /, error.message
        end
      end

      test "deleting a record raises if preventing writes" do
        bird = Bird.create! name: "Bluejay"

        ActiveRecord::Base.connection_handler.while_preventing_writes do
          error = assert_raises ActiveRecord::ReadOnlyError do
            bird.destroy!
          end

          assert_match %r/\AWrite query attempted while in readonly mode: DELETE /, error.message
        end
      end

      test "selecting a record does not raise if preventing writes" do
        bird = Bird.create! name: "Bluejay"

        ActiveRecord::Base.connection_handler.while_preventing_writes do
          assert_equal bird, Bird.where(name: "Bluejay").last
        end
      end

      test "an explain query does not raise if preventing writes" do
        Bird.create!(name: "Bluejay")

        ActiveRecord::Base.connection_handler.while_preventing_writes do
          assert_queries(2) { Bird.where(name: "Bluejay").explain }
        end
      end

      test "an empty transaction does not raise if preventing writes" do
        ActiveRecord::Base.connection_handler.while_preventing_writes do
          assert_queries(2, ignore_none: true) do
            Bird.transaction do
              ActiveRecord::Base.connection.materialize_transactions
            end
          end
        end
      end

      test "preventing writes applies to all connections on a handler" do
        ActiveRecord::Base.connection_handler.while_preventing_writes do
          conn1_error = assert_raises ActiveRecord::ReadOnlyError do
            assert_equal ActiveRecord::Base.connection, Bird.connection
            assert_not_equal ARUnit2Model.connection, Bird.connection
            Bird.create!(name: "Bluejay")
          end

          assert_match %r/\AWrite query attempted while in readonly mode: INSERT /, conn1_error.message
        end

        ActiveRecord::Base.connection_handler.while_preventing_writes do
          conn2_error = assert_raises ActiveRecord::ReadOnlyError do
            assert_not_equal ActiveRecord::Base.connection, Professor.connection
            assert_equal ARUnit2Model.connection, Professor.connection
            Professor.create!(name: "Professor Bluejay")
          end

          assert_match %r/\AWrite query attempted while in readonly mode: INSERT /, conn2_error.message
        end
      end

      test "preventing writes with multiple handlers" do
        ActiveRecord::Base.connects_to(database: { writing: :arunit, reading: :arunit })

        ActiveRecord::Base.connected_to(role: :writing) do
          conn1_error = assert_raises ActiveRecord::ReadOnlyError do
            assert_equal :writing, ActiveRecord::Base.current_role

            ActiveRecord::Base.connection_handler.while_preventing_writes do
              Bird.create!(name: "Bluejay")
            end
          end

          assert_match %r/\AWrite query attempted while in readonly mode: INSERT /, conn1_error.message
        end

        ActiveRecord::Base.connected_to(role: :reading) do
          conn2_error = assert_raises ActiveRecord::ReadOnlyError do
            assert_equal :reading, ActiveRecord::Base.current_role

            ActiveRecord::Base.connection_handler.while_preventing_writes do
              Bird.create!(name: "Bluejay")
            end
          end

          assert_match %r/\AWrite query attempted while in readonly mode: INSERT /, conn2_error.message
        end
      end

      test "current_preventing_writes" do
        ActiveRecord::Base.connection_handler.while_preventing_writes do
          assert ActiveRecord::Base.current_preventing_writes, "expected connection current_preventing_writes to return true"
        end
      end
    end
  end
end
