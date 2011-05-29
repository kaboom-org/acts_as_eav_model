module ActiveRecord
  class Base
    def _read_attribute(attr_name)
      read_attribute attr_name
    end
  end
end
