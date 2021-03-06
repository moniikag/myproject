require 'spec_helper'

describe 'Loggin Out' do
  let!(:user) { FactoryGirl.create(:user) }

  it "allows user to log out" do
    log_in
    click_link "log-out"
    expect(page).to have_content("Log In")
    expect(page).to have_content("You have successfully logged out")
    expect(current_path).to eq(new_user_sessions_path)
  end

end
