class InvitationsController < ApplicationController
  before_action :get_resources, except: [:confirm]
  skip_before_action :authenticate_user, only: [:confirm]

  def create
    authorize Invitation
    @invitation = @todo_list.invitations.new(permitted_attributes(Invitation.new))
    if @invitation.save
      UserMailer.invitation(@invitation, current_user).deliver
      flash[:success] = "Invitation was successfully sent. User now needs to confirm access to your TodoList"
    else
      flash[:success] = "There was a problem sending your invitation."
    end
    redirect_to todo_list_path(@todo_list)
  end

  def confirm #invited user accepts invitation to todo list
    @invitation = Invitation.where(invited_user_email: params[:email], invitation_token: params[:token]).first
    authorize(@invitation || Invitation)
    if @invitation.new_user? # if user followed activation link instead of registration+activation link
      flash[:success] = "Welcome to our TodoList Service! Please register here and then active your access to the TodoList"
      redirect_to new_user_path
    else
      activate_access
    end
  rescue Pundit::NotAuthorizedError
    flash[:error] = "You have already activated access to the todo list or the link is invalid"
    redirect_to root_path
  end

  private
  def get_resources
    @todo_list = policy_scope(TodoList).find(params[:todo_list_id])
  end

  def activate_access
    ActivateInvitation.call(invitation: @invitation)
    flash[:success] = "Access to TodoList was successfully activated."
    redirect_to todo_list_path(@invitation.todo_list)
  end

end
