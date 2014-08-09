module Zapata
  class Printer
    class << self
      def print(raw)
        case raw.type
        when :const, :send, :int, :const_send, :literal, :float
          raw.value
        when :str
          # decide which one to use
          # "\"#{raw.value}\""
          "'#{raw.value}'"
        when :sym
          ":#{raw.value}"
        when :true
          true
        when :false
          false
        when :array
          array(raw.value)
        when :hash
          hash(raw.value)
        when :nil
          'nil'
        when :missing
          print(Primitive::Raw.new(:str, "Missing \"#{raw.value}\""))
        when :ivar
          RZpec::Writer.ivars << raw
          to_var_name(raw.value)
        else
          binding.pry
        end
      end

      def array(given_array)
        unnested_array = given_array.map { |el| unnest(el) }
        "[#{unnested_array.join(', ')}]"
      end

      def args(given_args, klass)
        return unless given_args.present?

        if klass == Array
          array_without_closers = given_args[1...-1]
          return unless array_without_closers.present?

          "(#{array_without_closers})"
        elsif [Fixnum, Symbol].include?(klass)
          "(#{given_args})"
        elsif klass == Hash
          "(#{given_args})"
        else
          binding.pry
        end
      end

      def hash(obj)
        values = obj.map do |key, val|
          "#{unnest(key)} => #{unnest(val)}"
        end

        "{ #{values.join(', ')} }"
      end

      def unnest(raw)
        return raw unless raw.respond_to?(:value)

        if raw.value.is_a?(Primitive::Raw)
          print(unnest(raw.value))
        else
          print(raw)
        end
      end

      def to_var_name(name)
        name.to_s.split('::').last.underscore.delete('@')
      end
    end
  end
end
