# frozen_string_literal: true

module SlimSelectHelper
  def data_from_collection_for_slim_select(collection, value_method, text_method, options = {})
    placeholder = options.delete(:placeholder)

    data = []
    data << {text: "", value: "", placeholder: true} if placeholder

    collection.each do |item|
      data << {
        text: item.public_send(text_method),
        value: item.public_send(value_method),
        **options
      }
    end

    data
  end
end
