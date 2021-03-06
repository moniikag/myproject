require "spec_helper"

describe "Editing user" do

  let!(:user) { FactoryGirl.create(:user) }

  let!(:valid_params) { {
    first_name: "New", last_name: "NewToo", email: "why@not.new",
    password: "letschange", password_confirmation: "letschange"
  } }

  it "allows a user to edit his data" do
    log_in
    visit "/users/#{user.id}/edit"
    expect(page).to have_content("Editing User")

    fill_in "user_email", with: valid_params[:email]
    fill_in "user_password", with: valid_params[:password]
    fill_in "user_password_confirmation", with: valid_params[:password]
    click_button "Update User"

    expect(current_path).to eq(root_path)
    expect(page).to have_content("User was successfully updated. ")
  end

end
