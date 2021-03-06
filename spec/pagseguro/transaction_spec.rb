require "spec_helper"

describe PagSeguro::Transaction do
  describe ".find_by_notification_code" do
    it "finds transaction by the given notificationCode" do
      PagSeguro::Transaction.stub :load_from_response

      PagSeguro::Request
        .should_receive(:get)
        .with("transactions/notifications/CODE")
        .and_return(double.as_null_object)

      PagSeguro::Transaction.find_by_notification_code("CODE")
    end

    it "returns response with errors when request fails" do
      body = %[<?xml version="1.0"?><errors><error><code>1234</code><message>Sample error</message></error></errors>]
      FakeWeb.register_uri :get, %r[.+], :status => [400, "Bad Request"], :body => body, :content_type => "text/xml"
      response = PagSeguro::Transaction.find_by_notification_code("invalid")

      expect(response).to be_a(PagSeguro::Transaction::Response)
      expect(response.errors).to include("Sample error")
    end
  end

  describe ".find_by_date" do
    it "initializes report with default options" do
      now = Time.now
      Time.stub :now => now

      PagSeguro::Report
        .should_receive(:new)
        .with(
          PagSeguro::Transaction,
          "transactions",
          hash_including(:per_page => 50, :starts_at => now - 86400, :ends_at => now),
          0
        )

      PagSeguro::Transaction.find_by_date
    end

    it "initializes report with given options" do
      starts_at = Time.now - 3600
      ends_at = starts_at + 180
      page = 1

      PagSeguro::Report
        .should_receive(:new)
        .with(
          PagSeguro::Transaction,
          "transactions",
          hash_including(:per_page => 10, :starts_at => starts_at, :ends_at => ends_at),
          page
        )

      PagSeguro::Transaction.find_by_date(
        {:per_page => 10, :starts_at => starts_at, :ends_at => ends_at},
        page
      )
    end
  end

  describe ".find_abandoned" do
    it "initializes report with default options" do
      now = Time.now
      Time.stub :now => now

      PagSeguro::Report
        .should_receive(:new)
        .with(
          PagSeguro::Transaction,
          "transactions/abandoned",
          hash_including(:per_page => 50, :starts_at => now - 86400, :ends_at => now - 900),
          0
        )

      PagSeguro::Transaction.find_abandoned
    end

    it "initializes report with given options" do
      starts_at = Time.now - 3600
      ends_at = starts_at + 180
      page = 1

      PagSeguro::Report
        .should_receive(:new)
        .with(
          PagSeguro::Transaction,
          "transactions/abandoned",
          hash_including(:per_page => 10, :starts_at => starts_at, :ends_at => ends_at),
          page
        )

      PagSeguro::Transaction.find_abandoned(
        {:per_page => 10, :starts_at => starts_at, :ends_at => ends_at},
        page
      )
    end
  end

  describe "attributes" do
    before do
      body = File.read("./spec/fixtures/transactions/success.xml")
      FakeWeb.register_uri :get, %r[.+], :body => body, :content_type => "text/xml"
    end

    subject(:transaction) { PagSeguro::Transaction.find_by_notification_code("CODE") }

    it { expect(transaction.sender).to be_a(PagSeguro::Sender) }
    it { expect(transaction.shipping).to be_a(PagSeguro::Shipping) }
    it { expect(transaction.items).to be_a(PagSeguro::Items) }
    it { expect(transaction.payment_method).to be_a(PagSeguro::PaymentMethod) }
    it { expect(transaction.status).to be_a(PagSeguro::PaymentStatus) }
    it { expect(transaction.items).to have(1).item }
    it { expect(transaction).to respond_to(:escrow_end_date) }
  end
end
