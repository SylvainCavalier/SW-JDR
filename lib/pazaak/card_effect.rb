module Pazaak
  class CardEffect
    # compute new sum and optional state transforms based on card name
    # returns [delta, proc] where delta is Integer change to apply to sum for simple cards,
    # and proc is an optional lambda that mutates game/state for complex effects
    def self.for(name)
      name = name.to_s
      # Simple +/- N
      if name.match?(/^\+[1-5]$/)
        return [name[1..].to_i, nil]
      elsif name.match?(/^-[1-5]$/)
        return [-name[1..].to_i, nil]
      elsif name.start_with?("±")
        # dual card: sign chosen ONLY from current score
        # if current sum < 20 => +N, else => -N (can bust by going over 20)
        n = name.gsub(/[^0-9]/, '').to_i
        return [0, ->(game, user){
          state = game.player_state(user)
          current = state["sum"].to_i
          delta = current < 20 ? n : -n
          state["sum"] = current + delta
          state["bust"] = state["sum"] > 20
          state["served"] = true if state["sum"] == 20
          (state["played_specials"] ||= []) << delta
          game.set_player_state!(user, state)
        }]
      elsif name == 'x2'
        return [0, ->(game, user){
          state = game.player_state(user)
          last = ((state["draws"] || []) + (state["played_specials"] || [])).last
          return if last.nil?
          state["sum"] += last
          (state["played_specials"] ||= []) << last
          state["bust"] = state["sum"] > 20
          game.set_player_state!(user, state)
        }]
      elsif name.include?('&')
        # e.g. "2&4" -> turn all 2 and 4 into -2 and -4 in draws
        parts = name.split('&').map(&:to_i)
        return [0, ->(game, user){
          state = game.player_state(user)
          changed = 0
          (state["draws"] || []).map! do |v|
            if parts.include?(v)
              changed += (v * -2)
              -v
            else
              v
            end
          end
          state["sum"] += changed
          game.set_player_state!(user, state)
        }]
      end
      [0, nil]
    end
    def self.css_kind(name)
      n = name.to_s
      return 'plus' if n.start_with?('+')
      return 'minus' if n.start_with?('-')
      return 'dual' if n.start_with?('±')
      return 'utility' if n == 'x2' || n.include?('&')
      'utility'
    end
  end

end


