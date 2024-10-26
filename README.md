# slack-ruby-socket-mode-bot

This gem allows users to create Slack bots that respond to mentions. This gem only supports events-based [socket mode](https://api.slack.com/apis/socket-mode) bots. The gem allows registering a number of callbacks that will be executed if the registered regular expression matches the mention text.

See the [examples](https://github.com/guille/slack-socket-mode-bot/blob/master/examples) directory for some ideas on how to use the gem.

## Limitations

- The bot assumes it is only running for one workspace.
- It only supports mention events. Other types of events such as slash commands may be implemented in the future.
- Put this together in a few hours, very likely to go boom unexpectedly.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
