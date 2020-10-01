# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::FactoryBot::BuildList, :config do
  let(:cop_config) do
    { 'EnforcedStyle' => enforced_style }
  end

  context 'when EnforcedStyle is :build_list' do
    let(:enforced_style) { :build_list }

    it 'flags usage of n.times with no arguments' do
      expect_offense(<<-RUBY)
        3.times { build :user }
        ^^^^^^^ Prefer build_list.
      RUBY
    end

    it 'flags usage of n.times when FactoryGirl.build is used' do
      expect_offense(<<-RUBY)
        3.times { FactoryGirl.build :user }
        ^^^^^^^ Prefer build_list.
      RUBY
    end

    it 'flags usage of n.times when FactoryBot.build is used' do
      expect_offense(<<-RUBY)
        3.times { FactoryBot.build :user }
        ^^^^^^^ Prefer build_list.
      RUBY
    end

    it 'ignores build method of other object' do
      expect_no_offenses(<<-RUBY)
        3.times { SomeFactory.build :user }
      RUBY
    end

    it 'ignores build in other block' do
      expect_no_offenses(<<-RUBY)
        allow(User).to receive(:build) { build :user }
      RUBY
    end

    it 'ignores n.times with argument' do
      expect_no_offenses(<<-RUBY)
        3.times { |n| build :user, created_at: n.days.ago }
      RUBY
    end

    it 'ignores n.times when there is no build call inside' do
      expect_no_offenses(<<-RUBY)
        3.times { do_something }
      RUBY
    end

    it 'ignores n.times when there is other calls but build' do
      expect_no_offenses(<<-RUBY)
        used_passwords = []
        3.times do
          u = build :user
          expect(used_passwords).not_to include(u.password)
          used_passwords << u.password
        end
      RUBY
    end

    it 'flags FactoryGirl.build calls with a block' do
      expect_offense(<<-RUBY)
        3.times do
        ^^^^^^^ Prefer build_list.
          build(:user) { |user| build :account, user: user }
        end
      RUBY
    end

    include_examples 'autocorrect',
                     '5.times { build :user }',
                     'build_list :user, 5'

    include_examples 'autocorrect',
                     '5.times { build(:user, :trait) }',
                     'build_list(:user, 5, :trait)'

    include_examples 'autocorrect',
                     '5.times { build :user, :trait, key: val }',
                     'build_list :user, 5, :trait, key: val'

    include_examples 'autocorrect',
                     '5.times { FactoryGirl.build :user }',
                     'FactoryGirl.build_list :user, 5'

    bad_code = <<-RUBY
      3.times do
        build(:user, :trait) { |user| build :account, user: user }
      end
    RUBY

    good_code = <<-RUBY
      build_list(:user, 3, :trait) { |user| build :account, user: user }
    RUBY

    include_examples 'autocorrect', bad_code, good_code

    bad_code = <<-RUBY
      3.times do
        build(:user, :trait) do |user|
          build :account, user: user
          build :profile, user: user
        end
      end
    RUBY

    good_code = <<-RUBY
      build_list(:user, 3, :trait) do |user|
          build :account, user: user
          build :profile, user: user
      end
    RUBY

    include_examples 'autocorrect', bad_code, good_code
  end

  context 'when EnforcedStyle is :n_times' do
    let(:enforced_style) { :n_times }

    it 'flags usage of build_list' do
      expect_offense(<<-RUBY)
        build_list :user, 3
        ^^^^^^^^^^ Prefer 3.times.
      RUBY
    end

    it 'flags usage of FactoryGirl.build_list' do
      expect_offense(<<-RUBY)
       FactoryGirl.build_list :user, 3
                   ^^^^^^^^^^ Prefer 3.times.
      RUBY
    end

    it 'flags usage of FactoryGirl.build_list with a block' do
      expect_offense(<<-RUBY)
       FactoryGirl.build_list(:user, 3) { |user| user.points = rand(1000) }
                   ^^^^^^^^^^ Prefer 3.times.
      RUBY
    end

    it 'ignores build method of other object' do
      expect_no_offenses(<<-RUBY)
        SomeFactory.build_list :user, 3
      RUBY
    end

    include_examples 'autocorrect',
                     'build_list :user, 5',
                     '5.times { build :user }'

    include_examples 'autocorrect',
                     'build_list(:user, 5, :trait)',
                     '5.times { build(:user, :trait) }'

    include_examples 'autocorrect',
                     'build_list :user, 5, :trait, key: val',
                     '5.times { build :user, :trait, key: val }'

    include_examples 'autocorrect',
                     'FactoryGirl.build_list :user, 5',
                     '5.times { FactoryGirl.build :user }'
  end
end
