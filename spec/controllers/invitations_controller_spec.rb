require 'spec_helper'

RSpec.describe InvitationsController do
  let(:user) { FactoryGirl.create(:user) }
  let(:valid_session) { { user_id: user.id } }
  let(:todo_list) { FactoryGirl.create(:todo_list, user: user) }

  let(:other_user) { FactoryGirl.create(:user) }
  let(:other_valid_session) { { user_id: other_user.id } }
  let(:other_todo_list) { FactoryGirl.create(:todo_list, user: other_user) }

  let(:invitation_valid_params) { { invited_user_email: other_user.email } }
  let(:invitation) { FactoryGirl.create(:invitation, todo_list: todo_list, invited_user_email: other_user.email) }


  context "POST create: " do
    context "if user not signed in: " do
      it "doesn't create invitation and redirects to new_user_sessions_path" do
        expect {
          post :create, { todo_list_id: todo_list.id, invitation: invitation_valid_params }
        }.to change{Invitation.count}.by(0)
        expect(response).to redirect_to(new_user_sessions_path)
      end
    end

    context "if user signed in: " do
      it "creates an invitation and assigns invitation_token" do
        expect {
          post :create, { todo_list_id: todo_list.id, invitation: invitation_valid_params }, valid_session
        }.to change{Invitation.count}.by(1)
        expect(response.status).to eq(302)
        expect(Invitation.last.invitation_token).to_not be_nil
      end

      it "raises an error on attempt to create Invitation for other user's todo list" do
        expect {
          post :create, { todo_list_id: other_todo_list.id, invitation: invitation_valid_params }, valid_session
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "raises an error on attempt to create Invitation for non-existing todo list" do
        expect {
          post :create, { todo_list_id: '1', invitation: invitation_valid_params }, valid_session
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "given invalid params doesn't create Invitation" do
        invitation_invalid_params = invitation_valid_params.dup
        invitation_invalid_params[:invited_user_email] = 'email'
        expect {
          post :create, { todo_list_id: todo_list.id, invitation: invitation_invalid_params }, valid_session
        }.to change{ Invitation.count }.by(0)
        expect(response.status).to eq(302)
      end

      it "doesn't create invitation on attempt to invite user himself" do
        invitation_invalid_params = invitation_valid_params.dup
        invitation_invalid_params[:invited_user_email] = user.email
        expect {
          post :create, { todo_list_id: todo_list.id, invitation: invitation_invalid_params }, valid_session
        }.to change{ Invitation.count }.by(0)
      end

      it "given extra params creates Invitation" do
        invitation_invalid_params = invitation_valid_params.dup
        invitation_invalid_params[:invitation_token] = '12345'
        expect {
          post :create, { todo_list_id: todo_list.id, invitation: invitation_invalid_params }, valid_session
        }.to change{ Invitation.count }.by(1)
        expect(response.status).to eq(302)
        the_invitation = Invitation.where(invited_user_email: invitation_invalid_params[:invited_user_email]).first
        expect(the_invitation.invitation_token).to_not eq(invitation_invalid_params[:invitation_token])
      end
    end
  end

  context "GET confirm: " do
    let(:invitation_for_nonexistent_user) { FactoryGirl.create(:invitation, todo_list: todo_list, invited_user_email: "no@user.email") }

    context "nonexistent user: " do
      it "redirects to new_user_path with flash[:success]-inviting to register" do
        get :confirm, { email: invitation_for_nonexistent_user.invited_user_email, token: invitation_for_nonexistent_user.invitation_token,
         todo_list_id: todo_list.id }
        expect(response).to redirect_to(new_user_path)
        expect(flash[:success]).to be_present
      end
    end

    context "existing user: " do
      context "if user not signed in: " do
        it "gets valid token: activates access with flash[:success]" do
          expect(invitation.invitation_token).to_not be_nil
          get :confirm, { email: invitation.invited_user_email, token: invitation.invitation_token, todo_list_id: todo_list.id }
          invitation.reload
          expect(invitation.invitation_token).to be_nil
          expect(flash[:success]).to be_present
        end

        it "gets token that has already been used: redirects to root_path with flash[:error]" do
          token = invitation.invitation_token
          invitation.update_attribute('invitation_token', nil)
          get :confirm, { email: invitation.invited_user_email, token: token, todo_list_id: todo_list.id }
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to be_present
        end

        it "gets invalid token: redirects to root_path with flash[:error]" do
          get :confirm, { email: invitation.invited_user_email, token: '12345', todo_list_id: todo_list.id }
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to be_present
        end

        it "gets no token: redirects to root_path with flash[:error]" do
          get :confirm, { email: invitation.invited_user_email, todo_list_id: todo_list.id }
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to be_present
        end

        it "gets unknown email: redirects to root_path with flash[:error]" do
          get :confirm, { email: 'some@email.com', token: invitation.invitation_token, todo_list_id: todo_list.id }
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to be_present
        end

        context 'if user not activated yet' do
          let(:unconfirmed_user) { FactoryGirl.create(:unconfirmed_user) }

          it 'gets valid token: activates user, activates access, flash[:succes]' do
            invitation_for_nonexistent_user.update_attribute('invited_user_email', unconfirmed_user.email)
            expect(invitation_for_nonexistent_user.invitation_token).to_not be_nil
            expect(unconfirmed_user.activation_token).to_not be_nil

            get :confirm, { email: invitation_for_nonexistent_user.invited_user_email,
              token: invitation_for_nonexistent_user.invitation_token, todo_list_id: todo_list.id }

            invitation_for_nonexistent_user.reload
            unconfirmed_user.reload

            expect(invitation_for_nonexistent_user.invitation_token).to be_nil
            expect(unconfirmed_user.activation_token).to be_nil
            expect(flash[:success]).to be_present
          end
        end
      end

      context "if user signed in: " do
        it "gets valid token: activates access and redirects to todo_list_path with flash[:success]" do
          expect(invitation.invitation_token).to_not be_nil
          get :confirm, { email: invitation.invited_user_email, token: invitation.invitation_token, todo_list_id: todo_list.id }, other_valid_session
          invitation.reload
          expect(invitation.invitation_token).to be_nil
          expect(response).to redirect_to(todo_list_path(todo_list))
          expect(flash[:success]).to be_present
        end

        it "gets token that has already been used: redirects to root_path with flash[:error]" do
          token = invitation.invitation_token
          invitation.update_attribute('invitation_token', nil)
          get :confirm, { email: invitation.invited_user_email, token: token, todo_list_id: todo_list.id }, other_valid_session
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to be_present
        end

        it "gets invalid token: redirects to root_path with flash[:error]" do
          get :confirm, { email: invitation.invited_user_email, token: '12345', todo_list_id: todo_list.id }, other_valid_session
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to be_present
        end

        it "gets no token: redirects to root_path with flash[:error]" do
          get :confirm, { email: invitation.invited_user_email, todo_list_id: todo_list.id }, other_valid_session
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to be_present
        end

        it "gets unknown email: redirects to root_path with flash[:error]" do
          get :confirm, { email: 'some@email.com', token: invitation.invitation_token, todo_list_id: todo_list.id }, other_valid_session
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to be_present
        end
      end
    end
  end
end
