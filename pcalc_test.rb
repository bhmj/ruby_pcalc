require "test/unit"
require_relative './pcalc'

class PolandCalculatorTest < Test::Unit::TestCase

  def test_first
    pc = PolandCalculator.new do
      decimal_selector :d_0
    end
    assert_equal 15, pc.calc('1 2 + 4 * 3.1 +'), "1st reference result"
  end

  def test_second
    pc = PolandCalculator.new do
      functions do
        f_x -> (x) { 1.0 / x }
      end
      decimal_selector :d_2
    end
    assert_equal 0.14, pc.calc('1 2 5 + * f_x'), "2nd reference result"
  end

  def test_third
    pc = PolandCalculator.new do
      functions do
        f_x -> (x) { 1.0 / x }
        f_my_function -> (x) { 0.99 + x }
      end
      decimal_selector :d_2
    end
    assert_equal 2.33, pc.calc('1 1 + f_my_function f_x 2 +'), "3rd reference result"
  end

  def test_unsupported_selector
    pc = PolandCalculator.new do
      decimal_selector :d_5
    end
    assert_raise(UnsupportedDecimalSelector) { pc.calc('1 1 +') }
  end

  def test_insufficient_arguments_op
    pc = PolandCalculator.new 
    assert_raise(InsufficientArguments) { pc.calc('1 +') }
  end

  def test_insufficient_arguments_fn
    pc = PolandCalculator.new do
      functions do
        f_x -> (x) { 1.0 / x }
      end
    end
    assert_raise(InsufficientArguments) { pc.calc('f_x') }
  end

  def test_invalid_token
    pc = PolandCalculator.new
    assert_raise(InvalidToken) { pc.calc('1 2 @') }
    assert_raise(InvalidToken) { pc.calc('x y +') }
  end

  def test_invalid_expression
    pc = PolandCalculator.new
    assert_raise(InvalidExpression) { pc.calc('1 2 3 +') }
  end

  def test_tricky_regexps
    pc = PolandCalculator.new
    assert_raise(InvalidToken) { pc.calc('1 2 + fake_f_3') }
    assert_raise(InvalidToken) { pc.calc('1 2 +-') }
    assert_raise(InvalidToken) { pc.calc('--1 2 +') }
    assert_equal 3, pc.calc('1 2 +'), "number regexp"
    assert_equal 3, pc.calc('1. 2 +'), "number regexp"
    assert_equal 3, pc.calc('1.0 2 +'), "number regexp"
    assert_equal 3, pc.calc('1.00 2 +'), "number regexp"
    assert_equal 2.1, pc.calc('.1 2 +'), "number regexp"
    assert_equal 2.1, pc.calc('0.1 2 +'), "number regexp"
    assert_equal 2.1, pc.calc('00.1 2 +'), "number regexp"
    assert_equal 2.1, pc.calc('00.10 2 +'), "number regexp"
  end

  def test_tricky_expressions
    pc = PolandCalculator.new
    assert_equal 123, pc.calc('123'), "Single number is valid"
    assert_equal -5, pc.calc('-1 5 *'), "Negative numbers"
    assert_equal Float::INFINITY, pc.calc('1 0 /'), "Infinity"
    assert_equal -Float::INFINITY, pc.calc('-1 0 /'), "-Infinity"
    assert_equal true, pc.calc('-1 0 / 1 0 / +').nan?, "NaN"
  end

  def test_clear_stack
    pc = PolandCalculator.new
    assert_raise(InvalidExpression) { pc.calc('1 2') } # left on stack after exception
    assert_equal 2.5, pc.calc('1 1.5 +'), "stack cleared"
  end

end
