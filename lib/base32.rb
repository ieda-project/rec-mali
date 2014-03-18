class Base32
  ALPHABET = "123456789ABCDEFGHJKMNPQRSTUVWXYZ"
  BASE = ALPHABET.length

  class << self
    def decode(base32_val)
      int_val = 0
      base32_val = base32_val.tr(" -/\n\r\t", '').upcase.tr('LI', '11')
      base32_val.reverse.split(//).each_with_index do |char,index|
        raise ArgumentError, 'Value passed not a valid Base32 String.' if (char_index = ALPHABET.index(char)).nil?
        int_val += (char_index)*(BASE**(index))
      end
      int_val
    end

    def encode(int_val)
      raise ArgumentError, 'Value passed is not an Integer.' unless int_val.is_a?(Integer)
      base32_val = ''
      while(int_val >= BASE)
        mod = int_val % BASE
        base32_val = ALPHABET[mod,1] + base32_val
        int_val = (int_val - mod)/BASE
      end
      ALPHABET[int_val,1] + base32_val
    end
  end
end
