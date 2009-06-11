require 'set'

module SetExt
  def join(*args,&block)
    to_a.join(*args,&block)
  end
end

class Set
  include SetExt
end

