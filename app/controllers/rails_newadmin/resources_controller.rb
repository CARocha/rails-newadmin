module RailsNewadmin
  class ResourcesController < ApplicationController
    before_action :load_resource
    before_action :authorize_grant
    before_action :load_record, only: [:show, :edit, :update, :delete, :destroy]
    before_action :authorize_action
    helper_method :resource_label, :record_label, :related_options

    def index
      @query = Query.new(@access, params)
      @records, @total = @query.records, @query.count
    end

    def show; end
    def delete; end

    def new
      @record = @access.scope.new
    end

    def create
      @record = @access.scope.new
      persist(:create, :new)
    end

    def edit; end

    def update
      persist(:update, :edit)
    end

    def destroy
      @record.destroy!
      redirect_to resource_records_path(@resource.resource_key), status: :see_other, notice: t("rails_newadmin.crud.deleted")
    rescue ActiveRecord::RecordNotDestroyed
      flash.now[:alert] = @record.errors.full_messages.to_sentence
      render :delete, status: :unprocessable_entity
    end

    def options
      reflection = @resource.model_class.reflect_on_association(params[:association].to_s)
      raise ActiveRecord::RecordNotFound unless reflection && @resource.relation_resources.key?(reflection.name)
      render json: related_options(reflection).map { |record| { id: record.id, label: record_label(record) } }
    end

    private

    def load_resource
      @resource = RailsNewadmin.registry.fetch(params[:resource_key])
      @access = Access.new(current_actor, @resource)
    rescue KeyError
      raise ActiveRecord::RecordNotFound
    end

    def load_record
      @record = @access.scope.find(params[:id])
    end

    def authorize_grant
      @permission_action = { "index" => :view, "show" => :view, "options" => :view,
        "new" => :create, "create" => :create, "edit" => :update, "update" => :update,
        "delete" => :destroy, "destroy" => :destroy }.fetch(action_name)
      head :forbidden unless @access.granted?(@permission_action)
    end

    def authorize_action
      head :forbidden unless @access.allowed?(@permission_action, @record)
    end

    def persist(action, template)
      fields = @access.permitted_attributes(action, @record)
      fields &= @resource.field_names
      data = params.require(:record).permit(*fields).to_h
      # Lock versions are concurrency tokens, never an editable business field.
      if @record.persisted? && @record.respond_to?(:lock_version) && params[:record].key?(:lock_version)
        @record.lock_version = params[:record][:lock_version]
      end
      if valid_relationships?(data) && @record.update(data)
        redirect_to resource_record_path(@resource.resource_key, @record), status: :see_other, notice: t("rails_newadmin.crud.saved")
      else
        @record.assign_attributes(data.except(*relationship_foreign_keys))
        render template, status: :unprocessable_entity
      end
    rescue ActiveRecord::StaleObjectError
      @record.errors.add(:base, t("rails_newadmin.crud.conflict"))
      render template, status: :conflict
    end

    def relationship_foreign_keys
      @resource.model_class.reflect_on_all_associations(:belongs_to).map(&:foreign_key)
    end

    def valid_relationships?(data)
      @resource.model_class.reflect_on_all_associations(:belongs_to).each do |reflection|
        id = data[reflection.foreign_key]
        next if id.blank?
        target_key = @resource.relation_resources[reflection.name]
        target_resource = target_key && RailsNewadmin.registry.fetch(target_key)
        target_access = target_resource && Access.new(current_actor, target_resource)
        found = target_access&.allowed?(:view) && target_access.scope.where(target_resource.model_class.primary_key => id).first
        next if found && found.is_a?(reflection.klass) && target_access.allowed?(:view, found)
        @record.errors.add(reflection.foreign_key, t("rails_newadmin.crud.invalid_relation"))
      end
      @record.errors.empty?
    end

    def related_options(reflection, selected_id: nil)
      target_resource = RailsNewadmin.registry.fetch(@resource.relation_resources.fetch(reflection.name))
      return [] unless target_resource.model_class == reflection.klass
      target_access = Access.new(current_actor, target_resource)
      return [] unless target_access.allowed?(:view)
      records = Query.new(target_access, { q: params[:q].to_s, page: params[:page], per_page: 20 }).records.to_a
      if selected_id.present? && records.none? { |record| record.id.to_s == selected_id.to_s }
        selected = target_access.scope.find_by(target_resource.model_class.primary_key => selected_id)
        records.unshift(selected) if selected && target_access.allowed?(:view, selected)
      end
      records
    end

    def resource_label = @resource.model_class.model_name.human(count: 2)

    def record_label(record)
      label_field = [:name, :title].find { |field| record.has_attribute?(field) }
      label_field ? record.public_send(label_field).to_s : "#{record.class.model_name.human} ##{record.id}"
    end
  end
end
