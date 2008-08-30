require 'set'

module SetExt
  def join(*args,&block)
    map.join(*args,&block)
  end
end

class Set
  include SetExt
end

