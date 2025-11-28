module ChatouilleHelper
  def step_badge_color(step)
    case step
    when 1 then "secondary"
    when 2 then "primary"
    when 3 then "warning"
    when 4 then "danger"
    else "secondary"
    end
  end

  def effect_icon(effect)
    case effect.to_s
    when "faith", "foi"
      "🙏"
    when "credits", "crédits"
      "💎"
    when "missionaries", "missionnaires"
      "🧑‍🦲"
    when "market_share", "parts"
      "📊"
    when "influence", "political_influence"
      "🏛️"
    when "converts", "convertis"
      "👥"
    when "temples"
      "⛪"
    when "miracles"
      "✨"
    when "council_observer"
      "👁️"
    when "council_member"
      "🪑"
    when "flying_temple"
      "🛸"
    else
      "•"
    end
  end

  def effect_name(effect)
    case effect.to_s
    when "faith"
      "Foi"
    when "credits"
      "Crédits"
    when "missionaries"
      "Missionnaires"
    when "market_share"
      "Parts de marché"
    when "influence", "political_influence"
      "Influence"
    when "converts"
      "Convertis"
    when "temples"
      "Temples"
    when "miracles"
      "Miracles"
    when "council_observer"
      "Observateur au Conseil"
    when "council_member"
      "Membre du Conseil"
    when "flying_temple"
      "Temple Volant"
    else
      effect.to_s.humanize
    end
  end

  def resource_icon(resource)
    case resource.to_s
    when "faith"
      "🙏"
    when "credits"
      "💎"
    when "missionaries"
      "🧑‍🦲"
    else
      "•"
    end
  end

  def can_afford?(resource, amount)
    return true unless @chatouille_state
    
    case resource.to_s
    when "faith"
      @chatouille_state.faith_points >= amount
    when "credits"
      @chatouille_state.religion_credits >= amount
    when "missionaries"
      @chatouille_state.missionaries >= amount
    else
      true
    end
  end

  def can_afford_action?(action)
    return true unless @chatouille_state
    return true unless action[:cost]
    
    action[:cost].all? do |resource, amount|
      can_afford?(resource, amount)
    end
  end
end

