module Zapata
  class RSpecWriter
    attr_reader :spec_filename

    def initialize(filename, code, subject_analysis, helper_file, var_analysis, spec_analysis = nil)
      @subject_analysis = subject_analysis
      @var_analysis = var_analysis
      @spec_analysis = spec_analysis
      @helper_file = helper_file
      @spec_filename = filename.gsub('app', 'spec').gsub('.rb', '_spec.rb')
      @writer = Writer.new(spec_filename)
      @result = {}

      case code.type
      when :class
        parse_klass(code)
      end
    end

    def subject_methods
      @subject_analysis.select { |assignment| assignment.class == DefAssignment }
    end

    def parse_klass(class_code)
      name, inherited_from_klass, body = class_code.to_a
      @instance = InstanceMock.new(name, inherited_from_klass, body)

      @writer.append_line("require '#{@helper_file}'")
      @writer.append_line

      @writer.append_line("describe #{@instance.name} do")
      @writer.append_line

      subject_methods.each do |method|
        write_for_method(method)
      end

      @writer.append_line('end')
    end

    def write_for_method(def_assignment)
      method = MethodMock.new(def_assignment.name, def_assignment.args,
        def_assignment.body, @var_analysis, @instance)

      if method.name == :initialize
        @instance.args_to_s = method.predicted_args_to_s
        write_let_from_initialize
      else
        write_method(method)
      end
    end

    def write_let_from_initialize
      @writer.append_line(
        "let(:#{@instance.name_underscore}) { #{@instance.initialize_to_s} }"
      )
      @writer.append_line
    end

    def write_method(method)
      return if method.empty?

      @writer.append_line("it '##{method.name}' do")

      @writer.append_line(
        "expect(#{@instance.name_underscore}.#{method.name}#{method.predicted_args_to_s}).to eq(#{write_equal(method.name)})"
      )

      @writer.append_line('end')
      @writer.append_line
    end

    def write_equal(method_name)
      if @spec_analysis
        Printer.value(@spec_analysis.expected(method_name))
      else
        Printer.value('FILL IN THIS BY HAND')
      end
    end
  end
end