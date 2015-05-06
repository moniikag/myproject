require 'spec_helper'

RSpec.describe UsersController do
  fixtures :all
  subject { users(:john) }
  let(:valid_session) { { user_id: subject.id } }
  let(:valid_user_param) { { 
    first_name: "name", last_name: "last", email: "newtest@example.com", 
    password:'password', password_confirmation: 'password' 
  }}

  context "GET new: " do 
    context "if user not signed in: " do
      it "renders action new" do
        get :new
        expect(response.status).to be(200)
        expect(response).to render_template(:new)
        expect(assigns(:user)).to be_a_new(User)
      end
    end

    context "if user signed in: " do
      it "redirects to root path" do
        get :new, {}, valid_session
        expect(response).to redirect_to(root_path)  
      end
    end
  end

  context "GET edit: " do 
    context "if user not signed in: " do
      it "renders action edit" do
        get :edit, { id: subject.id }
        expect(response).to redirect_to(new_user_sessions_path)
      end
    end

    context "if user signed in: " do
      it "redirects to edit" do
        get :edit, { id: subject.id }, valid_session
        expect(response.status).to be(200)
        expect(response).to render_template(:edit)
        expect(assigns(:user)).to eq(subject)
      end
    end
  end

  context "POST create: " do
    context "if user signed in: " do
      it "redirects to root path" do
        expect {
          post :create, { user: valid_user_param } , valid_session
        }.to change { User.count }.by(0)   
        expect(response).to redirect_to(root_path)
      end
    end

    context "if user not signed in: " do
      it "given valid params creates user and redirects to user " do
        expect {
          post :create, user: valid_user_param
        }.to change { User.count }.by(1)  
        user = User.find_by_email('newtest@example.com')
        expect(controller.current_user).to eq(user)
        expect(response).to redirect_to(user)
      end

      it "given extra params creates user and redirects to user " do
        expect {
          post :create, user: valid_user_param.merge(extra: 'homo sapiens') 
        }.to change { User.count }.by(1)  
        user = User.find_by_email('newtest@example.com')
        expect(controller.current_user).to eq(user)
        expect(response).to redirect_to(user)
      end

      it "given invalid params renders template :new" do
        params = valid_user_param.dup
        params.delete(:email)
        expect {
          post :create, user: params
        }.to change { User.count }.by(0)  
        expect(response.status).to be(200)
        expect(response).to render_template(:new)
        expect(assigns(:user)).to be_a_new(User)
      end
    end
  end

  context "PUT update" do
    context "if user not signed in" do
      it "redirects to new_user_sessions_path" do  
        put :update, id: subject.id
        expect(response).to redirect_to(new_user_sessions_path)
      end
    end

    context "if user signed in" do
      it "given correct params updates user and redirects to user" do
        put :update, { id: subject.id, user: { first_name: "name" } }, valid_session
        expect(response).to redirect_to(subject)
      end

      it "given invalid params renders tempate edit" do
        put :update, { id: subject.id, user: { email: "" } }, valid_session
        expect(response).to render_template(:edit)
      end
    end
  end

  context "DELETE destroy" do
    context "if user not signed in" do
      it "doesn't destroy user & redirects to new_user_sessions_path" do  
        expect {
          delete :destroy, { id: subject.id }
        }.to change { User.count }.by(0)
        expect(response).to redirect_to(new_user_sessions_path)
      end
    end

    context "if user signed in" do
      let(:other_user) { users(:tom) }

      it "destroys the user on attempt to destroy himself & recirects to users" do
        delete :destroy, { id: subject.id }, valid_session
        expect(response).to redirect_to(root_url)
      end

      it "doesn't destroy user on attempt to destroy another user & redirects to root_path" do
        expect {
          delete :destroy, { id: other_user.id }, valid_session
        }.to change { User.count }.by(0)
        expect(response).to redirect_to root_path
      end
    end
  end

end