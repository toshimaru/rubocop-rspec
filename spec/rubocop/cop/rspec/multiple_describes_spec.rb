# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::MultipleDescribes do
  subject(:cop) { described_class.new }

  it 'flags multiple top-level example groups with class and method' do
    expect_offense(<<-RUBY)
      describe MyClass, '.do_something' do; end
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use multiple top-level example groups - try to nest them.
      describe MyClass, '.do_something_else' do; end
    RUBY
  end

  it 'flags multiple top-level example groups only with class' do
    expect_offense(<<-RUBY)
      describe MyClass do; end
      ^^^^^^^^^^^^^^^^ Do not use multiple top-level example groups - try to nest them.
      describe MyOtherClass do; end
    RUBY
  end

  it 'ignores single top-level example group' do
    expect_no_offenses(<<-RUBY)
      describe MyClass do
      end
    RUBY
  end

  it 'flags shared example groups' do
    expect_offense(<<-RUBY)
      shared_examples_for 'behaves' do
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use multiple top-level example groups - try to nest them.
      end
      shared_examples_for 'misbehaves' do
      end
    RUBY
  end
end
