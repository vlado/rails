*   Fix `config_for` error when there's only a shared root array.

    *Loïc Delmaire*

*   Raise an error in generators if an index type is invalid.

    *Petrik de Heus*

*   `package.json` now uses a strict version constraint for Rails JavaScript packages on new Rails apps.

    *Zachary Scott*, *Alex Ghiculescu*

*   Modified scaffold generator template so that running
    `rails g scaffold Author` no longer generates tests called "creating
    a Author", "updating a Author", and "destroying a Author"

    Fixes #40744.

    *Michael Duchemin*

*   Raise an error in generators if a field type is invalid.

    *Petrik de Heus*

*   `bin/rails tmp:clear` deletes also files and directories in `tmp/storage`.

    *George Claghorn*

*   Fix compatibility with `psych >= 4`.

    Starting in Psych 4.0.0 `YAML.load` behaves like `YAML.safe_load`. To preserve compatibility
    `Rails.application.config_for` now uses `YAML.unsafe_load` if available.

    *Jean Boussier*

*   Allow loading nested locales in engines.

    *Gannon McGibbon*

*   Ensure `Rails.application.config_for` always cast hashes to `ActiveSupport::OrderedOptions`.

    *Jean Boussier*

*   Remove Rack::Runtime from the default middleware stack and deprecate
    referencing it in middleware operations without adding it back

    *Hartley McGuire*

*   Allow adding additional authorized hosts in development via `ENV['RAILS_DEVELOPMENT_HOSTS']`

    *Josh Abernathy*, *Debbie Milburn*

*   Add app concern and test keepfiles to generated engine plugins.

    *Gannon McGibbon*

*   Stop generating a license for in-app plugins.

    *Gannon McGibbon*

*   `rails app:update` no longer prompts you to overwrite files that are generally modified in the
    course of developing a Rails app. See [#41083](https://github.com/rails/rails/pull/41083) for
    the full list of changes.

    *Alex Ghiculescu*

*   Change default branch for new Rails projects and plugins to `main`.

    *Prateek Choudhary*

*   Add benchmark method that can be called from anywhere.

    This method is used as a quick way to measure & log the speed of some code.
    However, it was previously available only in specific contexts, mainly views and controllers.
    The new Rails.benchmark can be used in the rest of your app: services, API wrappers, models, etc.

        def test
          Rails.benchmark("test") { ... }
        end

    *Simon Perepelitsa*

*   Removed manifest.js and application.css in app/assets
    folder when --skip-sprockets option passed as flag to rails.

    *Cindy Gao*

*   Add support for stylesheets and ERB views to `rails stats`.

    *Joel Hawksley*

*   Allow appended root routes to take precedence over internal welcome controller.

    *Gannon McGibbon*


Please check [6-1-stable](https://github.com/rails/rails/blob/6-1-stable/railties/CHANGELOG.md) for previous changes.
