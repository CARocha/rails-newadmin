# frozen_string_literal: true
module RailsNewadmin
  class Query
    attr_reader :relation, :page, :per_page

    def initialize(access, params)
      @resource = access.resource
      @relation = access.scope
      @page = params[:page].to_s.to_i.clamp(1, 100_000)
      @per_page = (params[:per_page].presence || 25).to_i.clamp(1, 100)
      filter(params[:filters])
      search(params[:q])
      sort(params[:sort], params[:direction])
    end

    def count = relation.count
    def records = relation.preload(@resource.preload_names).limit(per_page).offset((page - 1) * per_page)

    private

    def filter(values)
      return unless values.respond_to?(:key?)
      @resource.filter_fields.each do |field|
        value = values[field.to_s] || values[field]
        next unless value.is_a?(String) && value.present? && value.length <= 200 && @resource.model_class.column_names.include?(field.to_s)
        @relation = relation.where(field => value)
      end
    end

    def search(value)
      return unless value.is_a?(String) && value.present?
      escaped = ActiveRecord::Base.sanitize_sql_like(value.first(200))
      table = @resource.model_class.arel_table
      fields = @resource.search_fields.select { |field| %i[string text].include?(@resource.model_class.type_for_attribute(field.to_s).type) }
      predicates = fields.map { |field| table[field].matches("%#{escaped}%", "\\") }
      @relation = relation.where(predicates.reduce(:or)) if predicates.any?
    end

    def sort(field, direction)
      primary_key = @resource.model_class.primary_key
      allowed = @resource.column_names.map(&:to_s) & @resource.model_class.column_names
      field = allowed.include?(field) ? field : primary_key
      direction = %w[asc desc].include?(direction) ? direction : "desc"
      @relation = relation.order(field => direction)
      @relation = relation.order(primary_key => :desc) unless field == primary_key
    end
  end
end
