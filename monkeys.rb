class Struct
  def to_json
    hash = {}
    each_pair { |name, value| hash[name] = value }
    hash.to_json
  end
end

class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end
end
