module RailsNewadmin
  class GroupsController < ApplicationController
    before_action -> { head :forbidden unless can_manage_access? }

    def index
      @groups = Group.order(:name).limit(100)
    end

    def new
      @group = Group.new
      @permissions = Permission.where(active: true).order(:resource_key, :action)
    end

    def create
      @group = Group.new
      save_group(:new)
    end

    def edit
      @group = Group.find(params[:id])
      @permissions = Permission.where(active: true).order(:resource_key, :action)
    end

    def update
      @group = Group.find(params[:id])
      save_group(:edit)
    end

    private

    def save_group(template)
      AccessManagement.new(current_actor, request_id: request.request_id).save_group!(@group, params.require(:group).permit(:name, permission_ids: []))
      redirect_to groups_path, status: :see_other
    rescue ActiveRecord::RecordInvalid
      @permissions = Permission.where(active: true).order(:resource_key, :action)
      render template, status: :unprocessable_entity
    end
  end
end
