# frozen_string_literal: true

module SlimSelectHelper
  def data_from_collection_for_slim_select(collection, value_method, text_method, options = {})
    placeholder = options.delete(:placeholder)
    selected_value = options.delete(:selected)

    data = []
    data << {text: "", value: "", placeholder: true} if placeholder

    collection.each do |item|
      text =
        if text_method.is_a?(Proc)
          text_method.call(item)
        else
          item.public_send(text_method)
        end

      value =
        if value_method.is_a?(Proc)
          value_method.call(item)
        else
          item.public_send(value_method)
        end

      selected =
        if selected_value.is_a?(Proc)
          selected_value.call(item, value)
        else
          selected_value
        end

      data << {text:, value:, selected:, **options}
    end

    data
  end

  def group_data_from_collection_for_slim_select(
    collection, group_method, value_method, text_method, options = {}
  )
    placeholder = options.delete(:placeholder)

    data = []
    data << {text: "", value: "", placeholder: true} if placeholder

    collection.each do |group, group_data|
      label =
        if group_method.is_a?(Proc)
          group_method.call(group)
        else
          group.public_send(group_method)
        end

      data << {
        label:,
        options: data_from_collection_for_slim_select(
          group_data, value_method, text_method, options
        )
      }
    end

    data
  end
end
