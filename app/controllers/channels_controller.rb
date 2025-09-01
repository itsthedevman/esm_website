# frozen_string_literal: true

class ChannelsController < AuthenticatedController
  def index
    channels =
      if params[:user]
        # We're filtering by the channels we have access to.
        # Permission checking is handled by the bot.
        not_found! if current_community.nil?

        current_community.player_channels(current_user)
      else
        # If we're trying to view all channels, we have to have modification permissions
        check_for_community_access!

        current_community.channels
      end

    if params[:slim_select]
      channels = helpers.group_data_from_collection_for_slim_select(
        channels,
        ->(category) { category[:name] },
        ->(channel) { channel[:id] },
        ->(channel) { channel[:name] },
        placeholder: true,
        select_all: true
      )
    end

    render json: {content: {channels:}}
  end
end
