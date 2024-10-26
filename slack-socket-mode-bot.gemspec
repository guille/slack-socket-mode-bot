# frozen_string_literal: true

require_relative "lib/version"

Gem::Specification.new do |spec|
  spec.name = "slack-socket-mode-bot"
  spec.version = SlackSocketModeBot::VERSION
  spec.authors = ["guille"]
  spec.email = ["guille@users.noreply.github.com"]

  spec.summary = "Gem for implementing simple bots for Slack using Socket Mode"
  spec.description = "This gem allows users to create Slack bots that respond to mentions. This gem only supports events-based socket mode bots. The gem allows registering a number of callbacks that will be executed if the registered regular expression matches the mention text."
  spec.homepage = "https://github.com/guille/slack-socket-mode-bot"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ examples/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "async"
  spec.add_dependency "async-websocket"
  spec.add_dependency "slack-ruby-client"
end
