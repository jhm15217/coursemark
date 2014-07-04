require 'spec_helper'

describe UserSessionsController do
  let(:user) { FactoryGirl.create(:user) }

  before { user.save! }

  describe "GET 'new'" do
    it "returns http success" do
      get 'new'
      response.should be_success
    end
  end

  describe "POST 'create'" do
    context "with correct credentials" do
      it "returns http success" do
        post 'create', { user_session: {email: user.email, password: user.password}, commit: "Login"}
        response.should be_redirect
      end
    end

    context "with incorrect confirmation token" do
      it "returns a redirect" do
        post 'create', { user_session: {email: 'xxx@email.com', password: 'wrong_password'} }
        response.should be_success
      end
    end
  end

  describe "DELETE 'destroy'" do
    it "returns a redirect" do
      user_session = UserSession.new({email: user.email, password: user.password})
      user_session.save!
      delete 'destroy'
      response.should be_redirect
    end
  end


end
