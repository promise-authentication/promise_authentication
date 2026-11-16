require 'test_helper'
require 'rake'

class TasksTest < ActiveSupport::TestCase
  # Only our own task files: Rails.application.load_tasks would also reload
  # Rails' tasks, which `rails test` already loaded (constant redefinition warnings).
  setup do
    Dir[Rails.root.join('lib/tasks/*.rake')].each { |file| load file } unless Rake::Task.task_defined?('bounces:poll')
  end

  # execute, not invoke: runs the task body without its :environment
  # prerequisite (already loaded) and can run again in the next test.
  def run_task(name)
    Rake::Task[name].execute
  end

  test 'bounces:poll reports what it found' do
    Bounces::Mailbox.stub :poll!, { reports: 2, matched: 1 } do
      assert_output("2 reports, 1 matched a pending code\n") { run_task('bounces:poll') }
    end
  end

  test 'bounces:poll says when the mailbox is not configured' do
    assert_output("bounce mailbox not configured\n") { run_task('bounces:poll') }
  end

  test 'statistics:sweep deletes old visit statistics' do
    swept = false
    Statistics.stub :sweep_old!, -> { swept = true } do
      run_task('statistics:sweep')
    end
    assert swept
  end

  test 'trust:roll_certificates rotates the certificates' do
    rotated = false
    Trust::Certificate.stub :rotate!, -> { rotated = true } do
      run_task('trust:roll_certificates')
    end
    assert rotated
  end
end
