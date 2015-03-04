class Cache
  EXPIRES_SECOND = 600
  attr_accessor :content

  def initialize
    expire
  end

  def expire?
    !@content || went_on_certain_period
  end

  def expire
    @previous_period = Time.now
  end

  private
  def went_on_certain_period
    Time.now - @previous_period > EXPIRES_SECOND
  end
end
