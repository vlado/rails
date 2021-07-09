*   Deleting an item from the Middleware stack will raise if the item is not found

    Previously, calling `config.middleware.delete(ItemNotInMiddleware)` would fail silently.
    Now it will raise, same as `config.middleware.move(0, ItemNotInMiddleware)` does.

    *Alex Ghiculescu*

*   OpenSSL constants are now used for Digest computations.

    *Dirkjan Bussink*

*   Remove IE6-7-8 file download related hack/fix from ActionController::DataStreaming module

    Due to the age of those versions of IE this fix is no longer relevant, more importantly it creates an edge-case for unexpected Cache-Control headers.

    *Tadas Sasnauskas*

*   Configuration setting to skip logging an uncaught exception backtrace when the exception is
    present in `rescued_responses`.

    It may be too noisy to get all backtraces logged for applications that manage uncaught
    exceptions via `rescued_responses` and `exceptions_app`.
    `config.action_dispatch.log_rescued_responses` (defaults to `true`) can be set to `false` in
    this case, so that only exceptions not found in `rescued_responses` will be logged.

    *Alexander Azarov*, *Mike Dalessio*

*   Ignore file fixtures on `db:fixtures:load`

    *Kevin Sjöberg*

*   Fix ActionController::Live controller test deadlocks by removing the body buffer size limit for tests.

    *Dylan Thacker-Smith*

*   New `ActionController::ConditionalGet#no_store` method to set HTTP cache control `no-store` directive.

    *Tadas Sasnauskas*

*   Drop support for the `SERVER_ADDR` header

    Following up https://github.com/rack/rack/pull/1573 and https://github.com/rails/rails/pull/42349

    *Ricardo Díaz*

*   Set session options when initializing a basic session.

    *Gannon McGibbon*

*   Add `cache_control: {}` option to `fresh_when` and `stale?`

    Works as a shortcut to set `response.cache_control` with the above methods.

    *Jacopo Beschi*

*   Writing into a disabled session will now raise an error.

    Previously when no session store was set, writing into the session would silently fail.

    *Jean Boussier*

*   Add support for 'require-trusted-types-for' and 'trusted-types' headers.

    Fixes #42034

    *lfalcao*

*   Remove inline styles and address basic accessibility issues on rescue templates.

    *Jacob Herrington*

*   Add support for 'private, no-store' Cache-Control headers.

    Previously, 'no-store' was exclusive; no other directives could be specified.

    *Alex Smith*

*   Expand payload of `unpermitted_parameters.action_controller` instrumentation to allow subscribers to
    know which controller action received unpermitted parameters.

    *bbuchalter*

*   Add `ActionController::Live#send_stream` that makes it more convenient to send generated streams:

    ```ruby
    send_stream(filename: "subscribers.csv") do |stream|
      stream.writeln "email_address,updated_at"

      @subscribers.find_each do |subscriber|
        stream.writeln [ subscriber.email_address, subscriber.updated_at ].join(",")
      end
    end
    ```

    *DHH*

*   Add `ActionController::Live::Buffer#writeln` to write a line to the stream with a newline included.

    *DHH*

*   `ActionDispatch::Request#content_type` now returned Content-Type header as it is.

    Previously, `ActionDispatch::Request#content_type` returned value does NOT contain charset part.
    This behavior changed to returned Content-Type header containing charset part as it is.

    If you want just MIME type, please use `ActionDispatch::Request#media_type` instead.

    Before:

    ```ruby
    request = ActionDispatch::Request.new("CONTENT_TYPE" => "text/csv; header=present; charset=utf-16", "REQUEST_METHOD" => "GET")
    request.content_type #=> "text/csv"
    ```

    After:

    ```ruby
    request = ActionDispatch::Request.new("Content-Type" => "text/csv; header=present; charset=utf-16", "REQUEST_METHOD" => "GET")
    request.content_type #=> "text/csv; header=present; charset=utf-16"
    request.media_type   #=> "text/csv"
    ```

    *Rafael Mendonça França*

*   Change `ActionDispatch::Request#media_type` to return `nil` when the request don't have a `Content-Type` header.

    *Rafael Mendonça França*

*   Fix error in `ActionController::LogSubscriber` that would happen when throwing inside a controller action.

    *Janko Marohnić*

*   Allow anything with `#to_str` (like `Addressable::URI`) as a `redirect_to` location

    *ojab*

*   Change the request method to a `GET` when passing failed requests down to `config.exceptions_app`.

    *Alex Robbin*

*   Deprecate the ability to assign a single value to `config.action_dispatch.trusted_proxies`
    as `RemoteIp` middleware behaves inconsistently depending on whether this is configured
    with a single value or an enumerable.

    Fixes #40772

    *Christian Sutter*

*   Add `redirect_back_or_to(fallback_location, **)` as a more aesthetically pleasing version of `redirect_back fallback_location:, **`.
    The old method name is retained without explicit deprecation.

    *DHH*


Please check [6-1-stable](https://github.com/rails/rails/blob/6-1-stable/actionpack/CHANGELOG.md) for previous changes.
