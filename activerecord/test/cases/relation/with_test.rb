# frozen_string_literal: true

require "cases/helper"
require "models/comment"
require "models/post"

module ActiveRecord
  class WithTest < ActiveRecord::TestCase
    fixtures :comments
    fixtures :posts

    def test_with_when_hash_is_passed_as_an_argument
      posts_with_comments = Post.where("legacy_comments_count > 0")
      actual = Post.with(posts_with_comments: posts_with_comments).from("posts_with_comments AS posts")
      assert_equal posts_with_comments.to_a, actual
    end

    def test_with_when_arel_node_as_is_passed_as_an_argument
      posts_with_comments = Post.where("legacy_comments_count > 0")
      posts_table = Arel::Table.new(:posts)
      cte_table = Arel::Table.new(:posts_with_comments)
      cte_select = posts_table.project(Arel.star).where(posts_table[:legacy_comments_count].gt(0))
      as = Arel::Nodes::As.new(cte_table, cte_select)
      actual = Post.with(as).from("posts_with_comments AS posts")
      assert_equal posts_with_comments.to_a, actual
    end

    def test_with_when_array_of_arel_node_as_is_passed_as_an_argument
      posts_with_tags_and_comments = Post.where("legacy_comments_count > 0").where("tags_count > 0")

      posts_table = Arel::Table.new(:posts)
      first_cte_table = Arel::Table.new(:posts_with_comments)
      first_cte_select = posts_table.project(Arel.star).where(posts_table[:legacy_comments_count].gt(0))
      first_as = Arel::Nodes::As.new(first_cte_table, first_cte_select)
      second_cte_table = Arel::Table.new(:posts_with_tags_and_comments)
      second_cte_select = first_cte_table.project(Arel.star).where(first_cte_table[:tags_count].gt(0))
      second_as = Arel::Nodes::As.new(second_cte_table, second_cte_select)

      actual = Post.with([first_as, second_as]).from("posts_with_tags_and_comments AS posts")
      assert_equal posts_with_tags_and_comments.to_a, actual
    end

    def test_with_when_hash_with_multiple_elements_of_different_type_is_passed_as_an_argument
      posts_with_tags_and_multiple_comments = Post.where("tags_count > 0").where("legacy_comments_count > 1")
      posts_arel_table = Arel::Table.new(:posts)
      cte_options = {
        posts_with_tags: posts_arel_table.project(Arel.star).where(posts_arel_table[:tags_count].gt(0)),
        posts_with_tags_and_comments: "SELECT * FROM posts_with_tags WHERE legacy_comments_count > 0",
        posts_with_tags_and_multiple_comments: Post.where("legacy_comments_count > 1").from("posts_with_tags_and_comments AS posts")
      }
      actual = Post.with(cte_options).from("posts_with_tags_and_multiple_comments AS posts")
      assert_equal posts_with_tags_and_multiple_comments.to_a, actual
    end

    def test_multiple_with_calls
      posts_with_tags_and_comments = Post.where("tags_count > 0").where("legacy_comments_count > 0")
      actual = Post
        .with(posts_with_tags: Post.where("tags_count > 0"))
        .with(posts_with_tags_and_comments: "SELECT * FROM posts_with_tags WHERE legacy_comments_count > 0")
        .from("posts_with_tags_and_comments AS posts")
      assert_equal posts_with_tags_and_comments.to_a, actual
    end

    def test_multiple_with_randomly_callled
      posts_with_tags_and_comments = Post.where("tags_count > 0").where("legacy_comments_count > 0")
      actual = Post
        .with(posts_with_tags: Post.where("tags_count > 0"))
        .from("posts_with_tags_and_comments AS posts")
        .with(posts_with_tags_and_comments: "SELECT * FROM posts_with_tags WHERE legacy_comments_count > 0")
      assert_equal posts_with_tags_and_comments.to_a, actual
    end

    def test_with_recursive_call
      comment = Comment.last
      first_reply = Comment.create!(body: "First reply", parent: comment, post: comment.post)
      second_reply = Comment.create!(body: "Second reply", parent: comment, post: comment.post)

      union = %{
        SELECT comments.id, comments.parent_id FROM comments WHERE comments.id = #{comment.id}
        UNION
        SELECT comments.id, comments.parent_id FROM comments INNER JOIN replies ON comments.parent_id = replies.id
      }
      thread = Comment.with_recursive(replies: union).from("replies AS comments").order(:created_at)

      assert thread.to_sql.start_with?("WITH RECURSIVE")
      assert_equal [comment.id, first_reply.id, second_reply.id], thread.pluck(:id)
    end

    def test_count_after_with_call
      posts_count = Post.all.count
      posts_with_legacy_comments_count = Post.where("legacy_comments_count > 0").count
      assert posts_count > posts_with_legacy_comments_count

      with_relation = Post.with(posts_with_comments: Post.where("legacy_comments_count > 0"))
      assert_equal posts_count, with_relation.count
      assert_equal posts_with_legacy_comments_count, with_relation.from("posts_with_comments AS posts").count
      assert_equal posts_with_legacy_comments_count, with_relation.joins("JOIN posts_with_comments ON posts_with_comments.id = posts.id").count
    end

    def test_with_when_called_from_active_record_scope
      posts_with_tags = Post.where("tags_count > 0")
      assert_equal posts_with_tags.to_a, Post.with_tags_cte
    end

    def test_with_when_invalid_params_are_passed
      assert_raise(ArgumentError) { Post.with.load }
      assert_raise(ArgumentError) { Post.with([{ posts_with_tags: Post.where("tags_count > 0") }]).load }
    end

    def test_with_when_invalid_hash_values_are_passed
      assert_raise(ArgumentError) { Post.with(posts_with_tags: nil).load }
      assert_raise(ArgumentError) { Post.with(posts_with_tags: [Post.where("tags_count > 0")]).load }
    end
  end
end
