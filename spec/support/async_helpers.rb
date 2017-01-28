module AsyncHelpers
  # Wait for block to return true of raise error
  def wait(timeout = 1, &block)
    until block.call
      sleep 0.1
      timeout -= 0.1
      raise "Timeout error" unless timeout > 0
    end
  end

  def concurrently(enum)
    enum.map { |*x| Concurrent::Future.execute { yield(*x) } }.map(&:value!)
  end
end
