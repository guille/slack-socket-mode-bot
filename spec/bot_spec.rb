# frozen_string_literal: true

RSpec.describe SlackSocketModeBot::Bot do
  let(:stub_slack) { double("stub_slack") }
  let(:mock_auth) do
    {
      ok: true, user_id: 1, team_id: 2
    }
  end

  before do
    allow(Slack::Web::Client).to receive(:new).and_return(stub_slack)
  end

  it "does something useful" do
    expect(stub_slack).to receive(:auth_test).once.and_return(mock_auth)
    described_class.new(bot_token: "xoxb-...", app_token: "xapp-1-...")
  end
end
