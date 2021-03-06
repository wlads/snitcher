require "spec_helper"

require "securerandom"

describe Snitcher do
  let(:token) { SecureRandom.hex(5) }

  before do
    stub_request(:get, /nosnch\.in/)
  end

  describe ".snitch!" do
    it "pings DMS with the given token" do
      Snitcher.snitch!(token)

      expect(a_request(:get, "https://nosnch.in/#{token}")).to have_been_made.once
    end

    it "includes a custom user-agent" do
      Snitcher.snitch!(token)

      expect(
        a_request(:get, "https://nosnch.in/#{token}").with(
          headers: { "User-Agent" => /\ASnitcher;.*; v#{Snitcher::VERSION}\z/ },
        )
      ).to have_been_made
    end

    it "returns true when successful" do
      request = stub_request(:get, "https://nosnch.in/#{token}").to_return(status: 202)

      expect(Snitcher.snitch!(token)).to eq(true)
      expect(request).to have_been_made.once
    end

    it "returns false when unsuccessful" do
      request = stub_request(:get, "https://nosnch.in/#{token}").to_return(status: 404)

      expect(Snitcher.snitch!(token)).to eq(false)
      expect(request).to have_been_made.once
    end

    describe "with message" do
      it "includes the message as a query param" do
        Snitcher.snitch!(token, message: "A thing just happened")

        expect(a_request(:get, "https://nosnch.in/#{token}?m=A%20thing%20just%20happened")).to have_been_made
      end
    end

    it "raises a Timeout::Error if the request timesout" do
      stub_request(:get, "https://nosnch.in/#{token}").to_timeout

      expect { Snitcher.snitch!(token) }.to raise_error(Timeout::Error)
    end
  end

  describe ".snitch" do
    it "returns true on a successfuly check-in" do
      stub_request(:get, "https://nosnch.in/#{token}").to_return(status: 202)

      result = Snitcher.snitch(token)
      expect(result).to be(true)
    end

    it "returns false on a timeout" do
      stub_request(:get, "https://nosnch.in/#{token}").to_timeout

      result = Snitcher.snitch(token)
      expect(result).to be(false)
    end
  end

  describe "inclusion" do
    let(:snitching_class) { Class.new { include Snitcher } }

    it "snitches" do
      snitching_class.new.snitch(token)

      expect(a_request(:get, "https://nosnch.in/#{token}")).to have_been_made.once
    end
  end

  describe "extension" do
    let(:snitching_class) { Class.new { extend Snitcher } }

    it "snitches" do
      snitching_class.snitch(token)

      expect(a_request(:get, "https://nosnch.in/#{token}")).to have_been_made.once
    end
  end
end
