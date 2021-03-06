class UsersController < ApplicationController

  before_action :redirect_to_invitation_confirm, only: [:new]
  before_action :get_resources, except: [:confirm_email]
  skip_before_action :authenticate_user, only: [:new, :create, :confirm_email]

  def new
    @user = User.new
    @user.email = params[:email]
    @token = params[:invitation_token] if params[:invitation_token]
  end

  def create
    @user = User.new(permitted_attributes(User.new))
    if @user.save
      if params[:invitation_token].blank? || Invitation.find_by_invited_user_email_and_invitation_token(@user.email, params[:invitation_token]).nil?
        UserMailer.registration_confirmation(@user).deliver
        redirect_to root_path, notice: 'User was successfully created. Please confirm your email.'
      else
        sign_in(@user)
        redirect_to confirm_todo_list_invitations_path(todo_list_id: params[:todo_list_id],
          email: @user.email, token: params[:invitation_token])
      end
    else
      render action: 'new'
    end
  end

  def confirm_email
    @user = User.where(email: params[:email], activation_token: params[:activation_token]).first
    authorize @user || User
    ActivateUser.call(user: @user)
    flash[:success] = 'Your email was successfully confirmed.'
    sign_in(@user)
    redirect_to root_path
  rescue Pundit::NotAuthorizedError
    flash[:error] = 'The activation link has already been used or is invalid. Please try to log in.'
    redirect_to new_user_sessions_path
  end

  def edit
    @user = current_user
  end

  def update
    if @user.authenticate(params[:current_password]) && @user.update_attributes(permitted_attributes(@user))
      redirect_to root_path, notice: 'User was successfully updated.'
    else
      flash[:error] = 'User update failed.'
      render action: 'edit'
    end
  end

  def destroy
    @user.destroy
    sign_out
    redirect_to new_user_sessions_path
  end

  private
  def get_resources
    @user = policy_scope(User).find(params[:id]) if params[:id]
    authorize @user || User
  end

  # invited user follows todolist_activation & new_user link after already being registered
  def redirect_to_invitation_confirm
    if User.exists?(email: params[:email]) && params[:invitation_token]
      redirect_to confirm_todo_list_invitations_path(todo_list_id: params[:list],
        email: params[:email], token: params[:invitation_token])
    end
  end

end
