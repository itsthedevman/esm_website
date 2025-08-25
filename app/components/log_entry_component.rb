# frozen_string_literal: true

class LogEntryComponent < ApplicationComponent
  def on_load(entry:, search_text: nil)
    @entry = entry
    @search_text = search_text
  end

  def call
    content_tag(:span, class: "log-entry-content") do
      highlighted_content(parse_entry)
    end
  end

  private

  def highlighted_content(content)
    return content if @search_text.blank?

    # Create a regex for case-insensitive matching
    search_regex = Regexp.new(Regexp.escape(@search_text), Regexp::IGNORECASE)

    # Replace matches with highlighted version - using different color from poptabs
    content.gsub(search_regex) do |match|
      content_tag(:mark, match, class: "bg-info text-white fw-bold px-1 rounded border")
    end.html_safe
  end

  def parse_entry
    # Territory operations
    return parse_territory_operation if territory_operation?

    # Purchase/Sale operations
    return parse_purchase_sale if purchase_sale_operation?

    # Death messages - check this before timestamped since deaths have timestamps
    return parse_death_message if death_message?

    # Timestamped entries
    return parse_timestamped_entry if timestamped_entry?

    # Generic patterns
    parse_generic_entry
  end

  def territory_operation?
    @entry.match?(/PLAYER\s*\(\s*[\w]+\s*\).*?(STOLE A LEVEL|PAID.*RANSOM|PAID.*PROTECT TERRITORY|PURCHASE A TERRITORY FLAG|RESTORED THE FLAG|UPGRADE TERRITORY)/i)
  end

  def purchase_sale_operation?
    # More flexible regex to handle "REMOTE" transactions and weird usernames
    @entry.match?(/PLAYER:\s*\(\s*[\w]+\s*\).*?(PURCHASED|SOLD)/i)
  end

  def death_message?
    # Check for the actual death message patterns, not just the word "died"
    @entry.match?(/(died because|died a|died an|died and|died due|died while|died\.|commited suicide|crashed to death|was killed|was team-killed)/i)
  end

  def timestamped_entry?
    # Handle more complex timestamp formats including brackets and thread info
    @entry.match?(/^\[?\d{2}:\d{2}:\d{2}/)
  end

  def parse_territory_operation
    case @entry
    when /PLAYER\s*\(\s*([\w]+)\s*\)\s*(.+?)\s+STOLE A LEVEL\s+(\d+)\s+FLAG FROM TERRITORY #(\d+)/i
      uid, player, level, territory_id = $1, $2, $3, $4
      safe_join([
        player_badge(uid, player),
        " ",
        action_text("stole", :danger),
        " a ",
        content_tag(:span, "Level #{level}", class: "badge bg-info"),
        " flag from ",
        territory_badge(territory_id)
      ])

    when /PLAYER\s*\(\s*([\w]+)\s*\)\s*(.+?)\s+PAID\s+([\d,]+)\s+POP TABS FOR THE RANSOM OF TERRITORY #(\d+)\s*\|\s*PLAYER TOTAL POP TABS:\s*([\d,]+)/i
      uid, player, amount, territory_id, total = $1, $2, $3, $4, $5
      safe_join([
        player_badge(uid, player),
        " ",
        action_text("paid ransom", :warning),
        " of ",
        currency_badge(amount, "poptabs"),
        " for ",
        territory_badge(territory_id),
        " ",
        total_currency(total)
      ])

    when /PLAYER\s*\(\s*([\w]+)\s*\)\s*(.+?)\s+PAID\s+([\d,]+)\s+POP TABS TO PROTECT TERRITORY #(\d+)\s*\|\s*PLAYER TOTAL POP TABS:\s*([\d,]+)/i
      uid, player, amount, territory_id, total = $1, $2, $3, $4, $5
      safe_join([
        player_badge(uid, player),
        " ",
        action_text("paid protection", :success),
        " of ",
        currency_badge(amount, "poptabs"),
        " for ",
        territory_badge(territory_id),
        " ",
        total_currency(total)
      ])

    when /PLAYER\s*\(\s*([\w]+)\s*\)\s*(.+?)\s+PAID\s+([\d,]+)\s+POP TABS TO PURCHASE A TERRITORY FLAG\s*\|\s*PLAYER TOTAL POP TABS:\s*([\d,]+)/i
      uid, player, amount, total = $1, $2, $3, $4
      safe_join([
        player_badge(uid, player),
        " ",
        action_text("purchased", :primary),
        " territory flag for ",
        currency_badge(amount, "poptabs"),
        " ",
        total_currency(total)
      ])

    when /PLAYER\s*\(\s*([\w]+)\s*\)\s*(.+?)\s+RESTORED THE FLAG OF TERRITORY #(\d+)/i
      uid, player, territory_id = $1, $2, $3
      safe_join([
        player_badge(uid, player),
        " ",
        action_text("restored", :success),
        " the flag of ",
        territory_badge(territory_id)
      ])

    when /PLAYER\s*\(\s*([\w]+)\s*\)\s*(.+?)\s+PAID\s+([\d,]+)\s+POP TABS TO UPGRADE TERRITORY #(\d+) TO LEVEL\s+(\d+)\s*\|\s*PLAYER TOTAL POP TABS:\s*([\d,]+)/i
      uid, player, amount, territory_id, level, total = $1, $2, $3, $4, $5, $6
      safe_join([
        player_badge(uid, player),
        " ",
        action_text("upgraded", :info),
        " ",
        territory_badge(territory_id),
        " to ",
        content_tag(:span, "Level #{level}", class: "badge bg-info"),
        " for ",
        currency_badge(amount, "poptabs"),
        " ",
        total_currency(total)
      ])

    else
      content_tag(:span, @entry, class: "text-muted")
    end
  end

  def parse_purchase_sale
    case @entry
    # Remote purchase transactions
    when /PLAYER:\s*\(\s*([\w]+)\s*\)\s*R NSTR:\d+\s*\(([^)]+)\)\s*REMOTE\s+PURCHASED ITEM\s+(.+?)\s+FOR\s+([\d,.e\+]+)\s+POPTABS\s*\|\s*PLAYER TOTAL MONEY:\s*([\d,]+)/i
      uid, player, item, price, total = $1, $2, $3, $4, $5
      safe_join([
        content_tag(:span, "[REMOTE]", class: "badge bg-secondary ms-1"),
        " ",
        player_badge(uid, player),
        " ",
        action_text("purchased", :primary),
        " ",
        item_badge(item),
        " for ",
        currency_badge(price, "poptabs"),
        " ",
        total_currency(total)
      ])

    when /PLAYER:\s*\(\s*([\w]+)\s*\)\s*R NSTR:\d+\s*\(([^)]+)\)\s*REMOTE\s+PURCHASED VEHICLE\s+(.+?)\s+FOR\s+([\d,.e\+]+)\s+POPTABS\s*\|\s*PLAYER TOTAL MONEY:\s*([\d,]+)/i
      uid, player, vehicle, price, total = $1, $2, $3, $4, $5
      safe_join([
        content_tag(:span, "[REMOTE]", class: "badge bg-secondary ms-1"),
        " ",
        player_badge(uid, player),
        " ",
        action_text("purchased", :primary),
        " vehicle ",
        vehicle_badge(vehicle),
        " for ",
        currency_badge(price, "poptabs"),
        " ",
        total_currency(total),
        " "
      ])

    # Remote sale transactions
    when /PLAYER:\s*\(\s*([\w]+)\s*\)\s*R NSTR:\d+\s*\(([^)]+)\)\s*REMOTE\s+SOLD ITEM\s+(.+?)\s+FOR\s+([\d,.e\+]+)\s+POPTABS AND\s+([\d,]+)\s+RESPECT\s*\|\s*PLAYER TOTAL MONEY:\s*([\d,]+)/i
      uid, player, item, price, respect, total = $1, $2, $3, $4, $5, $6
      safe_join([
        content_tag(:span, "[REMOTE]", class: "badge bg-secondary ms-1"),
        " ",
        player_badge(uid, player),
        " ",
        action_text("sold", :success),
        " ",
        item_badge(item),
        " for ",
        currency_badge(price, "poptabs"),
        " and ",
        respect_badge(respect),
        " ",
        total_currency(total),
        " "
      ])

    # Regular (non-remote) purchase transactions
    when /PLAYER:\s*\(\s*([\w]+)\s*\)\s*(.+?)\s+PURCHASED ITEM\s+(.+?)\s+FOR\s+([\d,]+)\s+POPTABS\s*\|\s*PLAYER TOTAL MONEY:\s*([\d,]+)/i
      uid, player, item, price, total = $1, $2, $3, $4, $5
      safe_join([
        player_badge(uid, player),
        " ",
        action_text("purchased", :primary),
        " ",
        item_badge(item),
        " for ",
        currency_badge(price, "poptabs"),
        " ",
        total_currency(total)
      ])

    when /PLAYER:\s*\(\s*([\w]+)\s*\)\s*(.+?)\s+PURCHASED VEHICLE\s+(.+?)\s+FOR\s+([\d,]+)\s+POPTABS\s*\|\s*PLAYER TOTAL MONEY:\s*([\d,]+)/i
      uid, player, vehicle, price, total = $1, $2, $3, $4, $5
      safe_join([
        player_badge(uid, player),
        " ",
        action_text("purchased", :primary),
        " vehicle ",
        vehicle_badge(vehicle),
        " for ",
        currency_badge(price, "poptabs"),
        " ",
        total_currency(total)
      ])

    when /PLAYER:\s*\(\s*([\w]+)\s*\)\s*(.+?)\s+PURCHASED VEHICLE SKIN\s+(.+?)\s+\((.+?)\)\s+FOR\s+([\d,]+)\s+POPTABS\s*\|\s*PLAYER TOTAL MONEY:\s*([\d,]+)/i
      uid, player, skin, vehicle, price, total = $1, $2, $3, $4, $5, $6
      safe_join([
        player_badge(uid, player),
        " ",
        action_text("purchased skin", :primary),
        " ",
        item_badge(skin),
        " for ",
        vehicle_badge(vehicle),
        " - ",
        currency_badge(price, "poptabs"),
        " ",
        total_currency(total)
      ])

    when /PLAYER:\s*\(\s*([\w]+)\s*\)\s*(.+?)\s+SOLD ITEM\s+(.+?)\s+FOR\s+([\d,]+)\s+POPTABS AND\s+([\d,]+)\s+RESPECT\s*\|\s*PLAYER TOTAL MONEY:\s*([\d,]+)/i
      uid, player, item, price, respect, total = $1, $2, $3, $4, $5, $6
      safe_join([
        player_badge(uid, player),
        " ",
        action_text("sold", :success),
        " ",
        item_badge(item),
        " for ",
        currency_badge(price, "poptabs"),
        " and ",
        respect_badge(respect),
        " ",
        total_currency(total)
      ])

    when /PLAYER:\s*\(\s*([\w]+)\s*\)\s*(.+?)\s+SOLD ITEM:\s*(.+?)\s*\(ID#\s*(\d+)\)\s*with Cargo\s+(.+?)\s+FOR\s+([\d,]+)\s+POPTABS AND\s+([\d,]+)\s+RESPECT\s*\|\s*PLAYER TOTAL MONEY:\s*([\d,]+)/i
      uid, player, vehicle, vehicle_id, cargo, price, respect, total = $1, $2, $3, $4, $5, $6, $7, $8
      safe_join([
        player_badge(uid, player),
        " ",
        action_text("sold", :success),
        " ",
        vehicle_badge(vehicle),
        content_tag(:small, " ##{vehicle_id}", class: "text-muted"),
        content_tag(:small, " (#{cargo})", class: "text-info ms-1"),
        " for ",
        currency_badge(price, "poptabs"),
        " and ",
        respect_badge(respect),
        " ",
        total_currency(total)
      ])
    else
      content_tag(:span, @entry, class: "text-muted")
    end
  end

  def parse_death_message
    # First extract any timestamp if present
    if @entry.match?(/^\d{4}-\d{2}-\d{2} at \d{2}:\d{2}:\d{2} [AP]M UTC/i)
      timestamp_match = @entry.match(/^(\d{4}-\d{2}-\d{2} at \d{2}:\d{2}:\d{2} [AP]M UTC)\s*(.+)/i)
      if timestamp_match
        timestamp, message = timestamp_match[1], timestamp_match[2]
        return safe_join([
          content_tag(:span, timestamp, class: "text-info me-2"),
          parse_death_content(message)
        ])
      end
    end

    parse_death_content(@entry)
  end

  def parse_death_content(message)
    case message
    when /^(.+?)\s+died because.*Arma/i
      player = $1
      safe_join([
        player_name(player),
        " ",
        action_text("died", :warning),
        content_tag(:small, " (Arma bug)", class: "text-muted")
      ])

    when /^(.+?)\s+died because.*universe hates/i
      player = $1
      safe_join([
        player_name(player),
        " ",
        action_text("died", :warning),
        content_tag(:small, " (universe hates them)", class: "text-muted")
      ])

    when /^(.+?)\s+died because.*very unlucky/i
      player = $1
      safe_join([
        player_name(player),
        " ",
        action_text("died", :warning),
        content_tag(:small, " (unlucky)", class: "text-muted")
      ])

    when /^(.+?)\s+died a mysterious death/i
      player = $1
      safe_join([
        player_name(player),
        " ",
        action_text("died mysteriously", :warning)
      ])

    when /^(.+?)\s+died and nobody knows why/i
      player = $1
      safe_join([
        player_name(player),
        " ",
        action_text("died", :warning),
        content_tag(:small, " (unknown reason)", class: "text-muted")
      ])

    when /^(.+?)\s+died because that's why/i
      player = $1
      safe_join([
        player_name(player),
        " ",
        action_text("died", :warning),
        content_tag(:small, " (because)", class: "text-muted")
      ])

    when /^(.+?)\s+died due to Arma bugs/i
      player = $1
      safe_join([
        player_name(player),
        " ",
        action_text("died", :warning),
        content_tag(:small, " (Arma bugs - probably salty)", class: "text-muted")
      ])

    when /^(.+?)\s+died an awkward death/i
      player = $1
      safe_join([
        player_name(player),
        " ",
        action_text("died awkwardly", :warning)
      ])

    when /^(.+?)\s+died\.\s*Yes.*really dead/i
      player = $1
      safe_join([
        player_name(player),
        " ",
        action_text("died", :warning),
        content_tag(:small, " (really dead-dead)", class: "text-muted")
      ])

    when /^(.+?)\s+comm?itted suicide/i
      player = $1
      safe_join([
        player_name(player),
        " ",
        action_text("committed suicide", :warning)
      ])

    when /^(.+?)\s+died while playing Russian Roulette/i
      player = $1
      safe_join([
        player_name(player),
        " lost at ",
        action_text("Russian Roulette", :danger)
      ])

    when /^(.+?)\s+crashed to death/i
      player = $1
      safe_join([
        player_name(player),
        " ",
        action_text("crashed to death", :warning)
      ])

    when /^(.+?)\s+was killed by an NPC/i
      player = $1
      safe_join([
        player_name(player),
        " was killed by an ",
        action_text("NPC", :info)
      ])

    when /^(.+?)\s+was team-killed by\s+(.+?)[!.]/i
      victim, killer = $1, $2
      safe_join([
        player_name(victim),
        " was ",
        action_text("team-killed", :danger),
        " by ",
        player_name(killer)
      ])

    when /^(.+?)\s+was killed by\s+(.+?)!.*BAMBI SLAYER/i
      victim, killer = $1, $2
      safe_join([
        player_name(victim),
        " was killed by ",
        player_name(killer),
        " ",
        content_tag(:span, "[BAMBI SLAYER]", class: "badge bg-danger")
      ])

    when /^(.+?)\s+was killed by\s+(.+?)!\s*\(([^)]+)\)/i
      victim, killer, perks = $1, $2, $3
      perk_badges = perks.split(",").map { |perk| content_tag(:span, perk.strip, class: "badge bg-info ms-1") }
      safe_join([
        player_name(victim),
        " was killed by ",
        player_name(killer)
      ] + perk_badges)

    when /^(.+?)\s+was killed by\s+(.+?)[!.]/i
      victim, killer = $1, $2
      safe_join([
        player_name(victim),
        " was killed by ",
        player_name(killer)
      ])

    else
      content_tag(:span, message, class: "text-light")
    end
  end

  def parse_timestamped_entry
    # Handle complex timestamp formats like [02:55:06:071228 --5:00] [Thread 91468]
    if @entry.match?(/^\[([^\]]+)\]\s*\[([^\]]+)\]\s*(.+)/)
      timestamp, thread, message = $1, $2, $3
      safe_join([
        content_tag(:span, "[#{timestamp}]", class: "text-muted me-2"),
        content_tag(:span, "[#{thread}]", class: "text-secondary me-2"),
        content_tag(:span, message, class: "text-light")
      ])
    else
      # Simple timestamp format
      timestamp = @entry[0..7]
      message = @entry[9..]

      safe_join([
        content_tag(:span, timestamp, class: "text-muted me-2"),
        content_tag(:span, message, class: "text-light")
      ])
    end
  end

  def parse_generic_entry
    case @entry
    when /WARNING|Error|Failed/i
      content_tag(:span, @entry, class: "text-warning")
    when /SUCCESS|Loaded|Started|Connected/i
      content_tag(:span, @entry, class: "text-success")
    when /INFO|Loading|Initializing/i
      content_tag(:span, @entry, class: "text-info")
    else
      content_tag(:span, @entry, class: "text-light")
    end
  end

  # Helper methods for consistent formatting
  def player_badge(uid, name)
    safe_join([
      content_tag(:i, "", class: "bi bi-person-fill text-info me-1"),
      player_name(name),
      " ",
      content_tag(:small, "(#{uid})", class: "text-muted")
    ])
  end

  def player_name(name)
    content_tag(:span, name, class: "text-info fw-semibold")
  end

  def action_text(action, style)
    content_tag(:span, action, class: "text-#{style} fw-semibold")
  end

  def currency_badge(amount, type = "")
    formatted_amount = number_with_delimiter(amount)
    content_tag(:span, "#{formatted_amount} #{type}".strip, class: "badge bg-warning text-dark")
  end

  def respect_badge(amount)
    formatted_amount = number_with_delimiter(amount)
    content_tag(:span, "+#{formatted_amount} respect", class: "badge bg-success")
  end

  def total_currency(amount)
    formatted_amount = number_with_delimiter(amount)
    content_tag(:small, "(Balance: #{formatted_amount})", class: "text-muted")
  end

  def territory_badge(id)
    content_tag(:span, "Territory ##{id}", class: "badge bg-primary")
  end

  def item_badge(item)
    content_tag(:span, item, class: "badge bg-secondary")
  end

  def vehicle_badge(vehicle)
    content_tag(:span, vehicle, class: "badge bg-info text-dark")
  end

  def number_with_delimiter(number)
    # Convert scientific notation
    normalized = number.to_s.match?(/e[+-]?\d+/i) ? number.to_f.to_i : number.to_i

    helpers.number_with_delimiter(normalized)
  end
end
