require "spec_helper"

RSpec.describe Capybara::Sessionkeeper do
  it "has a version number" do
    expect(Capybara::Sessionkeeper::VERSION).not_to be nil
  end

  describe '#save_cookies' do
    it "saves cookies into file" do
      session = Capybara::Session.new(:chrome)
      session.visit 'https://github.com/'
      path = session.save_cookies
      expect(path).to match(/capybara-\d+.cookies.txt/)
    end
  end

  describe '#restore_cookies' do
    context "when path of cookie file isn't given" do
      let(:save_path_for_test) { 'spec/fixtures/restore_test' }

      it "restores cookies from the latest file" do
        allow(Capybara).to receive(:save_path).and_return(save_path_for_test)
        session = Capybara::Session.new(:chrome)
        session.visit 'https://github.com/'
        cookies = session.restore_cookies
        expect(cookies).not_to be_nil
        expect(cookies.all?{|c| c[:domain] =~ /github\.com/ }).to be_truthy
      end

      it "returns nil when cookie file doesn't exist in save_path" do
        allow(Capybara).to receive(:save_path).and_return('spec/fixtures/not_exist')
        session = Capybara::Session.new(:chrome)
        session.visit 'https://github.com/'
        expect(session.restore_cookies).to be_nil
      end
    end

    let(:cookie_path) { 'spec/fixtures/github.cookies.txt' }

    it "restores cookies from file" do
      session = Capybara::Session.new(:chrome)
      expect(session.driver.browser.manage.all_cookies).to be_empty
      session.visit 'https://github.com/'
      cookies = session.restore_cookies(cookie_path)
      expect(cookies).not_to be_empty
      expect(cookies.all?{|c| c[:domain] =~ /github\.com/ }).to be_truthy
    end

    it "raises error when the target site has never been visited" do
      session = Capybara::Session.new(:chrome)
      expect(session.driver.browser.manage.all_cookies).to be_empty
      session.visit 'https://www.google.com/'
      expect{
        session.restore_cookies(cookie_path)
      }.to raise_error(Selenium::WebDriver::Error::InvalidCookieDomainError, /visit/)
    end

    it "raises error when visit has never been performed" do
      session = Capybara::Session.new(:chrome)
      expect{
        session.restore_cookies(cookie_path)
      }.to raise_error(Capybara::Sessionkeeper::CookieError, /visit/)
    end
  end
end
