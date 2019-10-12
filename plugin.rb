# name: discourse-pavilion
# about: Pavilion customisations
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-pavilion

register_asset "stylesheets/common/pavilion.scss"
register_asset "stylesheets/mobile/pavilion.scss", :mobile

Discourse.filters.push(:work)
Discourse.anonymous_filters.push(:work)

Discourse.filters.push(:unassigned)
Discourse.anonymous_filters.push(:unassigned)

if respond_to?(:register_svg_icon)
  register_svg_icon "hard-hat"
  register_svg_icon "clock-o"
  register_svg_icon "dollar-sign"
  register_svg_icon "funnel-dollar"
  register_svg_icon "sun"
  register_svg_icon "moon"
end

after_initialize do
  
  
  [
    'playercount',
    'day_length',
    'night_length'
  ].each do |field|
    Topic.register_custom_field_type(field, :integer)
    add_to_serializer(:topic_view, field.to_sym) { object.topic.custom_fields[field] }
    PostRevisor.track_topic_field(field.to_sym) do |tc, tf|
      tc.record_change(field, tc.topic.custom_fields[field], tf)
      tc.topic.custom_fields[field] = tf
    end
  end
  
  [
    'billable_hours_week',
    'billable_total_month'
  ].each do |field|
    User.register_custom_field_type(field, :integer)
    add_to_serializer(:user, field.to_sym) { object.custom_fields[field] }
    register_editable_user_custom_field field.to_sym if defined? register_editable_user_custom_field
  end
  
  module ::PavilionWork
    class Engine < ::Rails::Engine
      engine_name "pavilion_work"
      isolate_namespace PavilionWork
    end
  end 
  
  PavilionWork::Engine.routes.draw do
    put 'update' => 'work#update'
  end
  
  Discourse::Application.routes.append do
    mount ::PavilionWork::Engine, at: 'work'
    %w{users u}.each_with_index do |root_path, index|
      get "#{root_path}/:username/work" => "pavilion_work/work#index", constraints: { username: RouteFormat.username }
    end
  end
  
  class PavilionWork::WorkController < ApplicationController
    def index
    end

    def update
      user_fields = params.permit(:billable_hours_week, :billable_total_month)
      user = current_user
      
      user_fields.each do |field, value|
        user_fields[field] = value.to_i
        
        if user_fields[field] > SiteSetting.send("max_#{field}".to_sym)
          raise Discourse::InvalidParameters.new(field.to_sym)
        end
      end
      
      user_fields.each do |field, value|
        user.custom_fields[field] = value
      end
      
      user.save_custom_fields(true)
      
      result = {}
      
      user_fields.each do |field|
        value = user.custom_fields[field]
        result[field] = value if value.present?
      end
      
      render json: success_json.merge(result)
    end
  end
end
