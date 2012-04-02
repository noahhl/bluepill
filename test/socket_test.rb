require 'test_helper'

class SocketTest < Test::Unit::TestCase

  test "client socket timeouts are caught and retried up to max attempts and then exits" do
    oldstdout, $stdout = $stdout, StringIO.new    
    Timeout.expects(:timeout).with(Bluepill::Socket::TIMEOUT).raises(Timeout::Error).times(Bluepill::Socket::MAX_ATTEMPTS)
    UNIXSocket.expects(:open).yields.times(Bluepill::Socket::MAX_ATTEMPTS)
    assert_raise SystemExit do
      Bluepill::Socket.client_command("tmp", "myapp", "restart")
    end
    $stdout = oldstdout
  end

  test "creating a server when one is already running kills it and starts a new one" do

    UNIXServer.expects(:open).with("tmp/socks/myapp.sock").raises(Errno::EADDRINUSE).times(2)
    UNIXSocket.expects(:open).raises(Errno::ECONNREFUSED)
    File.expects(:delete).with("tmp/socks/myapp.sock")
    assert_raise Errno::EADDRINUSE do
      Bluepill::Socket.server('tmp', 'myapp')
    end
  end

end