require 'logger'

$logger = Logger.new(STDOUT)
$logger.level = Logger::WARN # try INFO

class UnsupportedDecimalSelector < StandardError; end
class InsufficientArguments < StandardError; end
class InvalidToken < StandardError; end
class InvalidExpression < StandardError; end

class PolandCalculator

  def initialize (&block)
    # set decimal_selector
    @decimal_selector = :d_2
    instance_eval &block if block_given?
    @stack = Array.new
  end

  def token_type (tok)
    if tok =~ /[0-9]+(\.?[0-9]*)?/ then
      return :number
    elsif tok =~ /f_/ then
      return :function
    elsif tok =~ /[\+\-\*\/]+/ then
      return :operator
    else
      return :invalid
    end
  end

  def decimal_selector(dec)
    @decimal_selector = dec
  end

  def functions(&block)
    @fns = block
  end

  def calc (str)
    case @decimal_selector
    when :d_0, :d_2, :d_float
    else
      $logger.fatal("Unsupported decimal selector")
      raise UnsupportedDecimalSelector, "Unsupported decimal selector"
    end
    #
    $logger.info "decimals: #{@decimal_selector}"
    $logger.info "preparing functions"
    # prepare functions (not sure if this is a good way to do it but it works)
    str.split(' ').each do |fn|
      if token_type(fn) == :function
        $logger.info "  creating method #{fn}"
        singleton_class.define_method(fn) do |lmb|
          $logger.info "  creating wrapper on #{lmb}"
          singleton_class.define_method("f"+fn) do |arg|
            result = lmb.call(arg)
            $logger.info "#{result} = #{fn}(#{arg})"
            return result
          end
        end
      end
    end

    if @fns != nil then
      $logger.info "  now executing block to create wrappers"
      instance_eval &@fns
    end
    $logger.info("preparation complete")

    # process
    str.split(' ').each do |tok|
      case token_type(tok)
      when :operator
        if @stack.length < 2 then
          $logger.fatal "Insufficient arguments for #{tok}"
          raise InsufficientArguments, "Insufficient arguments for #{tok}"
        end
        right = @stack.pop
        left = @stack.pop
        result = case
            when tok == "+"
              left + right
            when tok == "-"
              left - right
            when tok == "*"
              left * right
            when tok == "/"
              left / right
            end        
        @stack.push result
        $logger.info "#{result} = #{left} #{tok} #{right}"
      when :number
        @stack.push tok.to_f
        $logger.info "#{tok}"
      when :function
        if @stack.length < 1 then
          $logger.fatal "Insufficient arguments for #{tok}"
          raise InsufficientArguments, "Insufficient arguments for #{tok}"
        end
        val = @stack.pop
        result = instance_eval "f"+tok+" "+val.to_s # logged inside
        @stack.push result
      else
        $logger.fatal "Invalid token #{tok}"
        raise InvalidToken, "Invalid token #{tok}"
      end
    end

    if @stack.length > 1 then
      $logger.fatal "Invalid expression"
      raise InvalidExpression, "Invalid expression"
    end

    result = @stack.pop

    case @decimal_selector 
    when :d_0
      result = result.round(0)
    when :d_2
      result = result.round(2)
    end
    $logger.info result
    return result
  end
end

=begin
pc = PolandCalculator.new do
  functions do
    f_x -> (x) { 1.0 / x }
    f_my_function -> (x) { 0.99 + x }
  end
  decimal_selector :d_5
end
puts pc.calc('1. 1 + f_my_function f_x 2 +')
=end