require 'test_helper'

class ControllerTest < Test::Unit::TestCase

  def setup
    @controller = Bluepill::Controller.new(:base_dir => "tmp", :log_file => "tmp/log")
  end

  test "verifying valid and invalid versions" do
    oldstderr, $stderr = $stderr, StringIO.new #abort generates a warning in C, so just shut up stderr for this test
    Bluepill::Socket.expects(:client_command).with(any_parameters).returns("fakeversion")
    assert_raise SystemExit do
      @controller.send :verify_version!, "myapp"
    end
    Bluepill::Socket.expects(:client_command).with(any_parameters).returns(Bluepill::VERSION)
    
    assert_nothing_raised do
      @controller.send :verify_version!, "myapp"
    end
    $strderr = oldstderr
  end

  test "setting up bluepill directory structure" do
    File.expects(:exists?).with("tmp/socks")
    File.expects(:exists?).with("tmp/pids")
    FileUtils.expects(:mkdir_p).with("tmp/socks")
    FileUtils.expects(:mkdir_p).with("tmp/pids")
    Bluepill::Controller.new(:base_dir => "tmp", :log_file => "../tmp/log")
  end

  test "cleaning up bluepill directory" do
    @controller.expects(:running_applications).returns(["myapp"])
    File.expects(:exists?).with("tmp/pids/myapp.pid").returns(true).at_least_once
    File.expects(:exists?).with("tmp/socks/myapp.sock").returns(true).at_least_once
    File.expects(:read).with("tmp/pids/myapp.pid").returns("10")
    Bluepill::System.expects(:pid_alive?).with(10).returns(false)
    File.expects(:unlink).with("tmp/pids/myapp.pid")
    File.expects(:unlink).with("tmp/socks/myapp.sock")
    @controller.send :cleanup_bluepill_directory
  end

  test "sending a command to a daemon" do
    @controller.expects(:verify_version!)
    Bluepill::Socket.expects(:client_command).with("tmp", "myapp", "restart")
    @controller.send_to_daemon("myapp", "restart")
  end

  test "handling status command" do
    oldstdout, $stdout = $stdout, StringIO.new
    @controller.expects(:send_to_daemon).with("myapp", :status).returns("")
    @controller.handle_command("myapp", "status")
    $stdout = oldstdout
  end

  test "handling quit command" do
    oldstdout, $stdout = $stdout, StringIO.new
    @controller.expects(:pid_for).with("myapp").returns(1)
    ::Process.expects(:kill).with("TERM", 1)
    ::Process.expects(:kill).with(0, 1)
    @controller.handle_command("myapp", "quit")
    $stdout = oldstdout
  end

  test "handling an invalid command outputs a warning message and exits with status code 1" do
    $stderr.expects(:puts).with("Unknown command `fakecommand` (or application `fakecommand` has not been loaded yet)")
    assert_raise SystemExit do
      @controller.handle_command("myapp", "fakecommand")
    end
  end

  test "handling log command run system tail command with correct pattern" do
    oldstdout, $stdout = $stdout, StringIO.new
    @controller.expects(:send_to_daemon).with("myapp", :log_file).returns("tmp/log/myapp.log")
    Kernel.expects(:exec).with("tail -n 100 -f tmp/log/myapp.log | grep -E '\\[.*myapp.*'")
    @controller.handle_command("myapp", "log")
    $stdout = oldstdout
  end

end