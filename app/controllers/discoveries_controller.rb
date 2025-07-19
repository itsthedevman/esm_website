# frozen_string_literal: true

class DiscoveriesController < ApplicationController
  def index
    return if params[:q].blank?

    search_term = params.require(:q)
    search_term_wildcard = "%#{search_term}%"

    communities = ESM::Community.where(
      <<~SQL,
        community_id ilike :term OR
        community_name ilike :term OR
        guild_id ilike :term
      SQL
      term: search_term_wildcard
    )

    servers = ESM::Server.all
      .where(server_visibility: :public)
      .where(
        <<~SQL,
          server_id ilike :term OR
          server_name ilike :term OR
          server_ip ilike :term
        SQL
        term: search_term_wildcard
      )

    # Check to see if we matched any communities via their servers
    related_communities = ESM::Community.all
      .where(id: servers.pluck(:community_id).uniq)
      .where.not(id: communities.pluck(:id).uniq)

    # And the same for servers
    related_servers = ESM::Server.all
      .where(server_visibility: :public, community_id: communities.pluck(:id).uniq)
      .where.not(id: servers.pluck(:id).uniq)

    render locals: {
      communities:,
      servers:,
      related_communities:,
      related_servers:
    }
  end
end
