require 'retrospec/resource'

class Conditional
  attr_reader :test, :value, :statements

  # things I need:  a key/value store for variables
  # types of variables
  # those that can be changed
  # those that can be influenced (facts, other variables that contain variables)
  # takes a subtype of Puppet::AST::Branch that contains conditional logic
  def initialize(branch)
     @statements = branch.statements
     @test = branch.test
  end

  def testcase
    begin
      case test
        when Puppet::Parser::AST::ComparisonOperator
          "#{test.lval.to_s} #{test.operator} #{test.rval.to_s}"
        when Puppet::Parser::AST::Variable
          test.to_s
        else
          require 'pry'
          binding.pry
      end
    rescue

    end
  end

  # get the attributes for the given resources found in the type code passed in
  # this will return a array of hashes, one for each resource found
  def self.all(type)
    r_attrs = []
    generate_conditionals(type).each do |c|
      r_attrs << Resource.all(c.statements)
    end
    r_attrs.flatten
  end

  # a array of types the are known to contain conditional code and statements
  def self.types
    #test, statement, value
    # if I don't have a statement that I am part of a bigger code block
    # [Puppet::Parser::AST::IfStatement, Puppet::Parser::AST::CaseStatement, Puppet::Parser::AST::Else,
    #  Puppet::Parser::AST::CaseOpt, Puppet::Parser::AST::Selector]
    [Puppet::Parser::AST::IfStatement, Puppet::Parser::AST::Else]
  end

  # recursively finds all the conditional types specified by types array
  def self.find_conditionals(statements)
    conds = []
    if statements.respond_to?(:find_all)
      conds = statements.find_all {|c| types.include?(c.class)  }
      conds.each do |statement|
        conds += find_conditionals(statement.statements)
      end
    end
    conds
  end

  # find and create an array of conditionals
  # we need the type so we can look through the code to find conditional statements
  def self.generate_conditionals(type)
    conditionals = []
    find_conditionals(type.code).each do |cond|
      conditionals << Conditional.new(cond)
    end
    conditionals
  end

end