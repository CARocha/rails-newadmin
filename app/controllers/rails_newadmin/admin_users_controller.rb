module RailsNewadmin
  class AdminUsersController < ApplicationController
    prepend_before_action :require_builtin_authentication
    before_action -> { render_access_denied unless can_manage_access? }

    def index
      @users = AdminUser.order(:email_address).limit(100)
    end

    def new
      @user = AdminUser.new
      @groups = Group.order(:name)
    end

    def create
      @user = AdminUser.new
      save_user(:new)
    end

    def edit
      @user = AdminUser.find(params[:id])
      @groups = Group.order(:name)
    end

    def update
      @user = AdminUser.find(params[:id])
      save_user(:edit)
    end

    private

    def save_user(template)
      attributes = params.require(:admin_user).permit(:email_address, :password, :password_confirmation, :active, :staff, :locale, group_ids: []).to_h
      attributes[:superuser] = params[:admin_user][:superuser] if current_actor.superuser? && params[:admin_user].key?(:superuser)
      AccessManagement.new(current_actor, request_id: request.request_id).update_user!(@user, attributes)
      redirect_to admin_users_path, status: :see_other
    rescue ActiveRecord::RecordInvalid, AccessManagement::LastSuperuser => error
      @user.errors.add(:base, t("rails_newadmin.access.last_superuser")) if error.is_a?(AccessManagement::LastSuperuser)
      @groups = Group.order(:name)
      render template, status: :unprocessable_entity
    end
  end
end
