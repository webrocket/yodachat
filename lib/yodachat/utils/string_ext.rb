module YodaChat
  module StringExt
    # Public: Transforms sentence to yoda-like language.
    # Inspired by http://www.perlmonks.org/?node_id=162190
    #
    # Examples
    #
    #     "The force is strong in you!".to_yoda
    #     # => "Strong in you, the force is!"
    #
    def to_yoda
      imarks = '\?\.\!\;'
      yodawords = %w{must shall should is be will show do try are teach have} 
      result = []

      self.split(/([#{imarks}])/).each { |s|
        if s =~ /^[#{imarks}]$/
          if result.last.nil? 
            result <<  s
          else
            result[result.size-1] = result.last + s
          end
        elsif word = yodawords.select { |word| s =~ /\b#{word}\b/ }[0]
          x = (s =~ /\b#{word}\b/) + word.size
          result << "#{s[x+1,s.size].capitalize}, #{s[0,x].downcase}"
        else 
          result << s
        end
      }

      result.join(" ")
    end
  end
end

class String
  include YodaChat::StringExt
end
